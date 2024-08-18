@echo off
setlocal

:: Prompt user to choose between installation and recovery environment
:option
echo Choose an option:
echo [1] Install Windows
echo [2] Launch Recovery Environment
set /p choice=Enter your choice (1 or 2): 
goto choice

:choice
if "%choice%"=="1" goto install_windows
if "%choice%"=="2" goto launch_recovery

echo Invalid choice. 
goto option

:warning
:: Warning about data destruction
echo WARNING: All files on the main disk will be destroyed to install Windows!
set /p confirm=Are you sure you want to continue? (Y/N): 
if /i not "%confirm%"=="Y" (
    echo Operation canceled. No changes were made.
    goto option
)

:install_windows
echo Starting Windows 11 installation...
goto start_installation

:launch_recovery
echo Launching Recovery Environment...
X:\sources\recovery\recenv.exe
pause

:start_installation
:: Variables

set mainDriveLetter=C
set systemDriveLetter=W
set installDriveLetter=D
set wimFilePath=%installDriveLetter%:\sources\install.wim
set esdFilePath=%installDriveLetter%:\sources\install.esd

:: Use Diskpart to partition and format the disk
echo Partitioning and formatting your disk
diskpart /s .\script.dsp

:: Check if install.wim or install.esd exists and set the image file path
if exist %wimFilePath% (
    set imageFile=%wimFilePath%
) else if exist %esdFilePath% (
    set imageFile=%esdFilePath%
) else (
    echo Error: Neither install.wim nor install.esd found in %installDriveLetter%:\sources
    pause
    exit /b 1
)

:: Extract system files using DISM
echo Loading and extracting files
dism /apply-image /imagefile:%imageFile% /index:1 /applydir:%mainDriveLetter%:\

:: Set registry values
echo Configuring registry
reg load HKLM\TempHive %mainDriveLetter%:\Windows\System32\Config\Software
reg add "HKLM\TempHive\Microsoft\Windows\CurrentVersion\Policies\System" /v verbosestatus /t REG_DWORD /d 1 /f
reg add "HKLM\TempHive\Software\Microsoft\Windows\DWM" /v forceeffectmode /t REG_DWORD /d 2 /f
reg unload HKLM\TempHive

:: Write boot files to the system partition
echo Creating bootable files
bcdboot %mainDriveLetter%:\Windows /s %systemDriveLetter%: /f UEFI

:: Pause and reboot
pause
wpeutil reboot

endlocal
