{ config, lib, pkgs, ... }:
let
  dpi = 144;
in
{
  imports = [
    ../../config/laptop_base.nix
    ../../config/i3_x11.nix
    ../../config/language/english.nix
  ];

  networking.hostName = "jester";
  system.stateVersion = "19.03";

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };


  boot.kernelPackages = pkgs.unstable.linuxPackages_latest;

 services = {
   xserver = {
     videoDrivers = [ "intel" "modesetting" ];
     dpi = dpi;

     /*
     displayManager.sessionCommands = ''
      ${pkgs.xorg.xrdb}/bin/xrdb -merge <<EOF
        Xft.dpi: ${toString dpi}
       EOF
      '';
    */
   };
   undervolt = {
     enable = false;
   };

   fprintd = {
     enable = true;
     package = pkgs.unstable.fprintd-thinkpad;
   };
 };

 environment.systemPackages = with pkgs; [

 ];

 nix = {
   extraOptions = ''
   extra-platforms = aarch64-linux arm-linux
   '';
 };
 boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

 virtualisation.libvirtd = {
   enable = true;
 };

 boot.kernelPatches = [ {
        name = "sof-sound";
        patch = null;
        extraConfig = ''
        # CONFIG_SND_SOC_SOF_ACPI is not set
        CONFIG_SND_SOC_SOF=m
        CONFIG_SND_SOC_SOF_PROBE_WORK_QUEUE=y
        CONFIG_SND_SOC_SOF_INTEL_TOPLEVEL=y
        CONFIG_SND_SOC_SOF_INTEL_PCI=m
        CONFIG_SND_SOC_SOF_INTEL_COMMON=m
        # CONFIG_SND_SOC_SOF_MERRIFIELD_SUPPORT is not set
        # CONFIG_SND_SOC_SOF_APOLLOLAKE_SUPPORT is not set
        # CONFIG_SND_SOC_SOF_GEMINILAKE_SUPPORT is not set
        CONFIG_SND_SOC_SOF_CANNONLAKE_SUPPORT=y
        CONFIG_SND_SOC_SOF_CANNONLAKE=m
        # CONFIG_SND_SOC_SOF_COFFEELAKE_SUPPORT is not set
        # CONFIG_SND_SOC_SOF_ICELAKE_SUPPORT is not set
        # CONFIG_SND_SOC_SOF_COMETLAKE_LP_SUPPORT is not set
        # CONFIG_SND_SOC_SOF_COMETLAKE_H_SUPPORT is not set
        # CONFIG_SND_SOC_SOF_TIGERLAKE_SUPPORT is not set
        # CONFIG_SND_SOC_SOF_ELKHARTLAKE_SUPPORT is not set
        # CONFIG_SND_SOC_SOF_JASPERLAKE_SUPPORT is not set
        CONFIG_SND_SOC_SOF_HDA_COMMON=m
        CONFIG_SND_SOC_SOF_HDA_LINK=y
        CONFIG_SND_SOC_SOF_HDA_AUDIO_CODEC=y
        # CONFIG_SND_SOC_SOF_HDA_ALWAYS_ENABLE_DMI_L1 is not set
        CONFIG_SND_SOC_SOF_HDA_COMMON_HDMI_CODEC=y
        CONFIG_SND_SOC_SOF_HDA_LINK_BASELINE=m
        CONFIG_SND_SOC_SOF_HDA=m
        CONFIG_SND_SOC_SOF_XTENSA=m
              '';
        } ];

}
