{  pkgs, stdenv, lib, autoPatchelfHook }:

pkgs.vscode-utils.buildVscodeMarketplaceExtension {
  mktplcRef =
    let
      sources = {
        "x86_64-linux" = {
          arch = "linux-x64";
          hash = "sha256-Xu+Ya8xCDkIgtk0CZ2KJQtTLPd8fZPgJuzvFiTryUEc=";
        };
      };
    in
    {
      name = "continue";
      publisher = "Continue";
      version = "0.9.215";
    }
    // sources.${stdenv.system};
  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];
  meta = {
    description = "Open-source autopilot for software development - bring the power of ChatGPT to your IDE";
    downloadPage = "https://marketplace.visualstudio.com/items?itemName=Continue.continue";
    homepage = "https://github.com/continuedev/continue";
    license = lib.licenses.asl20;
    maintainers = [ lib.maintainers.raroh73 ];
    platforms = [
      "x86_64-linux"
    ];
  };
}