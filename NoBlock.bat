@echo off
title NoBlock for Windows by AnthonyT
color a
rem Check for admin rights, if insufficient rights request with a UAC popup
IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
>nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)
if '%errorlevel%' NEQ '0' (
echo Requesting administrative privileges...
goto UACPrompt
) else ( goto AdminOK )
:UACPrompt
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
set params= %*
echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params:"=""%", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs"
del "%temp%\getadmin.vbs"
exit /B
:AdminOK
echo NoBlock for windows! Unblock network restrictions by AnthonyT
timeout 3
echo Changing DNS to cloudflare for all connected network adapters...
rem Changing DNS to cloudflare for every connected network adapter
for /F "skip=3 tokens=1,2,3* delims= " %%G in ('netsh interface show interface') DO (
    if "%%H"=="Connected" netsh interface ipv4 set dns name="%%J" static 1.1.1.1 > nul
)
if %errorlevel% == 1 (goto FAILDNS)
for /F "skip=3 tokens=1,2,3* delims= " %%G in ('netsh interface show interface') DO (
    if "%%H"=="Connected" netsh interface ipv4 add dns name="%%J" 1.0.0.1 index=2 > nul
)
if %errorlevel% == 1 (goto FAILDNS)
echo DNS changed successfully!
rem Flushing cache, and getting new IP
echo Flushing DNS cache...
ipconfig /flushdns > nul
echo DNS cache flushed!
echo Releasing IP...
ipconfig /release > nul
echo IP released!
echo Waiting 5 seconds to renew
timeout 5
echo Renewing IP... (may take a few seconds)
ipconfig /renew > nul
echo Testing block...
rem Test a blocked site
ping -n 2 pornhub.com | find /I "Lost = 0" > nul
if %errorlevel% == 0 (goto OK) else (goto FAIL)
:OK
echo Unblock successful! You may enjoy the internet now with no restrictions. 
echo If blocked sites still do not work, try restarting your computer.
pause
exit
:FAIL
echo Unblock failed
pause
exit
:FAILDNS
echo DNS change failed
pause
exit