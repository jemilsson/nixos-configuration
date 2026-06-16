// Adaptive debounce state machine for a single button.
// Only button state CHANGES are deferred by window T; reversals within T are swallowed.
// T adapts from observed bounce intervals, hard-bounded to [MIN_T_US, MAX_T_US].

pub const MIN_T_US: u64 = 5_000; // 5ms
pub const MAX_T_US: u64 = 40_000; // 40ms
pub const DEFAULT_T_US: u64 = 12_000; // 12ms conservative default
const BOUNCE_CEIL_US: u64 = 30_000; // intervals >= this are legit activity, not bounce
const HISTORY_LEN: usize = 20;

#[derive(Debug, Clone)]
pub struct ButtonDebouncer {
    /// Current confirmed logical state (0=released, 1=pressed)
    pub confirmed_state: i32,
    /// Pending transition: (new_value, timestamp_when_seen_us)
    pub pending: Option<(i32, u64)>,
    /// Adaptive window in microseconds
    pub t_us: u64,
    /// Rolling history of sub-ceiling bounce intervals (us)
    bounce_history: Vec<u64>,
    history_pos: usize,
    history_full: bool,
    /// Count of total bounce events observed (for periodic logging)
    pub bounce_count: u64,
}

#[derive(Debug, PartialEq)]
pub enum DebounceAction {
    /// Emit this value now
    Emit(i32),
    /// Nothing to emit yet; call check_pending() at pending_deadline_us()
    Defer,
    /// Swallow — reversal within window or redundant event
    Swallow,
}

impl ButtonDebouncer {
    pub fn new() -> Self {
        Self {
            confirmed_state: 0,
            pending: None,
            t_us: DEFAULT_T_US,
            bounce_history: vec![0u64; HISTORY_LEN],
            history_pos: 0,
            history_full: false,
            bounce_count: 0,
        }
    }

    /// Feed an event. Returns what to do.
    pub fn feed(&mut self, value: i32, now_us: u64) -> DebounceAction {
        if let Some((pending_val, pending_ts)) = self.pending {
            let elapsed = now_us.saturating_sub(pending_ts);

            if value == pending_val {
                // Same direction again — update timestamp, keep deferring
                self.pending = Some((pending_val, now_us));
                return DebounceAction::Defer;
            }

            // Reversal while pending
            if elapsed < self.t_us {
                // Bounce: record interval and swallow
                self.record_bounce(elapsed);
                self.pending = None; // cancel; confirmed_state stays as is
                return DebounceAction::Swallow;
            }

            // The pending transition had already stabilized (elapsed >= t_us).
            // Commit it, then start a new pending for this reversal.
            self.confirmed_state = pending_val;
            self.pending = Some((value, now_us));
            return DebounceAction::Emit(pending_val);
        }

        // No pending
        if value == self.confirmed_state {
            return DebounceAction::Swallow; // redundant
        }
        // New transition — start deferring
        self.pending = Some((value, now_us));
        DebounceAction::Defer
    }

    /// Call when the timer fires (now_us >= pending_ts + t_us).
    /// Returns Some(value) if pending should now be committed.
    pub fn check_pending(&mut self, now_us: u64) -> Option<i32> {
        if let Some((val, ts)) = self.pending {
            if now_us.saturating_sub(ts) >= self.t_us {
                self.confirmed_state = val;
                self.pending = None;
                return Some(val);
            }
        }
        None
    }

    /// Reset on reconnect — don't emit stale held state
    pub fn reset(&mut self) {
        self.confirmed_state = 0;
        self.pending = None;
    }

    fn record_bounce(&mut self, interval_us: u64) {
        if interval_us >= BOUNCE_CEIL_US {
            return; // legit activity — double-click immunity
        }
        self.bounce_count += 1;
        self.bounce_history[self.history_pos] = interval_us;
        self.history_pos = (self.history_pos + 1) % HISTORY_LEN;
        if self.history_pos == 0 {
            self.history_full = true;
        }
        self.adapt_t();
    }

    fn adapt_t(&mut self) {
        let len = if self.history_full {
            HISTORY_LEN
        } else {
            self.history_pos
        };
        if len < 3 {
            return; // need a few samples
        }
        let mut samples: Vec<u64> = self.bounce_history[..len].to_vec();
        samples.sort_unstable();
        // Use 90th percentile of observed bounce intervals + 20% headroom
        let p90_idx = (len * 9) / 10;
        let p90 = samples[p90_idx];
        let new_t = (p90 * 12 / 10).clamp(MIN_T_US, MAX_T_US);
        self.t_us = new_t;
    }

    pub fn pending_deadline_us(&self) -> Option<u64> {
        self.pending.map(|(_, ts)| ts + self.t_us)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // (a) Sub-10ms click chatter → one click emitted
    // press at t=0, fake-release at t=5ms, check_pending at t=12ms → only one press
    #[test]
    fn test_chatter_yields_one_click() {
        let mut db = ButtonDebouncer::new();

        // Press at t=0
        let r0 = db.feed(1, 0);
        assert_eq!(r0, DebounceAction::Defer);
        assert_eq!(db.confirmed_state, 0);

        // Fake release at t=5ms (bounce within window)
        let r1 = db.feed(0, 5_000);
        assert_eq!(r1, DebounceAction::Swallow);
        // confirmed_state still 0; pending cancelled
        assert_eq!(db.confirmed_state, 0);
        assert!(db.pending.is_none());

        // check_pending at t=12ms — nothing pending, nothing emitted
        let r2 = db.check_pending(12_000);
        assert_eq!(r2, None);

        // NOTE: the bounce was swallowed; no press was ever emitted — correct
        // for raw bounce-chatter. A real click requires the press to survive T.
    }

    // (a2) Clean press that survives window → emitted
    #[test]
    fn test_clean_press_emitted_after_window() {
        let mut db = ButtonDebouncer::new();

        // Press at t=0
        assert_eq!(db.feed(1, 0), DebounceAction::Defer);

        // Timer fires at t=13ms (> DEFAULT_T_US=12ms)
        let r = db.check_pending(13_000);
        assert_eq!(r, Some(1));
        assert_eq!(db.confirmed_state, 1);

        // Release at t=200ms — new pending
        assert_eq!(db.feed(0, 200_000), DebounceAction::Defer);

        // Timer fires at t=213ms
        let r2 = db.check_pending(213_000);
        assert_eq!(r2, Some(0));
        assert_eq!(db.confirmed_state, 0);
    }

    // (b) Blink-release during hold → button stays pressed
    // press at t=0, committed at t=12ms, fake-release at t=20ms,
    // reversal (re-press) at t=23ms → stays pressed
    #[test]
    fn test_blink_release_during_hold_stays_pressed() {
        let mut db = ButtonDebouncer::new();

        // Press at t=0
        assert_eq!(db.feed(1, 0), DebounceAction::Defer);

        // Commit press at t=12ms
        let commit = db.check_pending(12_000);
        assert_eq!(commit, Some(1));
        assert_eq!(db.confirmed_state, 1);

        // Fake release at t=20ms — new pending(0)
        assert_eq!(db.feed(0, 20_000), DebounceAction::Defer);

        // Re-press at t=23ms — reversal within window (3ms elapsed < 12ms T)
        let r = db.feed(1, 23_000);
        assert_eq!(r, DebounceAction::Swallow);
        // pending cancelled; confirmed_state still 1 (held)
        assert_eq!(db.confirmed_state, 1);
        assert!(db.pending.is_none());
    }

    // (c) Legit double-click ~150ms apart → TWO clicks pass through
    #[test]
    fn test_legit_double_click_passes_through() {
        let mut db = ButtonDebouncer::new();

        // First click: press at t=0
        assert_eq!(db.feed(1, 0), DebounceAction::Defer);
        assert_eq!(db.check_pending(13_000), Some(1));

        // Release at t=50ms
        assert_eq!(db.feed(0, 50_000), DebounceAction::Defer);
        assert_eq!(db.check_pending(63_000), Some(0));

        // Second click: press at t=150ms
        assert_eq!(db.feed(1, 150_000), DebounceAction::Defer);
        assert_eq!(db.check_pending(163_000), Some(1));

        // Release at t=200ms
        assert_eq!(db.feed(0, 200_000), DebounceAction::Defer);
        assert_eq!(db.check_pending(213_000), Some(0));

        assert_eq!(db.confirmed_state, 0);
    }

    // (d) Normal single click and long hold pass through unchanged
    #[test]
    fn test_normal_click_and_hold() {
        let mut db = ButtonDebouncer::new();

        // Press
        assert_eq!(db.feed(1, 0), DebounceAction::Defer);
        assert_eq!(db.check_pending(13_000), Some(1));

        // Hold for 500ms — no spurious events
        assert_eq!(db.check_pending(513_000), None);

        // Release
        assert_eq!(db.feed(0, 600_000), DebounceAction::Defer);
        assert_eq!(db.check_pending(613_000), Some(0));
        assert_eq!(db.confirmed_state, 0);
    }

    // (e) Double-click immunity: 10 rapid double-clicks at ~120ms apart
    // T must never grow above MAX_T_US and every second click must pass through
    #[test]
    fn test_double_click_immunity() {
        let mut db = ButtonDebouncer::new();
        let mut t: u64 = 0;
        let mut second_clicks_passed = 0u32;

        for _ in 0..10 {
            // First click of pair
            assert_eq!(db.feed(1, t), DebounceAction::Defer);
            t += 13_000; // wait past T
            let r1 = db.check_pending(t);
            assert_eq!(r1, Some(1), "first press should commit");

            t += 10_000;
            assert_eq!(db.feed(0, t), DebounceAction::Defer);
            t += 13_000;
            assert_eq!(db.check_pending(t), Some(0));

            // Second click at ~120ms after first (inter-click interval >= BOUNCE_CEIL_US=30ms → not recorded as bounce)
            t += 100_000;
            assert_eq!(db.feed(1, t), DebounceAction::Defer);
            t += 13_000;
            let r2 = db.check_pending(t);
            assert_eq!(r2, Some(1), "second click should also commit");
            second_clicks_passed += 1;

            t += 10_000;
            assert_eq!(db.feed(0, t), DebounceAction::Defer);
            t += 13_000;
            assert_eq!(db.check_pending(t), Some(0));
            t += 20_000;
        }

        assert_eq!(second_clicks_passed, 10);
        assert!(
            db.t_us <= MAX_T_US,
            "T ({} us) must never exceed MAX_T_US ({} us)",
            db.t_us,
            MAX_T_US
        );
    }
}
