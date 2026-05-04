{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # Core runtime
    nodejs
    nodePackages.npm

    # LSP servers (Node.js-based)
    typescript-language-server
    pyright
    prisma-language-server
    dockerfile-language-server-nodejs
    intelephense                           # PHP LSP (unfree)
    bash-language-server
    yaml-language-server
    svelte-language-server
    vue-language-server
    nodePackages.vscode-langservers-extracted  # JSON/HTML/CSS/ESLint LSPs

    # LSP servers (native)
    rust-analyzer
    golangci-lint
    gopls
    ruby-lsp
    taplo
    terraform-ls
    tflint

    # Linters / formatters
    shellcheck
    shfmt
    biome
    ruff
    markdownlint-cli2
    htmlhint
    stylelint
    hadolint
    ktlint
    mypy
    ast-grep

    # knip, jscpd, madge are not in nixpkgs; install via npm in user env
  ];
}
