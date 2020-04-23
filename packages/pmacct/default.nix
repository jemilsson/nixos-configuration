{ stdenv, fetchFromGitHub, pkgconfig, autoreconfHook, libtool, libpcap, zlib, jansson, libnetfilter_log, sqlite, postgresql}
#with import <nixpkgs> {};
let
  inherit (stdenv.lib) optional;
in
stdenv.mkDerivation rec {
  version = "1.7.4p1";
  pname = "pmacct";

  src = fetchFromGitHub {
    owner = "pmacct";
    repo = pname;
    rev = "${version}";
    sha256 = "1riqa863wxa64j9jpy16grl5wihz11fi7kin8d3ygjd0w2afbc03";
  };

  nativeBuildInputs = [ autoreconfHook pkgconfig libtool ];
  buildInputs = [ libpcap
    jansson
    libnetfilter_log
    sqlite
    postgresql
    #libmysqlclient
    zlib
    ];

  configureFlags = [
    "--with-pcap-includes=${libpcap}/include"
    "--enable-jansson"
    "--enable-nflog"
    "--enable-sqlite3"
    "--enable-pgsql"
    #"--enable-mysql"
    ];

  meta = with stdenv.lib; {
    description = "pmacct is a small set of multi-purpose passive network monitoring tools";
    longDescription = ''
      pmacct is a small set of multi-purpose passive network monitoring tools
      [NetFlow IPFIX sFlow libpcap BGP BMP RPKI IGP Streaming Telemetry]
    '';
    homepage = "http://www.pmacct.net/";
    license = licenses.gpl2;
    maintainers = [ maintainers."0x4A6F" ];
    platforms = platforms.unix;
  };
}
