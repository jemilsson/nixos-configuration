{ stdenv, fetchFromGitHub, libgcrypt, libgpgerror, libassuan, gnupg, openssl   }:
#with import <nixpkgs> {};
stdenv.mkDerivation rec {
  name = "scd-pkcs11-0.01";
  src = fetchFromGitHub {
    owner = "sektioneins";
    repo = "scd-pkcs11";
    rev = "6356e8e90e6c4c7078c448380d79bc1623183c6b";
    sha256 = "1hz2x29qhm9ryajrxssigqlrh6g77vi8ncmasvcqbabfkc2njwwx";
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
    license = stdenv.lib.licenses.asl20;
    #maintainers = [  ];
    platforms = stdenv.lib.platforms.all;
  };
}
