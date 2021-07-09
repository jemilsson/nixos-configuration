{ lib, fetchFromGitHub, libgcrypt, libgpgerror, libassuan, gnupg, openssl   }:
#with import <nixpkgs> {};
stdenv.mkDerivation rec {
  name = "scd-pkcs11-0.01";
  src = fetchFromGitHub {
    owner = "sektioneins";
    repo = "scd-pkcs11";
    rev = "5c7df15579832776909958d524a149777ec1c51f";
    sha256 = "10cl46gq4hq5n5avmpvcn9fw3h3mpwasflz4m99gc5cdlx22wwsg";
  };
  doCheck = false;
  buildInputs = [ libgcrypt libgpgerror libassuan ];
  propagatedBuildInputs = [ gnupg openssl ];
  meta = {
    description = "The scd-pkcs#11 module is a PKCS#11 provider interfacing to GnuPG's smart card daemon.";
    longDescription = ''
    The scd-pkcs#11 module is a prototype / proof of concept PKCS#11 provider interfacing to GnuPG's smart card daemon (scdaemon).

    It allows PKCS#11 aware applications such as Firefox or OpenSSH to use smart cards via GnuPG's builtin smart card support. scd-pkcs#11 is an alternative to the OpenSC PKCS#11 module.
    '';
    homepage = https://github.com/sektioneins/scd-pkcs11;
    license = lib.licenses.asl20;
    #maintainers = [  ];
    platforms = lib.platforms.all;
  };
}
