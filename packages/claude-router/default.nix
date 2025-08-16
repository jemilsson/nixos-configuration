{ pkgs, claude-code-router, ... }:

pkgs.writeShellScriptBin "claude-router" ''
  exec ${claude-code-router}/bin/ccr code "$@"
''