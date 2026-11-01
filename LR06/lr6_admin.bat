@echo off
rem LR6, Dziadzin M.V., IPZ-24-2, variant 3 (G=83, N=3)
rem Network administration script for workstation of WG-83-3
title LR6 admin script - Dziadzin M.V.
set MAIN=WS-83-3-03
set MAINIP=193.83.3.4
set AUX=WS-83-3-01
set AUXIP=193.83.3.2
set GW=193.83.3.1
set STUD=C:\Dziadzin_Student
set OKMAIN=0
set OKAUX=0
set OKGW=0
echo ===== 1. Workstation and user info =====
echo User name   : %USERNAME%
echo Computer    : %COMPUTERNAME%
echo Domain/user : %USERDOMAIN%
net config workstation | find "WG-"
ver
ipconfig
pause
echo ===== 2. Connectivity check =====
ping -n 2 -w 500 %MAINIP% >nul
if errorlevel 1 (echo Main server %MAIN% %MAINIP% - NOT available) else (echo Main server %MAIN% %MAINIP% - OK& set OKMAIN=1)
ping -n 2 -w 500 %AUXIP% >nul
if errorlevel 1 (echo Aux server %AUX% %AUXIP% - NOT available) else (echo Aux server %AUX% %AUXIP% - OK& set OKAUX=1)
ping -n 2 -w 500 %GW% >nul
if errorlevel 1 (echo Gateway %GW% - NOT available) else (echo Gateway %GW% - OK& set OKGW=1)
if %OKMAIN%%OKAUX%==00 goto error
echo ===== 3. Static ARP entries =====
if %OKMAIN%==1 for /f "tokens=2" %%m in ('arp -a %MAINIP% ^| find "%MAINIP%"') do arp -s %MAINIP% %%m
if %OKAUX%==1 for /f "tokens=2" %%m in ('arp -a %AUXIP% ^| find "%AUXIP%"') do arp -s %AUXIP% %%m
if %OKGW%==1 for /f "tokens=2" %%m in ('arp -a %GW% ^| find "%GW%"') do arp -s %GW% %%m
arp -a
pause
echo ===== 4. Time synchronization =====
if %OKAUX%==1 set SRV=%AUX%
if %OKMAIN%==1 set SRV=%MAIN%
echo Time server: %SRV%
net time \\%SRV% /set /yes
echo ===== 5. Network resources =====
net use * /delete /yes
if %OKMAIN%==1 net use G: \\%MAIN%\Dziadzin_Full /persistent:no
if %OKMAIN%==1 net use I: \\%MAIN%\Dziadzin_Change /persistent:no
if %OKMAIN%==1 net use K: \\%MAIN%\Dziadzin_Read /persistent:no
if %OKAUX%==1 net use LPT2: \\%AUX%\SharpJX9500 /persistent:no
if %OKMAIN%==0 net use G: \\%AUX%\Users /persistent:no
net use
pause
echo ===== 6. Student folder =====
if not exist %STUD% mkdir %STUD%
rem "Everyone" is localized in non-English Windows (Russian XP: "Vse"),
rem so if it fails, full access is granted to the current user
cacls %STUD% /e /g Everyone:F >nul 2>&1
if errorlevel 1 cacls %STUD% /e /g %USERNAME%:F
net share Dziadzin_Student /delete >nul 2>&1
net share Dziadzin_Student=%STUD% /remark:"Dziadzin M.V. student folder"
xcopy G:\*.txt %STUD%\ /y
dir /b %STUD%
echo ===== 7. Messages =====
msg * /server:%MAIN% /time:30 "LR6 script on %COMPUTERNAME% finished OK"
if errorlevel 1 echo Message to %MAIN% was not delivered
msg * /server:%AUX% /time:30 "LR6 script on %COMPUTERNAME% finished OK"
if errorlevel 1 echo Message to %AUX% was not delivered
echo Done.
goto end
:error
net use * /delete /yes
echo Servers %MAIN% and %AUX% are not available. Script stopped.
:end
