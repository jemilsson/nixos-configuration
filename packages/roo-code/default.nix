{ pkgs, stdenv, lib, autoPatchelfHook }:

pkgs.vscode-utils.buildVscodeMarketplaceExtension {
  mktplcRef =
    let
      sources = {
        "x86_64-linux" = {
          #arch = "linux-x64";
          hash = "sha256-t3QUqe0qYizrJQcsEmYYmNYS/cpYiHQXJHtzHk9MGS8="; # Replace with actual hash
        };
      };
    in
    {
      name = "roo-cline";
      publisher = "RooVeterinaryInc";
      version = "3.8.6";
    }
    // sources.${stdenv.system};
  
  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];

  meta = {
    description = ''
      AI-powered autonomous coding agent with natural language communication,
      workspace file access, terminal integration, browser automation,
      and customizable API/model integration. Adapts through Custom Modes
      to serve various roles from coding partner to system architect.
    '';
    downloadPage = "https://marketplace.visualstudio.com/items?itemName=RooVeterinaryInc.roo-cline";
    homepage = "https://github.com/RooVeterinaryInc/roo-code"; # Update if actual homepage exists
    license = lib.licenses.asl20; # Verify actual license from extension documentation
    maintainers = [ lib.maintainers.your-maintainer-handle ]; # Replace with actual maintainer
    platforms = [ "x86_64-linux" ];
  };
}