{ config, ... }:
{

boot = {
  kernelModules = [ "kvm-intel" "kvm-amd" "acpi_call" ];
  binfmt.emulatedSystems = [ "aarch64-linux" ];
};
virtualisation = {
 kvmgt = {
   enable = false;  # GVT-g is incompatible with xe driver, causes freeze on s2idle resume
 };
 libvirtd = {
   enable = true;
 };
};

}
