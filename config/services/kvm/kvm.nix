{ config, ... }:
{

boot = {
  kernelModules = [ "kvm-intel" "kvm-amd" "acpi_call" ];
  binfmt.emulatedSystems = [ "aarch64-linux" ];
};
virtualisation = {
 kvmgt = {
   enable = true;
 };
 libvirtd = {
   enable = true;
 };
};

}
