{ pkgs, ... }:

pkgs.writeShellScriptBin "claude-aws" ''
  export CLAUDE_CODE_USE_BEDROCK=1
  export ANTHROPIC_MODEL='us.anthropic.claude-sonnet-4-20250514-v1:0'
  export ANTHROPIC_SMALL_FAST_MODEL='us.anthropic.claude-3-5-haiku-20241022-v1:0'
  export AWS_REGION='us-east-1'
  exec ${pkgs.unstable.claude-code}/bin/claude "$@"
''