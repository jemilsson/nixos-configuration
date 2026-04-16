{ pkgs, ... }:

# Cleans up Claude Code session logs, subagent logs, and tool-result
# caches older than 7 days to prevent inode exhaustion.

{
  systemd.user.services.claude-log-cleanup = {
    unitConfig = {
      Description = "Clean up old Claude Code session logs";
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = toString (pkgs.writeShellScript "claude-log-cleanup" ''
        ${pkgs.findutils}/bin/find "$HOME/.claude/projects" -type f -mtime +7 -delete 2>/dev/null
        ${pkgs.findutils}/bin/find "$HOME/.claude/projects" -type d -empty -delete 2>/dev/null
      '');
    };
  };

  systemd.user.timers.claude-log-cleanup = {
    unitConfig = {
      Description = "Daily cleanup of old Claude Code session logs";
    };
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };
}
