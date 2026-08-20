#!/usr/bin/env python3
"""Presence-based auto-lock daemon.

Samples the built-in RGB camera (fed into a v4l2loopback device by
presence-lock-feed.service, see presence-lock.nix) every --interval seconds,
runs face detection, and calls `loginctl lock-session` after --timeout
seconds with no face seen. Never locks while a face is present, never hard-
fails on a busy/missing camera (skips that poll cycle instead), and pauses
sampling entirely while the session is already locked so it does not
contend with an active video call or waste CPU/power.
"""
import argparse
import subprocess
import sys
import time

import cv2

# nixpkgs' opencv4 python bindings don't ship cv2.data (no bundled cascade
# dir), unlike upstream pip wheels, so the cascade path is passed in
# explicitly by presence-lock.nix instead of relying on cv2.data.haarcascades.


def session_locked() -> bool:
    """True if the current session is already locked (or lock state can't
    be determined - fail closed on sampling, i.e. skip rather than sample
    a session we can't confirm is unlocked)."""
    try:
        out = subprocess.run(
            ["loginctl", "show-session", "self", "-p", "LockedHint", "--value"],
            capture_output=True, text=True, timeout=5,
        )
        return out.stdout.strip() != "no"
    except Exception as e:
        print(f"presence-lock: loginctl check failed, skipping cycle: {e}", file=sys.stderr)
        return True


def has_face(detector: "cv2.CascadeClassifier", device: str) -> bool | None:
    """Returns True/False for face presence, or None if the camera could not
    be read this cycle (busy/unavailable - caller should skip, not lock)."""
    cap = cv2.VideoCapture(device)
    try:
        if not cap.isOpened():
            return None
        ok, frame = cap.read()
        if not ok or frame is None:
            return None
    finally:
        cap.release()
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    # Params tuned live against real images (a portrait with a face, a
    # camera frame of an empty room): equalizeHist + scaleFactor=1.05,
    # minNeighbors=4, minSize=50 cleanly separated the two (1 face vs. 0);
    # scaleFactor 1.1+ missed the real face, minNeighbors 3 / minSize 40
    # false-positived on the empty room.
    gray = cv2.equalizeHist(gray)
    faces = detector.detectMultiScale(gray, scaleFactor=1.05, minNeighbors=4, minSize=(50, 50))
    return len(faces) > 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--device", default="/dev/video42", help="V4L2 loopback device fed by the camera")
    ap.add_argument("--interval", type=float, default=3.0, help="seconds between polls")
    ap.add_argument("--timeout", type=float, default=45.0, help="seconds with no face before locking")
    ap.add_argument("--cascade", required=True, help="path to the Haar cascade XML file")
    args = ap.parse_args()

    detector = cv2.CascadeClassifier(args.cascade)
    if detector.empty():
        print("presence-lock: failed to load Haar cascade", file=sys.stderr)
        return 1

    last_face_seen = time.monotonic()

    while True:
        time.sleep(args.interval)

        if session_locked():
            # Already locked (or state unknown): don't sample, don't
            # re-lock, don't burn camera/CPU. Reset the timer so we don't
            # fire an immediate re-lock the instant it's unlocked.
            last_face_seen = time.monotonic()
            continue

        present = has_face(detector, args.device)
        now = time.monotonic()
        if present is None:
            print("presence-lock: camera unavailable this cycle, skipping", file=sys.stderr)
            continue
        if present:
            last_face_seen = now
            continue

        if now - last_face_seen >= args.timeout:
            print(f"presence-lock: no face for {now - last_face_seen:.0f}s, locking", file=sys.stderr)
            try:
                subprocess.run(["loginctl", "lock-session"], timeout=5, check=False)
            except Exception as e:
                print(f"presence-lock: lock-session failed: {e}", file=sys.stderr)
            # Reset so we don't spam lock-session every cycle until the
            # LockedHint check above takes over on the next poll.
            last_face_seen = now


if __name__ == "__main__":
    sys.exit(main())
