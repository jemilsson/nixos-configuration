{ pkgs, ... }:

pkgs.writeShellScriptBin "ccr-configure-venice" ''
  ${pkgs.python3.withPackages (ps: with ps; [ requests ])}/bin/python3 ${./configure-venice.py} "$@"
''