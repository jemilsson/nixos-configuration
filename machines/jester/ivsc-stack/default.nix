# Out-of-tree helper that registers the Intel VSC (IVSC) SPI device on the
# LJCA virtual SPI controller. See vsc-spi-bind.c for the full rationale:
# the in-kernel IVSC stack (vsc-tp / platform-vsc / ivsc-ace / ivsc-csi) is
# complete on 7.x, but nothing creates the spi_device for \_SB.PC00.SPI1.SPFD
# (INTC1009), so none of it ever probes and the OV9234 never gets the CSI-2
# lanes handed over.
#
# Installed into updates/ rather than extra/ so depmod resolves our module
# ahead of anything with the same name; it does not shadow an in-tree module,
# the name is unique.
{ lib, stdenv, kernel }:

stdenv.mkDerivation {
  pname = "vsc-spi-bind";
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
    install -Dm444 vsc-spi-bind.ko \
      $out/lib/modules/${kernel.modDirVersion}/updates/vsc-spi-bind.ko
    runHook postInstall
  '';

  meta = {
    description = "Register the Intel VSC SPI device on the LJCA SPI bus";
    license = lib.licenses.gpl2Only;
    platforms = [ "x86_64-linux" ];
  };
}
