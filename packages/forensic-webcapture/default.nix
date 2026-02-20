{ lib
, stdenv
, python3
, makeWrapper
, coreutils
, openssl
, dnsutils
, traceroute
, chromium
, util-linux
}:

let
  pythonEnv = python3.withPackages (ps: with ps; [
    requests
    fake-useragent
    certifi
    cryptography
    beautifulsoup4
    dnspython
  ]);
in
stdenv.mkDerivation rec {
  pname = "forensic-webcapture";
  version = "4.0.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [ pythonEnv ];

  installPhase = ''
    mkdir -p $out/bin
    
    # Install Python forensic capture tool with integrated browsing
    cp ${./forensic-capture.py} $out/bin/forensic-webcapture
    chmod +x $out/bin/forensic-webcapture

    wrapProgram $out/bin/forensic-webcapture \
      --prefix PATH : ${lib.makeBinPath [
        coreutils
        openssl
        dnsutils
        traceroute
        chromium
        util-linux
      ]} \
      --set PYTHONPATH "${pythonEnv}/${python3.sitePackages}"
  '';

  meta = with lib; {
    description = "Forensic web capture tool with TLS certificates and browser spoofing";
    longDescription = ''
      Python-based forensic web capture tool for court-admissible evidence collection.
      
      FEATURES:
      - Advanced browser spoofing with multiple profiles (Chrome, Firefox, Safari, Googlebot)
      - Captures complete TLS/SSL certificate chain from HTTPS servers
      - Certificate fingerprints (SHA256/SHA1) for verification
      - Certificate validity and OCSP checking
      - DNS resolution documentation
      - Complete page capture with assets (preserves original compression)
      - Dual hashing (SHA256 + SHA512) for integrity
      - Comprehensive chain of custody documentation
      - Realistic browser headers to bypass anti-bot measures
      - Local web server for browsing captured sites
      
      The TLS certificate provides cryptographic proof that:
      - Content originated from the legitimate server
      - Server was authorized by a Certificate Authority
      - Connection was encrypted and authenticated
      - No man-in-the-middle attack occurred
      
      Usage:
        forensic-webcapture capture <URL>                    - Capture with Chrome profile
        forensic-webcapture capture -b firefox <URL>         - Use Firefox profile  
        forensic-webcapture capture -b googlebot <URL>       - Use Googlebot profile
        forensic-webcapture capture -b random <URL>          - Random user agent
        forensic-webcapture verify <dir>                     - Verify capture integrity
        forensic-webcapture report <dir>                     - Display forensic report
        forensic-webcapture browse <dir>                     - Browse capture locally
        forensic-webcapture browse --spoof-domain <dir>      - Browse with domain spoofing
      
      Designed for legal proceedings requiring cryptographic proof of web content origin.
    '';
    license = licenses.gpl3;
    maintainers = [ ];
    mainProgram = "forensic-webcapture";
  };
}