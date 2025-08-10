{ pkgs, stdenv, lib, autoPatchelfHook }:

pkgs.vscode-utils.buildVscodeMarketplaceExtension {
  mktplcRef = {
    name = "claude-code";
    publisher = "anthropic";
    version = "1.0.72";
    hash = "sha256-ILdS4HpDUntpU3fI9+OTbxQA9iINsd5iQt6lK5yDjw4=";
  };

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];

  meta = {
    description = "Anthropic's Claude AI assistant for Visual Studio Code";
    downloadPage = "https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code";
    homepage = "https://github.com/anthropics/claude-code";
    license = lib.licenses.unfree; # Note: Check actual license
    maintainers = [ lib.maintainers.your-maintainer-handle ];
    platforms = lib.platforms.all;
  };
}