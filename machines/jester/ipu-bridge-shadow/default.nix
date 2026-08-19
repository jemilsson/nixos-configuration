# In-tree ipu-bridge rebuilt out-of-tree with the OVTI9234 sensor-table
# entry, installed to updates/ so depmod prefers it over the unpatched
# kernel/ copy. Avoids a full kernel rebuild for a 2-line table change
# (the remote builder's ephemeral VMs cannot fit kernel builds).
# Fragility ceiling: if depmod priority ever breaks, the symptom is the
# IR sensor silently missing from the media graph; check
# `modinfo -n ipu_bridge` points at updates/. Upgrade path: upstream the
# entry, then delete this package.
{ lib, stdenv, kernel }:

stdenv.mkDerivation {
  pname = "ipu-bridge-ov9234";
  version = kernel.version;

  src = kernel.src;

  patches = [ ../ipu-bridge-ov9234.patch ];

  hardeningDisable = [ "pic" ];
  nativeBuildInputs = kernel.moduleBuildDependencies;

  buildPhase = ''
    runHook preBuild
    cd drivers/media/pci/intel
    echo 'obj-m := ipu-bridge.o' > Makefile
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
      M=$PWD modules
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm444 ipu-bridge.ko \
      $out/lib/modules/${kernel.modDirVersion}/updates/ipu-bridge.ko
    runHook postInstall
  '';

  meta = {
    description = "ipu-bridge with OVTI9234 sensor entry (shadows in-tree module)";
    license = lib.licenses.gpl2Only;
    platforms = [ "x86_64-linux" ];
  };
}
