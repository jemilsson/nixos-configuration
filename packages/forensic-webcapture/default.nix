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
, playwright-driver
}:

let
  pythonEnv = python3.withPackages (ps: with ps; [
    requests
    fake-useragent
    certifi
    cryptography
    beautifulsoup4
    dnspython
    playwright
  ]);
in
stdenv.mkDerivation rec {
  pname = "forensic-webcapture";
  version = "4.0.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [ pythonEnv ];

  installPhase = ''
    mkdir -p $out/bin $out/lib
    
    # Install the modular forensic_webcapture package
    cp -r forensic_webcapture $out/lib/
    
    # Install CLI wrapper script
    cp forensic-webcapture-cli.py $out/bin/forensic-webcapture
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
      --prefix PYTHONPATH : "$out/lib" \
      --prefix PYTHONPATH : "${pythonEnv}/${python3.sitePackages}" \
      --set PLAYWRIGHT_BROWSERS_PATH "${playwright-driver.browsers}" \
      --set PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD "1"
  '';

  meta = with lib; {
    description = "Forensic web capture tool with TLS certificates and browser spoofing";
    longDescription = ''
      Python-based forensic web capture tool for court-admissible evidence collection.
      
      FEATURES:
      - Advanced browser spoofing with multiple profiles (Chrome, Firefox, Safari, Googlebot)
      - Recursive crawling of same-domain links with configurable depth
      - Captures complete TLS/SSL certificate chain from HTTPS servers
      - Certificate fingerprints (SHA256/SHA1) for verification
      - Certificate validity and OCSP checking
      - DNS resolution documentation
      - Complete page capture with assets (preserves original compression)
      - Dual hashing (SHA256 + SHA512) for integrity
      - Comprehensive chain of custody documentation
      - Realistic browser headers to bypass anti-bot measures
      - Sandboxed browsing with domain spoofing (no internet access)
      - Complete isolation for forensic integrity
      
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
        forensic-webcapture capture --crawl <URL>            - Crawl same-domain links (depth 2)
        forensic-webcapture capture --crawl --depth 3 <URL>  - Crawl with custom depth
        forensic-webcapture capture --crawl --max-pages 100 <URL> - Crawl max 100 pages
        forensic-webcapture verify <dir>                     - Verify capture integrity
        forensic-webcapture report <dir>                     - Display forensic report
        forensic-webcapture browse <dir>                     - Browse with domain spoofing & sandboxing
      
      Designed for legal proceedings requiring cryptographic proof of web content origin.
    '';
    license = licenses.gpl3;
    maintainers = [ ];
    mainProgram = "forensic-webcapture";
  };
}