{ config, lib, pkgs, ... }:

# Motion-triggered room recording ("room-watch"), for watching a hotel room.
# The IPU6/OV2740 camera is only reachable via libcamera/PipeWire, so motion(1)
# cannot read it directly: a GStreamer feed copies the PipeWire camera stream
# into a v4l2loopback node, and motion watches that node.
#
# Off at boot. Start when leaving the room:
#   systemctl --user start room-watch
# Stop on return:
#   systemctl --user stop room-watch
# Recordings land in ~/Videos/room-watch/ (mkv clips + trigger snapshots) and
# rsync to devbox:room-watch/ every 60s so footage survives laptop theft.
# Upload needs the fafnir ssh agent unlocked; test before leaving:
#   systemctl --user status room-watch-sync

let
  gst = pkgs.gst_all_1;
  loopbackDev = "/dev/video42";

  # Telegram alert with an AI one-liner. Vision via the local
  # venice-subscription-api (port 8000); falls back to a bare caption if the
  # description fails so the photo still arrives. Credentials (not in repo):
  # ~/.config/room-watch/telegram.env with TELEGRAM_BOT_TOKEN and
  # TELEGRAM_CHAT_ID. Missing env file = hook exits quietly (feature off).
  notifyScript = pkgs.writeShellScript "room-watch-notify" ''
    img="$1"
    [ -f /home/jonas/.config/room-watch/telegram.env ] || exit 0
    . /home/jonas/.config/room-watch/telegram.env
    [ -n "$TELEGRAM_BOT_TOKEN" ] || exit 0

    # venice.ai intermittently drops the attachment (same request, ~1 in 4
    # replies "NO IMAGE" in testing); one retry covers it.
    for attempt in 1 2; do
    desc=$(${pkgs.coreutils}/bin/timeout 60 ${pkgs.bash}/bin/bash -c '
      b64=$(${pkgs.coreutils}/bin/base64 -w0 "'"$img"'")
      ${pkgs.curl}/bin/curl -s -m 55 localhost:8000/v1/chat/completions \
        -H "Content-Type: application/json" \
        --data-binary @<(printf %s "{\"model\":\"qwen3-vl-235b-a22b\",\"max_tokens\":100,
          \"messages\":[{\"role\":\"user\",\"content\":[
            {\"type\":\"text\",\"text\":\"One factual sentence: what is happening in this hotel-room security snapshot? Note any person or change.\"},
            {\"type\":\"image_url\",\"image_url\":{\"url\":\"data:image/jpeg;base64,$b64\"}}]}]}") \
      | ${pkgs.jq}/bin/jq -r ".choices[0].message.content // empty"
    ') || desc=""
      case "$desc" in
        ""|*"NO IMAGE"*|*"cannot see"*|*"can't see"*) continue ;;
        *) break ;;
      esac
    done
    case "$desc" in
      *"NO IMAGE"*|*"cannot see"*|*"can't see"*) desc="" ;;
    esac
    [ -n "$desc" ] || desc="Motion detected"

    ${pkgs.curl}/bin/curl -s -m 30 \
      "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendPhoto" \
      -F "chat_id=$TELEGRAM_CHAT_ID" -F "photo=@$img" \
      -F "caption=$desc" >/dev/null \
      || ${pkgs.coreutils}/bin/echo "telegram send failed for $img" >&2
  '';

  motionConf = pkgs.writeText "room-watch-motion.conf" ''
    video_device ${loopbackDev}
    width 1280
    height 720
    framerate 15

    target_dir /home/jonas/Videos/room-watch

    # Sensitivity: pixels changed to count as motion; tune up if the
    # aircon curtain-flutter false-triggers.
    threshold 1500
    lightswitch_percent 10
    despeckle_filter EedDl
    minimum_motion_frames 2
    event_gap 10
    pre_capture 15
    post_capture 30

    on_picture_save ${notifyScript} %f
    movie_output on
    movie_codec mkv
    movie_quality 60
    picture_output first
    text_left ROOM %Y-%m-%d %T

    webcontrol_port 0
    stream_port 0
    log_level 5
  '';
in
{
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModprobeConfig = ''
    options v4l2loopback video_nr=42 card_label=room-watch exclusive_caps=1
  '';

  systemd.user.services.room-watch-feed = {
    description = "PipeWire camera feed into v4l2loopback for room-watch";
    requires = [ "pipewire.service" ];
    after = [ "pipewire.service" "wireplumber.service" ];
    serviceConfig = {
      # target-object: the libcamera node name for the built-in camera.
      # 1280x720 matches the 16:9 sensor (1932x1092): 4:3 modes crop the
      # sides and look zoomed in. Converted to YUY2 for motion's sake.
      ExecStart = ''
        ${gst.gstreamer}/bin/gst-launch-1.0 -e \
          pipewiresrc target-object=libcamera_input.__SB_.PC00.LNK1 \
          ! videoconvert ! video/x-raw,format=YUY2,width=1280,height=720 \
          ! v4l2sink device=${loopbackDev} sync=false
      '';
      Restart = "on-failure";
      RestartSec = 3;
    };
    # .out explicitly: the default gstreamer output is "bin", which lacks the
    # core plugins (capsfilter etc.); without them caps-filter syntax fails.
    environment.GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPath "lib/gstreamer-1.0" [
      gst.gstreamer.out gst.gst-plugins-base gst.gst-plugins-good pkgs.pipewire
    ];
  };

  # Offsite copy: push clips to Tigris (fly.io S3) so theft of the laptop
  # doesn't take the evidence with it. Loop instead of per-event motion hooks:
  # a periodic sync catches up automatically after wifi drops.
  # Credentials (not in repo): ~/.config/room-watch/tigris.env with
  #   AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY from `fly storage create`.
  systemd.user.services.room-watch-sync = {
    description = "Upload room-watch recordings to Tigris";
    serviceConfig = {
      EnvironmentFile = "/home/jonas/.config/room-watch/tigris.env";
      ExecStart = pkgs.writeShellScript "room-watch-sync" ''
        while true; do
          ${pkgs.rclone}/bin/rclone copy /home/jonas/Videos/room-watch \
            ":s3,provider=Other,env_auth,endpoint='https://fly.storage.tigris.dev':room-watch" \
            || echo "sync failed, retrying in 60s"
          sleep 60
        done
      '';
      Restart = "on-failure";
      RestartSec = 10;
    };
  };

  systemd.user.services.room-watch = {
    description = "Motion-triggered room recording";
    requires = [ "room-watch-feed.service" "room-watch-sync.service" ];
    after = [ "room-watch-feed.service" ];
    serviceConfig = {
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/Videos/room-watch";
      ExecStart = "${pkgs.motion}/bin/motion -n -c ${motionConf}";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
}
