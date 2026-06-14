{ config, lib, pkgs, stdenv, hyprland, ... }:
let
  #containers = import ./containers/containers.nix { pkgs = pkgs; config = config; stdenv = stdenv; };
  #cardano-node = removed - no longer needed
  #cardano-hw-cli = removed - no longer needed  
  vpp = pkgs.jemilsson.vpp;
  claudia = pkgs.jemilsson.claudia;
  fit-web = pkgs.jemilsson.fit-web;
  fit-entire-website = pkgs.jemilsson.fit-entire-website;
  fit-main = pkgs.jemilsson.fit-main;

  wg2IPv4Prefixes = [
    { prefix = "10.128.12.0/24"; }
    { prefix = "10.0.0.0/8"; }
    { prefix = "100.64.0.0/10"; }
    { prefix = "192.168.0.0/16"; }
    { prefix = "172.16.0.0/12"; }
    { prefix = "160.79.104.0/23"; }  # Claude code
    { prefix = "137.61.9.13/32"; }   # skatteverket.se
    { prefix = "137.61.9.10/32"; }   # www7.skatteverket.se
  ];

  wg2IPv6Prefixes = [
    { prefix = "2a12:5800:0:27::/64"; }
    { prefix = "2a12:5800::/29"; }
    { prefix = "2a05:d016:865:7a00::/56"; }
    { prefix = "2607:6bc0::/48"; }   # Claude code
    { prefix = "2a03:b100:a:9::b/128"; }  # skatteverket.se
    { prefix = "2a03:b100:a:9::a/128"; }  # www7.skatteverket.se
    { prefix = "::/0"; metric = 50000; }
  ];

  parsePrefix = s: let
    parts = lib.splitString "/" s;
  in {
    address = builtins.elemAt parts 0;
    prefixLength = lib.toInt (builtins.elemAt parts 1);
  };

  prefixToRoute = p: let
    parsed = parsePrefix p.prefix;
  in parsed // lib.optionalAttrs (p ? metric) {
    options.metric = toString p.metric;
  };

  wg2AllowedIPs = map (p: p.prefix) (wg2IPv4Prefixes ++ wg2IPv6Prefixes);
  wg2IPv4Routes = map prefixToRoute wg2IPv4Prefixes;
  wg2IPv6Routes = map prefixToRoute wg2IPv6Prefixes;
in
{
  imports = [
    #<nixos-hardware/lenovo/thinkpad/x1/7th-gen>
    ../../config/laptop_base.nix
    ../../config/services/kvm/kvm.nix
    ../../config/i3_x11.nix
    ../../config/language/english.nix
    #../../config/software/tensorflow.nix
    #../../packages/vpp/vpp.nix
    ./hardware-configuration.nix
    #./graphiti.nix
    #./mcpo.nix
    ./camera.nix
    ./netns-claude-glecom.nix
    ./pi-lens.nix
    ./nix-retry.nix

  ];

  nixpkgs.config.permittedInsecurePackages = [
                #"electron-24.8.6"
];

  # Hardware-attested SSH key enforcement. syna installs and gates
  # authorized_keys for every privileged user from the shared keys file.
  # See ../../config/syna/attestations/README.md for how to refresh the
  # fafnir bundle.
  services.syna = {
    package = pkgs.syna;
    ssh = {
      enable = true;
      level = "fail";
      userKeys = import ../../config/syna/keys.nix;
    };
  };



  #programs.sway.extraOptions = [
  #  "WLR_DRM_DEVICES=/dev/dri/card1:/dev/dri/card0"
  #];

  #programs.sway.extraSessionCommands = ''
  #  WLR_DRM_DEVICES=/dev/dri/card1:/dev/dri/card0
  #'';


  environment.variables = {
    WLR_DRM_DEVICES = "/dev/dri/card0:/dev/dri/card1";
    #WLR_BACKEND = "vulkan";
    # Interactive cargo only (nix-build sandbox scrubs env, so determinism
    # of nix-built derivations is unaffected). sccache caches rustc output
    # to S3 (shared with somchai); mold cuts link time on big Rust workspaces.
    RUSTC_WRAPPER = "sccache";
    CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_RUSTFLAGS = "-C link-arg=-fuse-ld=mold";
    # Cap cargo parallelism at 8 of 12 cores so interactive work stays
    # responsive and 8 concurrent rustc+mold pairs fit in RAM. An env var
    # (not ~/.cargo/config.toml) so it reaches every cargo: the rustup
    # toolchain in ~/.cargo/bin shadows the nice'd wrapper from base.nix,
    # and devenv shells bring their own cargo too. One-off override:
    # cargo build -j12 (CLI beats env).
    CARGO_BUILD_JOBS = "8";
    # Hard resource caps for interactive cargo/rustc, enforced by the base.nix
    # cargo wrapper which launches into a transient systemd --user scope so the
    # whole cargo+rustc+mold tree is one bounded cgroup. -j8 + nice 19 only cap
    # parallelism and priority; these cap actual RAM/CPU so a single fat crate
    # (LTO, codegen-units=1) can't balloon past the session's headroom on this
    # 31 GiB / 12-core box. MemoryHigh throttles via reclaim, MemoryMax is the
    # hard OOM-kill ceiling for the build cgroup; CPUQuota caps at ~8 cores even
    # if a build spawns more than 8 concurrent rustc. Only reaches this wrapper
    # (rustup/devenv cargos shadow it, same caveat as CARGO_BUILD_JOBS above);
    # nix builds are unaffected (no $XDG_RUNTIME_DIR in the sandbox).
    CARGO_MEMORY_HIGH = "16G";
    CARGO_MEMORY_MAX = "20G";
    CARGO_CPU_QUOTA = "800%";
    SCCACHE_BUCKET = "sccache-shared-723173433317";
    SCCACHE_REGION = "ap-southeast-7";
    SCCACHE_S3_KEY_PREFIX = "v0";
  };

  # Disabled: any kernelPatches entry forces a full from-source kernel rebuild
  # (no binary-cache match), which is slow on jester. Re-enable once the fix is
  # upstream and in a cached nixpkgs kernel, or serve a prebuilt patched kernel
  # from a Nix binary cache.
  # boot.kernelPatches = [
  #   {
  #     name = "intel-mst-reprobe-fix";
  #     patch = ./intel-mst-reprobe-fix.patch;
  #   }
  # ];

  boot.initrd.kernelModules = [ "i915" ];
  boot.blacklistedKernelModules = [ "pn533_usb" "pn533" "xe" ];

  boot.kernel.sysctl."net.ipv4.tcp_mtu_probing" = 1;

  # Hyprland crashes on this machine are GPU context resets: the GPU driver
  # resets the Iris Xe GPU, glGetGraphicsResetStatus() then returns
  # GL_GUILTY_CONTEXT_RESET, and Hyprland aborts (it has no GL context
  # recovery). The kernel-side reset reason (guilty engine / error code) is
  # what we actually need, but base.nix caps journald at 500M which only
  # retains ~1 day, so the reset message rotates out before it can be read.
  # mkAfter ensures this SystemMaxUse wins over base.nix's (last key wins in
  # journald.conf). Bump retention so the next reset's signature is captured.
  services.journald.extraConfig = lib.mkAfter ''
    SystemMaxUse=4G
    MaxRetentionSec=2week
  '';

  # Memory-pressure hardening.
  #
  # jester has 31 GiB RAM and previously ran with ZERO swap. Under load
  # (rustc/nix builds + the local AI-gateway services + chromium/electron)
  # the *kernel* global OOM killer fired (89 oom-kill invocations in the
  # journal, 80 in a single day) and culled the graphical session wholesale
  # (pipewire, dbus-broker, the xdg portals), which is what made hyprlock
  # "sometimes crash" - it dies as collateral when the stack it renders on is
  # wiped. systemd.oomd (enabled in base.nix) acts on cgroup PSI but the
  # kernel global OOM, with no swap to provide reclaim runway, fired first.
  #
  # Three privilege-correct levers (verified: a user process here CANNOT set a
  # negative oom_score_adj, so "protect the session" via negative OOMScoreAdjust
  # on user units is not an option; instead we add swap headroom and bias the
  # killer toward builds, which are the actual trigger):

  # 1. zram swap: compressed in-RAM swap gives the kernel reclaim headroom so a
  #    transient spike compresses idle anonymous pages instead of hard-OOMing.
  #    Raised 25 -> 50 (2026-06): at 25% the device sat 100% full (7.6G/7.8G,
  #    SwapFree ~0) while measured compression was 4.85:1, so a 15.5G device
  #    costs ~3.2G RAM at this workload for +7.7G reclaim headroom. The
  #    worst-case-incompressible assumption behind "kept conservative" did not
  #    hold in practice; monitor `zramctl` mem_used_total after workload changes.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  # 2. VM tuning for zram: favour compressing anonymous pages over evicting the
  #    page cache, and disable swap readahead (zram is random-access, readahead
  #    just wastes cycles). overcommit is left at the kernel default (0 here;
  #    NixOS does not set strict overcommit).
  boot.kernel.sysctl = {
    "vm.swappiness" = 100;
    "vm.page-cluster" = 0;
    # Default 10 gives kswapd a ~29MB reclaim span on the 29.6G Normal zone,
    # causing wake/sleep churn under constant zram pressure; 100 batches
    # reclaim in ~296MB spans (fewer cycles, helps zstd compression batching).
    "vm.watermark_scale_factor" = 100;
    # Bias reclaim toward dropping reclaimable slab (~2G dentry/inode here)
    # sooner vs page cache; cheap to refill on NVMe. Slab-vs-pagecache only;
    # anon-vs-file balance is governed by swappiness above. Do not exceed 200.
    "vm.vfs_cache_pressure" = 200;
  };

  # 3. Bias the OOM killer toward local nix builds, the real trigger. The user
  #    systemd manager (and thus the whole graphical session) runs at
  #    oom_score_adj=100, while root nix-daemon runs at 0 - i.e. an unconstrained
  #    rustc build was LESS killable than the session it was starving. Raise
  #    nix-daemon so builds are sacrificed first, and add a soft MemoryHigh so
  #    the kernel reclaims/throttles a fat build before any hard kill.
  systemd.services.nix-daemon.serviceConfig = {
    OOMScoreAdjust = 500;
    # Hard ceiling on LOCAL nix builds: the nix-daemon cgroup (where local
    # build jobs run) may never exceed 6 of 12 cores nor 16 GiB RAM, regardless
    # of any --cores/--max-jobs/-j flag a build passes. somchai does the heavy
    # lifting; this keeps a local fallback (or a flag-forced build that slips
    # the hook) from saturating the box and starving the interactive session.
    # MemoryHigh (soft) reclaims/throttles before MemoryMax (hard) OOM-kills.
    CPUQuota = "600%";
    MemoryHigh = "14G";
    MemoryMax = "16G";
    # Run local builds at LOW priority so they yield to the interactive
    # session. CPUWeight is the cgroup-v2 lever (default 100; 10 gives builds
    # ~1/10 of contended CPU share); Nice reinforces thread ordering; idle IO
    # class keeps disk responsive. The CPUQuota above still caps absolute
    # usage; these only change who wins under contention.
    CPUWeight = 10;
    Nice = 19;
    IOSchedulingClass = "idle";
  };

  # 4. Wire systemd-oomd to actual cgroups. base.nix enables the daemon but
  #    NixOS monitors zero slices by default (oomctl showed both
  #    monitored-cgroup lists empty), so it could never act and the kernel
  #    global OOM kept firing first (27 oom-kill invocations in 7 days).
  #    With slices monitored, oomd kills the highest sustained-pressure
  #    descendant cgroup (chromium/builds) at 80% pressure for 30s, before
  #    the kernel nukes the session. oomd ignores OOMScoreAdjust (kernel-only
  #    knob); ManagedOOMPreference is its protection mechanism, so mark the
  #    credential stack avoid-last.
  systemd.oomd = {
    enableSystemSlice = true;
    enableUserSlices = true;
  };
  systemd.user.services.fafnir.serviceConfig.ManagedOOMPreference = "avoid";
  systemd.user.services.fafnir-openpgp.serviceConfig.ManagedOOMPreference = "avoid";
  # Protect the Claude Code agent session (runs under teleclaude.service in
  # app.slice at oom_score~800 with ManagedOOMPreference=none, i.e. a default
  # oomd candidate). Mark it avoid-last so oomd sacrifices builds/chromium/the
  # AI gateway first; the agent is the system's control plane. oomd ignores
  # OOMScoreAdjust and a user service cannot set a negative one, so this
  # preference is the only available protection lever. Hard-capping nix-daemon
  # was rejected: MemoryMax on the shared build cgroup SIGKILLs the daemon and
  # all in-flight builds atomically, wedging the store; the existing
  # MemoryHigh=20G + OOMScoreAdjust=500 already bias builds as the OOM victim.
  systemd.user.services.teleclaude.serviceConfig.ManagedOOMPreference = "avoid";

  # /tmp lives on the root fs and had accumulated 71G/18k entries: a nightly
  # recursive /tmp scan refreshes atime on every entry (all sampled nix-shell
  # dirs shared an identical atime to the nanosecond), and under relatime that
  # defeats systemd-tmpfiles' age check (max of atime/mtime/ctime vs 10d).
  # noatime freezes atime so age falls back to real mtime/ctime age; f2fs
  # lazytime already deferred atime writes, so there is no I/O cost.
  # cleanOnBoot additionally wipes /tmp wholesale on every boot.
  fileSystems."/".options = [ "noatime" ];
  boot.tmp.cleanOnBoot = true;

  # Boot spent ~60s in NetworkManager-wait-online (network.target at 4s,
  # network-online.target at 64s on slow 2.4GHz association), gating docker,
  # clatd and teamviewerd and thus multi-user/graphical.target. Nothing here
  # actually needs network-online at boot: wg2's endpoint is a bare IP and
  # re-handshakes on first packet, and the rest are happy to start degraded.
  systemd.services.NetworkManager-wait-online.enable = false;

  # DPTF-aware thermal management (INT3400 zone present, policy was the crude
  # step_wise governor): thermald clamps via RAPL proactively, sustaining
  # turbo longer during compile bursts instead of frequency-cliff throttling.
  # TLP owns governor/EPP/platform_profile; thermald owns RAPL - no conflict.
  services.thermald.enable = true;

  # No WWAN modem in this machine; NetworkManager pulls ModemManager in via
  # mkDefault true. Saves a daemon and a per-boot probe.
  networking.modemmanager.enable = false;

  systemd.services.restart-fprintd-on-resume = {
    description = "Restart fprintd after resume from sleep";
    wantedBy = [ "post-resume.target" ];
    after = [ "post-resume.target" ];
    script = "systemctl restart fprintd";
    serviceConfig.Type = "oneshot";
  };

  # Self-healing watchdog for stale fprintd sensor claims.
  #
  # hyprlock claims the fingerprint sensor via pam_fprintd during unlock.
  # If it freezes or crashes without releasing, fprintd keeps the claim and
  # every subsequent native fafnir sign fails with
  # net.reactivated.Fprint.Error.AlreadyInUse, while OpenPGP-through-fafnir
  # (no fprintd gate) keeps working. restart-fprintd-on-resume only covers
  # suspend/resume; this catches the freeze-during-normal-operation case by
  # watching for the "already claimed" denial in fprintd's journal and
  # restarting fprintd to drop the orphaned claim. The denial only logs when
  # a claim is genuinely refused, so a restart here is always corrective.
  systemd.services.fprintd-stale-claim-reaper = {
    description = "Restart fprintd when a stale sensor claim is detected";
    serviceConfig.Type = "oneshot";
    script = ''
      if ${pkgs.systemd}/bin/journalctl -u fprintd.service --since "-45s" --no-pager \
           | ${pkgs.gnugrep}/bin/grep -qi "already claimed"; then
        echo "stale fprintd claim detected; restarting fprintd"
        ${pkgs.systemd}/bin/systemctl restart fprintd.service
      fi
    '';
  };

  systemd.timers.fprintd-stale-claim-reaper = {
    description = "Periodically reap stale fprintd sensor claims";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "20s";
      AccuracySec = "5s";
    };
  };

  # Reaper for orphaned `ssh nix-builder@somchai.jonasem.com` sessions.
  #
  # When `nix build` runs against the somchai remote builder, the local
  # nix-daemon spawns a child `ssh nix-builder@somchai ... nix-daemon --stdio`
  # per build. If the parent `nix build` dies abnormally (SIGKILL, terminal
  # closed without `ssh -O exit`, agent crash), the SSH process is reparented
  # to nix-daemon (the system service) and never reaped: nix-daemon is still
  # alive, and SSH's ServerAliveInterval does not fire while the remote end
  # is healthy. The orphan keeps the per-builder upload lock, so all
  # subsequent `nix build` invocations queue forever behind it.
  #
  # This is the jester-side mirror of the `nix-daemon-stdio-reaper` unit that
  # runs on somchai itself (which handles the remote-side `nix-daemon --stdio`
  # zombies). Together they bound the lifetime of abandoned builder sessions.
  #
  # Logic: only kill ssh-nix-builder PIDs if the nix-daemon has no active
  # temproots entries (the daemon creates these during any build or copy, so
  # their presence means a legitimate build is in flight), and only after the
  # SSH process has been alive for >30 minutes.
  systemd.services.nix-ssh-builder-reaper = {
    description = "Reap orphaned ssh nix-builder@somchai sessions";
    path = [ pkgs.coreutils pkgs.procps pkgs.util-linux ];
    serviceConfig.Type = "oneshot";
    script = ''
      MAX_IDLE_S=1800   # 30 min
      LOG=/var/log/nix-ssh-builder-reaper.log
      ts=$(date -Iseconds)
      killed=0
      for pid in $(pgrep -f 'ssh nix-builder@somchai\.jonasem\.com' || true); do
        [ -d "/proc/$pid" ] || continue

        # Active build: nix-daemon holds temproots entries during any build/copy.
        # Checking these is more reliable than matching client process names.
        if [ -d /nix/var/nix/temproots ] && [ "$(ls -A /nix/var/nix/temproots 2>/dev/null)" ]; then
          continue
        fi

        etime=$(ps -o etimes= -p "$pid" 2>/dev/null | tr -d ' ')
        [ -n "$etime" ] || continue
        [ "$etime" -gt "$MAX_IDLE_S" ] || continue

        echo "$ts ORPHAN ssh-nix-builder pid=$pid etime=''${etime}s -> SIGKILL" >>"$LOG"
        kill -9 "$pid" 2>/dev/null || true
        killed=$((killed+1))
      done
      [ "$killed" -gt 0 ] && echo "$ts reaped $killed orphan ssh session(s)" >>"$LOG"
      exit 0
    '';
  };

  systemd.timers.nix-ssh-builder-reaper = {
    description = "Periodic reap of orphaned ssh nix-builder@somchai sessions";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "10min";
      OnUnitActiveSec = "10min";
      Unit = "nix-ssh-builder-reaper.service";
    };
  };

  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];

  hardware.graphics.extraPackages = with pkgs; [
  vpl-gpu-rt
  ];
  # For 32 bit applications 
  # hardware.graphics.extraPackages32 = with pkgs; [
  #   # RADV is used by default, no need for amdvlk
  # ];

  /*
  age.rekey = {
    # Obtain this using `ssh-keyscan` or by looking it up in your ~/.ssh/known_hosts
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEtJIhxEVsyKN/7fUBN4DYFoU6wgMJZbC8+hZk7Rv4Cx";
    # The path to the master identity used for decryption. See the option's description for more information.
    masterIdentities = [ ../../age/jonas-yubikey-7447013.pub ];
    #masterIdentities = [ "/home/myuser/master-key" ]; # External master key
    #masterIdentities = [ "/home/myuser/master-key.age" ]; # Password protected external master key
  };

  age.secrets.secret1.rekeyFile = ./secrets/secret1.age;
  age.secrets.secret1.generator.script = "alnum";

  environment.etc."secret1" = {
    source = config.age.secrets.secret1.path;
  };
  */
  
  #users.users.user1.passwordFile = config.age.secrets.secret1.path;

  system.stateVersion = "23.05";

  # Run nixos-upgrade hourly (overrides base.nix's "Mon..Fri 02:00") to track
  # the hourly claude-code input bumps. Shrink the randomized delay from base's
  # 1h so runs don't bunch toward the next hour's window.
  system.autoUpgrade.dates = lib.mkForce "hourly";
  system.autoUpgrade.randomizedDelaySec = lib.mkForce "10m";

  boot = {
    extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];
    kernelModules = [ "acpi_call" "uhid" ];
    # The AX211 BT controller autosuspends after ~2s idle; waking it stacks
    # on top of the MX Anywhere 3S's own sleep-reconnect latency and can eat
    # the first click after idle. Keep the controller awake (small idle-power
    # cost). Takes effect on reboot (module load time option).
    extraModprobeConfig = ''
      options btusb enable_autosuspend=0
    '';
    kernelParams = [
      "mem_sleep_default=s2idle"  # Only sleep mode available (firmware has no S3)
      # Disable Panel Self-Refresh on the i915 driver. Hyprland crashes here
      # have shown up as GPU context resets after which Hyprland's
      # glGetGraphicsResetStatus() returns GL_GUILTY_CONTEXT_RESET and it
      # aborts. PSR (panel self-refresh) failing to wake the display pipe is a
      # common trigger on mobile Iris Xe. Disabling PSR is the low-risk,
      # reversible first-line mitigation. Only cost is slightly higher idle
      # power. Remove if it does not help.
      "i915.enable_psr=0"
    ];
    loader = {
      systemd-boot =
        {
          enable = true;
          graceful = true;
        };
      efi.canTouchEfiVariables = true;
    };
    #kernelPackages = pkgs.linuxPackages_6_6;
    #kernelPackages = pkgs.unstable.linuxPackages_latest;

    binfmt.emulatedSystems = [ ];
  };

  # Shorter page-scan intervals while connectable: the MX Anywhere 3S sleeps
  # after idle and must reconnect on the next click; FastConnectable narrows
  # that window so the wake-up click is less likely to be lost. Merges into
  # the shared bluetooth settings from desktop_base.nix.
  hardware.bluetooth.settings.General.FastConnectable = true;

  # Disambiguate the two RTK USB-C panels (they ship with identical EDID
  # serials, which confuses wlroots/Hyprland and prevents distinct
  # per-output position rules). The kernel-assigned DP connector names
  # are unstable across reboots (we've seen DP-5/DP-6 and DP-7/DP-8),
  # but the two panels always land on adjacent connectors. Override every
  # odd DP-N: exactly one of the two panels picks up the modified EDID,
  # the other keeps its native one, so they end up with distinct serials.
  hardware.display.outputs."DP-1".edid = "rtk-dp8.bin";
  hardware.display.outputs."DP-3".edid = "rtk-dp8.bin";
  hardware.display.outputs."DP-5".edid = "rtk-dp8.bin";
  hardware.display.outputs."DP-7".edid = "rtk-dp8.bin";
  hardware.display.outputs."DP-9".edid = "rtk-dp8.bin";
  hardware.display.outputs."DP-11".edid = "rtk-dp8.bin";
  hardware.display.edid.packages = [
    (pkgs.runCommand "rtk-edid" { } ''
      mkdir -p "$out/lib/firmware/edid"
      cp ${./edid/rtk-dp8.bin} "$out/lib/firmware/edid/rtk-dp8.bin"
    '')
  ];

  networking = {
    hostName = "jester";
    getaddrinfo.enable = false;

    bridges = {
      br0 = {
        interfaces = [ ];
      };
      br1 = {
        interfaces = [ ];
      };
    };

    wireguard = {
      interfaces = {
        /*
          wg0 = {
          ips = [ "10.50.0.37/32" ];
          peers = [
          {
          publicKey = "IR9lBjFR2qX4UmgML5oBykUgrAzqOzhaNpF+xjD8L3k=";
          allowedIPs = [
          "10.50.0.0/16"
          ];
          endpoint = "13.48.43.75:123";
          }

          ];
          };
        
          wg1 = {
          privateKeyFile = "/var/lib/wireguard/privatekey";
          generatePrivateKeyFile = true;
          ips = [ "10.111.255.253/32" "10.112.255.253/32" ];
          peers = [
          {
          publicKey = "zYgI7WYsKHNh70oZvdHDPKCeqKeEdsQbAIxtlNGSw2c=";
          allowedIPs = [
          "10.111.0.0/16"
          ];
          endpoint = "18.198.12.235:123";
          }

          {
          publicKey = "Uv6JEWpVPBAt44WBRWmyGRYtF0k7mYm2vRKmkOArtUw=";
          allowedIPs = [
          "10.112.0.0/16"
          ];
          endpoint = "54.75.127.255:123";
          }

          ];
          };

        */

        
          
          wg2 = {
          privateKeyFile = "/var/lib/wireguard/privatekey";
          allowedIPsAsRoutes = false;
          metric = 100;
          ips = [ "10.128.12.3/24" "2a12:5800:0:27::3/64" ];
          peers = [
          {
          publicKey = "kCvTCiqn4/mhkbWF9eKaTycAp7yHfkMYu3uEuuneFFc=";
          allowedIPs = wg2AllowedIPs;
          endpoint = "194.26.208.1:51822";
          }
          ];
          };
        
        /*

          
          wg3 = {
          privateKeyFile = "/var/lib/wireguard/privatekey";
          ips = [ "10.128.12.3/24" "2a12:5800:0:27::3/64" ];
          peers = [
          {
          publicKey = "Z712joOcYZDyiJrynswegnIlRsebKrIskvw2rOIBX2Y=";
          allowedIPs = [
                "10.128.12.0/24"
                "2a12:5800:0:27::/64"
                "10.0.0.0/8"
                "172.16.0.0/12"
                "192.168.0.0/16"
                "100.64.0.0/10"
                "192.121.29.0/24"
                "194.26.208.0/24"
                "2a12:5800::/29"
                #"0::/0"
                #"0.0.0.0/0"
                
              ];
          endpoint = "194.26.208.43:53";
          }
          ];
          };

          */
        	



      };
    };

    interfaces = {
      #"enp48s0u2u1.102" = {
      #  useDHCP = true;
      #};
      #"enp48s0u2u1.150" = {
      #  useDHCP = true;
      #};

      wlp0s20f3.ipv4.routes = [
        {
            address = "194.26.208.1";
            prefixLength = 32;

        }
        {
            address = "194.26.208.43";
            prefixLength = 32;

        }
      ];
      wg2.ipv4.routes = wg2IPv4Routes;
      wg2.ipv6.routes = wg2IPv6Routes;
    };

    vlans = {
      #"enp48s0u2u1.102" = {
      #  id = 102;
      #  interface = "enp48s0u2u1u2";
      #};
      #"enp48s0u2u1.150" = {
      #  id = 150;
      #  interface = "enp48s0u2u1u2";
      #};
    };

  dhcpcd = {
    enable = true;
    extraConfig = "
    define 108 uint32 ipv6only_preferred
    request ipv6only_preferred
    ";
  };

  networkmanager.dispatcherScripts = [
    {
      type = "basic";
      source = pkgs.replaceVars ./prefer-ipv4-fallback.sh {
        iputils = pkgs.iputils;
      };
    }
  ];

  };

  services = {
    xserver = {
      videoDrivers = [ "modesetting" ];
    };
    undervolt = {
      enable = false;
    };

    fprintd = {
      enable = true;
    };

    # ofono (telephony) and teamviewer removed 2026-06: ofono had no hardware
    # to manage (Wi-Fi-only machine, daemon sat inactive) and teamviewer had
    # zero sessions in the journal while keeping a 37-thread daemon resident.
    # Re-add services.teamviewer.enable = true if remote support is needed.

    clatd = {
      enable = true;
      settings = {
        plat-prefix = "64:ff9b::/96";
      };
    };

  };

  networking.firewall.extraCommands = ''
    # Allow IPv6 forwarding for clatd
    ip6tables -I FORWARD -i clat -j ACCEPT
    ip6tables -I FORWARD -o clat -j ACCEPT
  '';

  environment.systemPackages = with pkgs; [
    cargo-sweep
    # Wrapper scopes AWS_PROFILE=sccache-shared to sccache invocations only
    # so it doesn't bleed into other AWS-aware tools in the shell.
    # nice 10: the sccache server persists in the interactive terminal scope
    # at nice 0, competing with keystrokes; 10 yields to interactive work
    # while staying above cargo builds (nice 19 via the base.nix wrapper).
    (writeShellScriptBin "sccache" ''
      export AWS_PROFILE=sccache-shared
      exec ${coreutils}/bin/nice -n 10 ${sccache}/bin/sccache "$@"
    '')
    mold
    docker
    docker-compose
    ffmpeg
    #python37Packages.imutils
    #python37Packages.scipy
    #python37Packages.shapely
    opencl-headers
    labelImg
    tesseract5  # OCR tool with all language support

    #bambu-studio
    #orca-slicer

    #pkgsCross.armv7l-hf-multiplatform.buildPackages.targetPackages.glibc

    #cardano-node
    #cardano-hw-cli

    vulkan-validation-layers

    #vpp
    
    #claudia
    
    # fit-web  # Needs additional dependencies
    # fit-entire-website  # Needs additional dependencies
    # fit-main  # Main FIT GUI application (needs work)

    # chromium is in desktop_base.nix with --remote-debugging-port=9222

    unstable.telegram-desktop
    whatsapp-electron

    bun
    sox

    claude-code

    nix-tcp-proxy

    #devenv


  ];

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };

  nix = { 
    extraOptions = ''
        trusted-users = root jonas

        extra-substituters = https://devenv.cachix.org
        extra-trusted-public-keys = devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=
    '';
    settings.experimental-features = [ "nix-command" "flakes" ];
    settings.builders-use-substitutes = true;

  };

  hardware = {

    #firmware = [
    #  pkgs.unstable.ivsc-firmware
    #];

    /*
    pulseaudio.extraConfig = ''
      load-module module-alsa-sink   device=hw:0,0 channels=4
      load-module module-alsa-source device=hw:0,6 channels=4
    '';
    */

    #opengl = {
    #extraPackages = with pkgs; [ intel-ocl ];
    #};

  };






  # Allow jonas to restart fprintd without a password (needed to clear stale
  # D-Bus claims after hyprlock exits without releasing the sensor).
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") == "fprintd.service" &&
          action.lookup("verb") == "restart" &&
          subject.user == "jonas") {
        return polkit.Result.YES;
      }
    });
  '';

  security.tpm2 = {
    enable = true;
    # abrmd is a userspace TPM resource manager that competes with the
    # kernel's /dev/tpmrm0 for session slots. fafnir uses tpmrm0 by
    # default; running both yields "Esys called in bad sequence"
    # errors when they independently juggle TPM state. Disable abrmd
    # unless a legacy app explicitly needs a dbus/socket TCTI.
    abrmd.enable = false;
  };

  # fafnir: TPM-backed SSH agent + FIDO authenticator + age plugin.
  services.fafnir = {
    enable       = true;
    approval     = "fprintd";
    enableRsa    = true;
    rsaBits      = 2048;
    autoLockIdleSecs = 28800;
    powerledPath = "/sys/class/leds/tpacpi::power";
    # YubiKey OpenPGP keys are now reached via fafnir-openpgp's own
    # ssh-agent socket (scdaemon passthrough). fafnir's main agent
    # forwards to it, so SSH_AUTH_SOCK on the TPM agent gets both
    # the TPM identity and the card auth key.
    agentSockPaths = [ "$XDG_RUNTIME_DIR/fafnir/openpgp-ssh.sock" ];
    secretService.enable = true;
    # Opt-in LLM auto-approver (Venice.ai). Routine native sign/decrypt
    # requests skip the fingerprint prompt when they match a
    # human-approved precedent and the model concurs. Key lives in a
    # 0600 file outside the nix store.
    llmApprover = {
      enable     = true;
      apiKeyFile = "/home/jonas/.config/fafnir/venice.key";
      storePath  = "/home/jonas/.local/share/fafnir/approver/decisions.redb";
    };
  };

  # fafnir-keepassxc-bridge: native-messaging host for KeePassXC-Browser
  # (Chromium/Firefox), serving credentials out of fafnir's vault.
  services.fafnir-keepassxc-bridge = {
    enable = true;
    users  = [ "jonas" ];
  };

  # fafnir-wallet: Ledger-Nano-emulating Solana HD wallet daemon
  # (TPM-protected BIP39 seed, exposed as a UHID Ledger device).
  services.fafnir-wallet = {
    enable = true;
    users  = [ "jonas" ];
  };

  # fafnir-openpgp: gpg-agent replacement, TPM-backed. Mutually exclusive
  # with the upstream gpg-agent user service for the listed users.
  services.fafnir-openpgp = {
    enable          = true;
    users           = [ "jonas" ];
    pinentry        = pkgs.pinentry-qt;
    useSystemPcscd  = true;
  };

  # Expose YubiKey PIV slots through fafnir's PKCS#11 aggregator so the
  # fafnir-openpgp ssh-agent socket advertises PIV identities alongside
  # the OpenPGP card subkeys. OpenPGP is intentionally disabled here:
  # fafnir-openpgp already serves the OpenPGP applet via scdaemon, and
  # routing it through opensc-pkcs11 in parallel would cause PCSC
  # sharing violations on the YubiKey.
  services.fafnir.pkcs11.cards = {
    enable = true;
    openpgp.enable = false;
  };

  # Bind fafnir-openpgp to the XDG runtime gnupg socket path so gpg
  # tools find it at the standard location (gpgconf --list-dirs
  # agent-socket returns %t/gnupg/S.gpg-agent, not ~/.gnupg/S.gpg-agent).
  # Disable the competing gpg-agent sockets so they don't lock the
  # YubiKey first via their own scdaemon.
  systemd.user.services.fafnir-openpgp = {
    serviceConfig.ExecStartPre = lib.mkAfter
      [ "${pkgs.coreutils}/bin/mkdir -p %t/gnupg" ];
    serviceConfig.Environment  = lib.mkAfter [ "GNUPGHOME=%t/gnupg" ];
    unitConfig.Conflicts       = "gpg-agent.service";
  };
  systemd.user.sockets.gpg-agent.enable       = lib.mkForce false;
  systemd.user.sockets.gpg-agent-extra.enable = lib.mkForce false;

  # Raise per-user systemd default LimitNOFILE so transient units (e.g.
  # `systemd-run --user -p LimitNOFILE=...`) can be granted >524288 fds.
  # Required by magicblock-validator (RocksDB) for ER integration tests.
  systemd.user.extraConfig = ''
    DefaultLimitNOFILE=2097152
  '';

  # The module defaults to graphical-session.target, but WAYLAND_DISPLAY
  # is only imported into systemd's environment by the Hyprland exec-once
  # that starts hyprland-session.target. Binding to that target ensures
  # fafnir-prompt can connect to the compositor.
  systemd.user.services.fafnir = {
    unitConfig.After  = lib.mkForce [ "fafnir-openpgp.service" "hyprland-session.target" ];
    unitConfig.Wants  = lib.mkForce [ "fafnir-openpgp.service" ];
    unitConfig.PartOf = lib.mkForce [ "hyprland-session.target" ];
    wantedBy          = lib.mkForce [ "hyprland-session.target" ];
  };
  systemd.user.services.fafnir-passkey = {
    unitConfig.After  = lib.mkForce [ "fafnir.service" "hyprland-session.target" ];
    unitConfig.PartOf = lib.mkForce [ "hyprland-session.target" ];
    wantedBy          = lib.mkForce [ "hyprland-session.target" ];
  };

  # fafnir-secret-service owns org.freedesktop.secrets on jester,
  # so disable gnome-keyring's secrets component (default-enabled
  # in config/appearance.nix) to avoid the D-Bus name race.
  services.gnome.gnome-keyring.enable = lib.mkForce false;

  # gpg-agent SSH emulation has been retired — fafnir-openpgp serves
  # the YubiKey auth subkey directly on its own ssh-agent socket via
  # scdaemon passthrough, and fafnir's main agent forwards to it.
  programs.ssh.extraConfig = ''

    Host somchai.jonasem.com
      User nix-builder
      IdentitiesOnly yes
      IdentityAgent none
      IdentityFile /etc/ssh/ssh_host_ed25519_key
      ProxyCommand /home/jonas/workspace/private-nixos-configuration/machines/somchai/somchai-proxy.sh %h %p
      # ControlMaster with a SHORT persist. The earlier failure was
      # ControlPersist 8h: somchai idle-shuts-down after ~5min idle
      # (idle-shutdown.service: IDLE_CONSECUTIVE=5 × 1min timer), so an 8h
      # master vastly outlived the box. When the box slept the master TCP
      # died but the local socket lingered; new channels reused the stale
      # socket, bypassed the ProxyCommand, and never fired the wake Lambda
      # ("ControlSocket already exists" / "Broken pipe" / "unexpected
      # end-of-file"). Removing mux entirely fixed that but regressed the
      # wake path: with no master, EVERY nix ssh channel (build + each
      # substitution) re-runs the full ProxyCommand, so a cold-box build
      # storms the wake Lambda + prefill in parallel, starving the aws CLI
      # ("Lambda invoke failed") and slowing the boot.
      #
      # ControlPersist 120s is the fix: one master serves all of a build's
      # channels (wake + prefill run once per build, not per channel), and
      # 120s « the 5min idle window means the master always dies before the
      # box can sleep, so it can never go stale. Mux idle masters are
      # explicitly ignored by somchai's idle-shutdown, so a lingering master
      # never holds the box awake either.
      ControlMaster auto
      ControlPath /tmp/nix-ssh-%r@%h:%p
      ControlPersist 120
      ConnectTimeout 120
      ServerAliveInterval 60
      ServerAliveCountMax 10
      TCPKeepAlive yes
  '';

  # Use somchai (AWS EC2 c7i in ap-southeast-7) as a remote nix builder.
  # Root SSHes via the host ed25519 key (jester-tpm), authorized for jonas
  # on somchai via the shared ssh-keys.nix.
  # Prevent nix-daemon crash on boot: Settings static initializer dereferences
  # HOME before nscd is ready. Setting HOME explicitly avoids the race.
  systemd.services.nix-daemon.environment.HOME = "/root";

  nix.distributedBuilds = true;
  nix.settings.max-jobs = 1; # 0 breaks preferLocalBuild=true derivations (e.g. /etc/issue)
  # Cap per-build parallelism for the local fallback path. The default
  # (cores = 0) means "all 12"; SCHED_IDLE keeps the CPU polite but 12-wide
  # compile memory can still push the session into MemoryHigh throttling.
  # Halved from 8 to reduce resource pressure; somchai does the heavy lifting.
  nix.settings.cores = 4;
  # somchai is an EC2 spot instance woken on demand via Lambda from the
  # ProxyCommand; cold boot is 60-90s. Keep this generous so nix-daemon
  # doesn't yank the SSH handshake before the wake completes.
  nix.settings.connect-timeout = 360;
  # Buffer for NAR downloads from remote builder / S3 cache.
  # 256 MiB: large enough to stream the biggest store paths (compiled APK,
  # BoringSSL .a) without hitting "download buffer is full", but small enough
  # to avoid the SIGABRT that 1 GiB caused (4 concurrent jobs × 1 GiB = 4 GiB
  # allocation → nix-daemon abort() on internal assertion with Nix 2.31.4).
  nix.settings.download-buffer-size = 256 * 1024 * 1024; # 256 MiB
  # Limit substituter parallelism so substituting paths back from
  # somchai/cache.nixos.org doesn't exhaust SSH channel slots and starve
  # the build itself. Default 16 is way too aggressive for our link.
  nix.settings.max-substitution-jobs = 2;
  # Fall back to local build when somchai is unreachable instead of failing.
  nix.settings.fallback = true;
  # Larger TCP backoff on remote-build SSH so the link survives the
  # post-build-hook S3 push hiccup that briefly blocks somchai's
  # nix-daemon write side.
  nix.settings.stalled-download-timeout = 300;
  # Expose /etc/gai.conf to the build sandbox so fixed-output fetchurl
  # derivations honor the host's prefer-ipv4-fallback dispatcher. Without
  # this, glibc inside the sandbox uses RFC 3484 default precedence (v6
  # preferred), and big VSIX/etc fetches over a slow IPv6 path crawl.
  nix.settings.extra-sandbox-paths = [ "/etc/gai.conf" ];
  # Pull from somchai's S3 binary cache using a read-only IAM credential.
  # somchai-nix-read in /root/.aws/credentials: s3:GetObject + s3:ListBucket only.
  nix.settings.substituters = lib.mkAfter [
    "s3://somchai-nix-cache-723173433317?region=ap-southeast-7&profile=somchai-nix-read"
    # Prebuilt upstream Hyprland (jester runs the hyprwm/Hyprland flake build).
    "https://hyprland.cachix.org"
  ];
  nix.settings.trusted-public-keys = lib.mkAfter [
    "somchai-cache-1:NBIJCnDzlLzG9mNpHf4iEv17xZ+9ceF5+NBBdYxambc="
    "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
  ];

  # Run the compositor (and matching xdg portal) from the upstream Hyprland
  # flake instead of nixpkgs-unstable. mkForce overrides the package set in the
  # shared config/i3_x11.nix module. hyprctl/hyprlock stay on nixpkgs-unstable
  # (only `hyprctl dispatch dpms on` is used; IPC skew is negligible) to avoid a
  # hyprctl binary collision in environment.systemPackages.
  programs.hyprland.package = lib.mkForce hyprland.packages.${pkgs.system}.hyprland;
  programs.hyprland.portalPackage = lib.mkForce hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
  nix.buildMachines = [{
    hostName = "somchai.jonasem.com";
    sshUser = "nix-builder";
    sshKey = "/etc/ssh/ssh_host_ed25519_key";
    systems = [ "x86_64-linux" ];
    # Must match somchai's own nix max-jobs (private-nixos-configuration/
    # machines/somchai/configuration.nix, NOT this repo) or jester dispatches
    # more than the remote will run. somchai: 16 physical cores / 32 vCPU (HT).
    # Profile 4 jobs x 8 cores = 32 threads = exactly the vCPU count (no HT
    # oversubscription), trading per-build speed for burst parallelism (the
    # 6-way cargo-test* check batch). KEEP IN SYNC with somchai max-jobs=4.
    maxJobs = 4;
    speedFactor = 4;
    supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
    protocol = "ssh-ng";
  }];
  programs.ssh.knownHosts.somchai = {
    hostNames = [ "somchai.jonasem.com" "2406:da14:8b88:b701:ce5e:831b:b719:c940" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEsY31lwQd6bxClPwdH3kGDfKjSEcBmTUoxeP+7aaXMY";
  };

  # Software debounce for MX Anywhere 3S which has bouncing left-click switch
  environment.etc."libinput/local-overrides.quirks".text = ''
    [Logitech MX Anywhere 3S Bounce Fix]
    MatchUdevType=mouse
    MatchName=*Logitech MX Anywhere 3S*
    ModelLogitechBustypeRollover=1
  '';

  # Weekly cleanup of stale Rust build artifacts in ~/workspace.
  # cargo-sweep --time 30 removes artifacts unused for 30 days; entire
  # target/ dirs whose parent Cargo.toml hasn't been built in 30 days are
  # wiped wholesale. Stays out of .git, node_modules, .direnv, result.
  systemd.user.services.cargo-sweep-workspace = {
    description = "Sweep stale Rust build artifacts in ~/workspace";
    serviceConfig = {
      Type = "oneshot";
      Nice = 19;
      IOSchedulingClass = "idle";
    };
    path = [ pkgs.cargo-sweep pkgs.coreutils pkgs.findutils ];
    script = ''
      set -u
      ws="$HOME/workspace"
      [ -d "$ws" ] || exit 0
      # Wipe whole target/ dirs older than 30 days (sibling Cargo.toml).
      find "$ws" -type d -name target -prune \
        \( -path '*/node_modules/*' -o -path '*/.git/*' \) -prune -o \
        -type d -name target -prune -print0 2>/dev/null \
      | while IFS= read -r -d "" t; do
          [ -f "$(dirname "$t")/Cargo.toml" ] || continue
          if [ -z "$(find "$t" -newermt '30 days ago' -print -quit 2>/dev/null)" ]; then
            rm -rf "$t"
          fi
        done
      # Sweep stale artifacts inside remaining target/ dirs.
      cargo sweep --recursive --time 30 "$ws" || true
    '';
  };
  systemd.user.timers.cargo-sweep-workspace = {
    description = "Weekly cargo-sweep of ~/workspace";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };
}
