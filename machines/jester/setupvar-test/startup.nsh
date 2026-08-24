@echo -off
echo ==========================================================
echo  CVF Support setup_var diagnostic test
echo  Variable "Setup" (GUID EC87D643-EBA4-4BB5-A1E5-3F3E36B20DA9)
echo  Offset 0x9B9  target value 0x02 (USB Bridge)
echo  EXPECTED to fail with WRITE_PROTECTED on this ThinkPad.
echo ==========================================================
echo.
echo --- Step 1: read current value at 0x9B9 ---
efi\setup\setup_var.efi Setup:0x9B9
echo.
echo --- Step 2: attempt write 0x02 at 0x9B9 ---
efi\setup\setup_var.efi Setup:0x9B9=0x02
echo.
echo --- Step 3: read back value at 0x9B9 ---
efi\setup\setup_var.efi Setup:0x9B9
echo.
echo ==========================================================
echo  Test complete. Note the Step 2 result:
echo    "WRITE_PROTECTED" (or an error) = firmware SPI lock holds.
echo    Step 3 shows 0x02             = write took (unexpected win).
echo  Reboot into your normal entry afterwards.
echo ==========================================================
pause
