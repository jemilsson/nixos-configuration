# Out-of-tree OmniVision OV9234 IR sensor module (port of mainline ov9734).
{ lib, stdenv, kernel }:

stdenv.mkDerivation {
  pname = "ov9234";
  version = "0.1-${kernel.version}";

  src = ./.;

  hardeningDisable = [ "pic" ];
  nativeBuildInputs = kernel.moduleBuildDependencies;

  buildPhase = ''
    runHook preBuild
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
      M=$PWD modules
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm444 ov9234.ko \
      $out/lib/modules/${kernel.modDirVersion}/extra/ov9234.ko
    runHook postInstall
  '';

  meta = {
    description = "OmniVision OV9234 mono/IR camera sensor driver";
    license = lib.licenses.gpl2Only;
    platforms = [ "x86_64-linux" ];
  };
}
