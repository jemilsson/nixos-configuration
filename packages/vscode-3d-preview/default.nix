{ pkgs, stdenv, lib, autoPatchelfHook }:

pkgs.vscode-utils.buildVscodeMarketplaceExtension {
  mktplcRef = {
    name = "vscode-3d-preview";
    publisher = "tatsy";
    version = "0.2.4";
    hash = "sha256-MXK3uAzCRdC2SXp647YWReKqdyJ9Fymqt+2zWI8LdoA=";
  };

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];

  meta = {
    description = "3D model viewer for Visual Studio Code";
    downloadPage = "https://marketplace.visualstudio.com/items?itemName=tatsy.vscode-3d-preview";
    homepage = "https://github.com/tatsy/vscode-3d-preview";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.your-maintainer-handle ];
    platforms = [ "x86_64-linux" ];
  };
}