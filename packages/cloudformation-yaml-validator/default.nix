{  pkgs, stdenv, lib, autoPatchelfHook }:

pkgs.vscode-utils.buildVscodeMarketplaceExtension {
  mktplcRef =
    let
      sources = {
        "x86_64-linux" = {
          #arch = "linux-x64";
          hash = "sha256-9SGmDT1VRgl5Uh2KToYzEti2WzNlC+iGYd9HGm3Gun8=";
        };
      };
    in
    {
      name = "cloudformation-yaml-validator";
      publisher = "champgm";
      version = "0.3.15";
    }
    // sources.${stdenv.system};
  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];
}