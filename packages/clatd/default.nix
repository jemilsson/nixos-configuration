{ lib, stdenv, fetchurl, pkg-config, libdaemon, bison, flex, check, libbsd, autoreconfHook, fetchFromGitHub, perl, perlPackages, tayga, systemd, autoPatchelfHook }:
stdenv.mkDerivation rec {
  pname = "clatd";
  version = "v1.6";

  src = fetchFromGitHub {
    owner = "toreanderson";
    repo = "${pname}";
    rev = "${version}";
    hash = "sha256-ZUGWQTXXgATy539NQxkZSvQA7HIWkIPsw1NJrz0xKEg=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];
  buildInputs = [
    perl
    perlPackages.NetIP
    perlPackages.IOSocketInet6
    perlPackages.NetDNS
    tayga
    systemd
  ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;


  installPhase = ''
  install -Dm755 clatd "$out/bin/clatd"
  install -Dm755 scripts/clatd.networkmanager "$out/etc/NetworkManager/dispatcher.d/50-clatd"
  install -Dm644 scripts/clatd.systemd "$out/usr/lib/systemd/system/clatd.service"
  '';

  # Needed for cross-compilation

  meta = with lib; {
    homepage = "http://www.litech.org/radvd/";
    description = "IPv6 Router Advertisement Daemon";
    platforms = platforms.linux;
    license = licenses.bsdOriginal;
    maintainers = with maintainers; [ fpletz ];
  };
}
