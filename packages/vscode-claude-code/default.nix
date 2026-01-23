{ pkgs, stdenv, lib, autoPatchelfHook }:

pkgs.vscode-utils.buildVscodeMarketplaceExtension {
  mktplcRef = {
    name = "claude-code";
    publisher = "anthropic";
    version = "2.1.17";
    hash = "sha256-1f5birp6vwny1fm23z182dvzc0cx06hc14n0xs64hczjwi0r3jwv";
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