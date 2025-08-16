{ lib, stdenv, fetchurl, nodejs, makeWrapper }:

stdenv.mkDerivation rec {
  pname = "claude-code-router";
  version = "1.0.39";

  src = fetchurl {
    url = "https://registry.npmjs.org/@musistudio/claude-code-router/-/claude-code-router-${version}.tgz";
    sha256 = "sha256-lkdbW419RsXgL1gGsib+3DrLH1kyOd6LcUUOmNgiqOA=";
  };

  nativeBuildInputs = [ nodejs makeWrapper ];

  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    mkdir -p $out/lib/node_modules/@musistudio/claude-code-router
    cp -r . $out/lib/node_modules/@musistudio/claude-code-router/
    
    # Create wrapper scripts
    mkdir -p $out/bin
    cat > $out/bin/claude-code-router << EOF
#!/usr/bin/env bash
exec ${nodejs}/bin/node $out/lib/node_modules/@musistudio/claude-code-router/dist/cli.js "\$@"
EOF
    chmod +x $out/bin/claude-code-router
    
    # Create ccr symlink
    ln -s $out/bin/claude-code-router $out/bin/ccr
  '';

  meta = with lib; {
    description = "Router for Claude Code with multiple AI providers";
    homepage = "https://github.com/musistudio/claude-code-router";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.all;
  };
}