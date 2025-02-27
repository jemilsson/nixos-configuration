{  pkgs, stdenv, lib, autoPatchelfHook }:

pkgs.vscode-utils.buildVscodeMarketplaceExtension {
  mktplcRef =
    let
      sources = {
        "x86_64-linux" = {
          #arch = "linux-x64";
          hash = "sha256-m+n7nuLK11jlS/dALRPDkSLNUBt6aj/sKZTk2lyPdBU=";
        };
      };
    in
    {
      name = "boto3-ide";
      publisher = "Boto3typed";
      version = "0.6.0";
    }
    // sources.${stdenv.system};
  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];
}