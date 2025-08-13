{ pkgs, lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "tmuxai";
  version = "1.1.0";

  src = fetchurl {
    url = "https://github.com/alvinunreal/tmuxai/releases/download/v${version}/tmuxai_Linux_amd64.tar.gz";
    sha256 = "583c66e9e47214545b8326c50058f9f371b03f6cfedd8012699395f7e20b4556";
  };

  nativeBuildInputs = with pkgs; [
    gnutar
    gzip
  ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/bin
    cp tmuxai $out/bin/
    chmod +x $out/bin/tmuxai
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "AI-Powered, Non-Intrusive Terminal Assistant for tmux";
    homepage = "https://github.com/alvinunreal/tmuxai";
    license = licenses.asl20;
    maintainers = [ ];
    platforms = platforms.linux;
    mainProgram = "tmuxai";
  };
}