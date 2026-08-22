# Decisions

Settled rulings so compaction summaries carry a pointer, not prose.

## jester: IR camera / Windows Hello unreachable in software (2026-08-22)

The OV9234 IR sensor (Windows Hello) cannot stream under Linux on this unit, and
the block is firmware, not driver. Full investigation record lives on branch
`fix/ljca-enum` at `machines/jester/ivsc-stack/DIAGNOSIS.md` (kept unmerged: it
also deletes `presence-lock.nix` and disables `autoUpgrade`, both test-only).

Root cause (proven by ifrextractor-rs on Lenovo N3XET67W v1.42 SPI capsule): the
IVSC master enable "CVF Support" (UEFI Setup var, GUID
EC87D643-EBA4-4BB5-A1E5-3F3E36B20DA9, QuestionId 0x539, VarOffset 0x9B9) has a
default contradiction. The USB Bridge option (value 2) carries inline
Default+MfgDefault flags, but an explicit EFI_IFR_DEFAULT opcode overrides
DefaultId 0x0 to 0. So the STANDARD default (what F9 "Load Setup Defaults"
applies) is Disabled(0); only the MANUFACTURING default is USB Bridge(2).
jester's live value 0x00 IS the standard default. F9 does NOT enable the camera.
Units ship working because Lenovo applies manufacturing defaults on the line; a
later Setup-defaults re-init (BIOS update / CMOS event) flips CVF Support to
Disabled, and the question is not in Lenovo's visible F1 menu. The Setup var is
SMM-write-protected from the OS (EROFS).

Remedies (both hardware, neither a BIOS-menu action):
- External SPI-flash programmer (CH341A) writing Setup:0x9B9 = 0x02.
- USB IR camera + Howdy, sidestepping the built-in sensor.

RGB camera (OV2740) works and is unaffected.
