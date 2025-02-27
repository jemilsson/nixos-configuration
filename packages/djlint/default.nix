{  pkgs, stdenv, lib, autoPatchelfHook }:

pkgs.vscode-utils.buildVscodeMarketplaceExtension {
  mktplcRef =
    let
      sources = {
        "x86_64-linux" = {
          #arch = "linux-x64";
          hash = "sha256-+T2Q8swtn8yrW5UxWn9lkh40wVIZ3D4IpvmYOvDnoWY=";
        };
      };
    in
    {
      name = "djlint";
      publisher = "monosans";
      version = "2025.0.0";
    }
    // sources.${stdenv.system};
  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];
}