# Enabling the IR camera via external SPI programmer (jester)

The only working way to enable the built-in IR / Windows-Hello camera on this
unit. It sets the one firmware byte (CVF Support) that every software path is
blocked from writing (SMM_BWP=1, verified). Physical access to the flash chip
bypasses that lock. See DECISIONS.md for why nothing else works.

Goal: change the UEFI `Setup` variable byte at variable-offset `0x9B9` from
`0x00` (Disabled) to `0x02` (USB Bridge). This clears the firmware gate: on next
boot the firmware runs the IVSC init and `INTC1009._CRS` routes the IVSC
transport to the live LJCA USB-SPI bridge (`spi0`), which `vsc-tp` can bind.

Value MUST be `0x02` (USB Bridge), NOT `0x01` (Native IOs): native SPI1
(`00:1e.3`) is function-disabled in firmware on this unit (`_STA=0x08`, absent
from PCI config space), so `Native IOs` routes the IVSC to a controller that does
not exist and the camera stays dark. Only `USB Bridge` reaches a working bus.

## What the byte flip does and does NOT guarantee (read before reflashing)
The flip is NECESSARY but is NOT proven sufficient on its own. Two caveats, both
from live testing on branch `fix/ljca-enum` (`machines/jester/ivsc-stack/DIAGNOSIS.md`):

1. The stock in-kernel `vsc-tp` has two real bugs on this platform's CVFS=2
   routing that block `vsc_tp_probe()`: it requests `IRQF_TRIGGER_FALLING` on a
   PADCFG-locked wake pad (`-EINVAL`), and the `CVFS==2` `_CRS` branch omits the
   `wakeupfw` GPIO resource the driver expects (`-EINVAL`). Both are fixed by the
   out-of-tree `mei_vsc_hw_patched` module in `ivsc-stack/vsc-tp-patched/` on
   that branch. Import it (or upstream the two fixes) alongside the reflash; do
   not expect the unpatched stock stack to stream.

2. A possible hardware wall: with fixes 1+2 applied, the wake IRQ pad (GPI0
   pin 23) read as hardware-locked output-only (`PADCFG0=0x44000200`,
   `GPIORXDIS=1`), which cannot serve as an interrupt source. BUT this was
   observed under a RUNTIME GNVS poke (`CVFS=2` written after boot), which does
   NOT run the firmware's IVSC init. A real reflash latches CVF Support=2 before
   boot, so the firmware IVSC bring-up configures the pad itself and may leave
   pin 23 in a usable state. Whether the wall clears on a genuine cold boot is
   UNTESTED. Treat a streaming camera as the goal to verify (step 5), not a
   guaranteed outcome. If pin 23 is still output-only after the reflash, the
   residual fix is an SSDT override of the pad config, a separate task.

## Risk / recoverability (read first)
- Brick risk is real but recoverable IF you keep a verified original dump.
- This model has ONE forum report of BIOS "self-heal" reverting a clip reflash.
  Mitigation: keep the untouched dump; if it self-heals, reflash the patched
  image again, or if it bricks, reflash the original. Do not proceed without a
  verified backup on two devices.
- You are writing the whole BIOS flash. A wrong chip ID, wrong voltage, or bad
  clip contact can corrupt it. Go slow, verify every step.

## Hardware (~$10)
- CH341A USB programmer. IMPORTANT: many CH341A boards drive the SPI at 5V,
  which can damage a 3.3V flash chip. Use a 3.3V-modified CH341A, or a 1.8/3.3V
  adapter. Confirm 3.3V on the clip before attaching.
- SOIC-8 test clip (pomona-style) matching the flash package, + jumper wires.
- The BIOS flash chip: reportedly a Winbond W25Q128 (SOIC-8, 16MB) on the X1C
  Gen 11 board (single unverified forum source — confirm the silkscreen marking
  before ordering the clip). Reading the chip will report its real JEDEC ID.

## Access
- Lenovo self-repair guide SR500060 (21HM/21HN): remove the bottom cover to
  reach the mainboard. Disconnect the internal battery before clipping the chip.
- Locate the SPI flash (SOIC-8 near the PCH). Clip it in-circuit; if reads are
  unstable, the chip may need to be powered alone (hold the board off / the EC
  in reset) or desoldered — try in-circuit first.

## Tooling (Nix)
    nix-shell -p flashrom uefitool ifrextractor-rs

## Procedure
1. Read TWICE and verify identical (never trust a single read):
       flashrom -p ch341a_spi -r dump1.rom
       flashrom -p ch341a_spi -r dump2.rom
       cmp dump1.rom dump2.rom      # must be identical
   Copy dump1.rom to two separate devices as the untouched backup.

2. Locate the `Setup` variable in the dump and compute the absolute offset:
   - Open dump1.rom in UEFITool (NE). Find the NVRAM store, then the variable
     named `Setup` with GUID `EC87D643-EBA4-4BB5-A1E5-3F3E36B20DA9`.
   - Note the file offset of the variable's DATA (body) start.
   - Absolute patch offset = <Setup data start> + 0x9B9.
   - Cross-check: at that offset the byte should currently read 0x00. Confirm
     with IFRExtractor that QuestionId 0x539 (CVF Support) maps to VarOffset
     0x9B9, options Disabled=0 / Native IOs=1 / USB Bridge=2.
     (If there are multiple `Setup` variable instances, pick the one whose GUID
     matches AND whose 0x9B9 byte is 0x00; there was only one on this unit.)

3. Patch that single byte 0x00 -> 0x02 (copy first, edit the copy):
       cp dump1.rom patched.rom
       printf '\x02' | dd of=patched.rom bs=1 seek=<ABSOLUTE_OFFSET> \
         count=1 conv=notrunc
       cmp -l dump1.rom patched.rom   # must show exactly ONE differing byte

4. Write and verify:
       flashrom -p ch341a_spi -w patched.rom
   flashrom verifies after write by default. If it reports region/verify issues,
   STOP and reflash dump1.rom.

   Caveat (do NOT do this first): patching the IFR DefaultId 0x0 for QuestionId
   0x539 inside a DXE module is often floated as "more robust vs a load-defaults
   revert", but it means editing code inside a firmware volume, which can trip
   Boot Guard / FV signature verification and brick the unit, unlike the plain
   NVRAM data-byte edit. It also has no worked-out offsets or tooling here. Do
   the NVRAM byte only. If a later load-defaults reverts it, re-flash the NVRAM
   byte again; only consider the IFR route as a last resort with a verified
   FV-hash/Boot-Guard analysis first.

5. Reassemble, boot, and verify end to end (on jester). Success is a captured
   IR frame, NOT just modules binding:
       # a) byte latched:
       sudo dd if=/sys/firmware/efi/efivars/Setup-ec87d643-eba4-4bb5-a1e5-3f3e36b20da9 \
         bs=1 skip=$((4 + 0x9B9)) count=1 2>/dev/null | od -An -tx1   # expect 02
       # b) transport enumerates on the LJCA bus (spi0), not native 00:1e.3:
       ls -l /sys/bus/spi/devices/spi-INTC1009:00/driver   # -> vsc-tp
       # c) probe got past the pin-23 wall (no gpiochip_lock_as_irq error):
       dmesg | grep -iE 'vsc_tp|gpiochip_lock_as_irq|ivsc'
       # d) ACTUAL stream (the real success test):
       v4l2-ctl -d /dev/video8 --stream-mmap --stream-count=1   # or libcamera capture
   If (b) binds but (c) shows the pin-23 output-only error and (d) fails, the
   reflash cleared the firmware gate but the pad wall remains -> SSDT override
   task. Import ivsc-stack/vsc-tp-patched (fixes 1+2) before concluding.

## If it self-heals or reverts
Re-read the flash; if 0x9B9 went back to 0x00, the firmware reverted it. Try the
IFR-default patch (step 4 alternative). If it bricks (no boot), reflash dump1.rom
with the programmer; Lenovo's Fn+R crisis recovery is a secondary fallback but
unconfirmed for this model.
