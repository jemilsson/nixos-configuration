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
        SND_SOC_SOF = m
        SND_SOC_SOF_PROBE_WORK_QUEUE = y
        SND_SOC_SOF_INTEL_TOPLEVEL = y
        SND_SOC_SOF_INTEL_PCI = m
        SND_SOC_SOF_INTEL_COMMON = m
        SND_SOC_SOF_CANNONLAKE_SUPPORT = y
        SND_SOC_SOF_CANNONLAKE = m
        SND_SOC_SOF_HDA_COMMON = m
        SND_SOC_SOF_HDA_LINK = y
        SND_SOC_SOF_HDA_AUDIO_CODEC = y
        SND_SOC_SOF_HDA_COMMON_HDMI_CODEC = y
        SND_SOC_SOF_HDA_LINK_BASELINE = m
        SND_SOC_SOF_HDA = m
        SND_SOC_SOF_XTENSA = m
              '';
        } ];

}
