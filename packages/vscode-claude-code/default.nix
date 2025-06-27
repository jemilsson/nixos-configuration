{ pkgs, stdenv, lib, autoPatchelfHook }:

pkgs.vscode-utils.buildVscodeMarketplaceExtension {
  mktplcRef = {
    name = "claude-code";
    publisher = "anthropic";
    version = "1.0.31";
    hash = "sha256-3brSSb6ERY0In5QRmv5F0FKPm7Ka/0wyiudLNRSKGBg=";
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