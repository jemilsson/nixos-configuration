# CVF Support setup_var boot-menu test (RU.efi-class path).
#
# Runs setup_var.efi from jester's own ESP via a systemd-boot entry, so no USB
# is needed. setup_var.efi writes the UEFI Setup variable at offset 0x9B9 = 0x02
# (CVF Support -> USB Bridge) in the pre-boot DXE context. This is the same
# trust context that already returned WRITE_PROTECTED from efivars, so the write
# is EXPECTED to fail; the test confirms the SPI flash lock is hardware-enforced
# before considering an external programmer. See ivsc-stack/DIAGNOSIS.md.
#
# Usage: rebuild + reboot, pick "CVF Support write test (setup_var)" in the
# systemd-boot menu. The chainloaded UEFI shell auto-runs \startup.nsh (read,
# write, read-back, pause). Remove this import once the test is done.
{ ... }:
{
  boot.loader.systemd-boot.extraFiles = {
    "efi/setup/shell.efi" = ./setupvar-test/shell.efi;
    "efi/setup/setup_var.efi" = ./setupvar-test/setup_var.efi;
    # ESP-root startup.nsh: the edk2 shell auto-runs it on launch.
    "startup.nsh" = ./setupvar-test/startup.nsh;
  };

  boot.loader.systemd-boot.extraEntries = {
    "cvf-setupvar.conf" = ''
      title CVF Support write test (setup_var)
      efi /efi/setup/shell.efi
    '';
  };
}
