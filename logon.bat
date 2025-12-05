@echo off
if not "%1"=="" goto %1
if not "%OS%"=="Windows_NT" set LOGONSERVER=\\files
if not exist %LOGONSERVER%\netlogon\run_hidden.vbs goto start
wscript %LOGONSERVER%\netlogon\run_hidden.vbs "%0" start
goto realend

:start
cls
echo                        --------------------------
echo                        * Globales Anmeldeskript *
echo                        --------------------------
echo.
C:
set HOMESHARE=%USERNAME%
if not "%OS%"=="Windows_NT" set HOMESHARE=homes

REM Falls custom_logon.bat existiert, fuehre dieses aus und beende Skript
if not exist %LOGONSERVER%\netlogon\custom_logon.bat goto skip_custom_logon
call %LOGONSERVER%\netlogon\custom_logon.bat
goto end
:skip_custom_logon
REM This has to start early
if exist %LOGONSERVER%\pgm\Anmeldung\Authentication\run.bat call %LOGONSERVER%\pgm\Anmeldung\Authentication\run.bat

REM Load settings
if exist %LOGONSERVER%\netlogon\settings.bat call %LOGONSERVER%\netlogon\settings.bat

ver | %windir%\system32\find "Version 5" >NUL
if errorlevel 1 goto skip_desktop_ini
del /s /a "%USERPROFILE%\desktop.ini" >NUL 2>NUL
del /s /a "%USERPROFILE%\..\All Users\desktop.ini" >NUL 2>NUL
:skip_desktop_ini

REM *******************************************************
REM *           Verbinden der Serverlaufwerke             *
REM *******************************************************
if not "%OS%"=="Windows_NT" goto mapping
set NUOPT=/PERSISTENT:NO
if "%PERSISTENT_MAPPING%"=="yes" set NUOPT=/PERSISTENT:YES

REM echo   - Trenne alle bestehenden Netzwerkfreigaben
REM net use * /DELETE /YES >NUL
REM %LOGONSERVER%\netlogon\tools\sleep 500
echo   - Warte auf Explorer
%LOGONSERVER%\netlogon\tools\sbewaitforproc.exe -w 5 -s 2 explorer.exe
echo.

:mapping
echo   - Verbinde H: mit %LOGONSERVER%\%HOMESHARE%
if exist H: net use H: /DELETE /YES >NUL
if not exist H: goto connect_h
echo       FEHLER: Laufwerk H: ist bereits belegt und kann nicht entfernt werden!
goto read_user_settings

:connect_h
REM echo.|net use H: /HOME /YES %NUOPT% >NUL
REM if "%MAP_TWICE%"=="yes" net use H: /DELETE /YES >NUL
REM if "%MAP_TWICE%"=="yes" echo.|net use H: /HOME /YES %NUOPT% >NUL
REM if exist H: goto read_user_settings
%SystemRoot%\system32\cscript.exe %LOGONSERVER%\netlogon\map.vbs H: %LOGONSERVER%\%HOMESHARE% //NoLogo
if "%MAP_TWICE%"=="yes" cscript.exe %LOGONSERVER%\netlogon\map.vbs H: %LOGONSERVER%\%HOMESHARE% //NoLogo
if exist H: goto read_user_settings
echo.|net use H: %LOGONSERVER%\%HOMESHARE% /YES %NUOPT% >NUL
if "%MAP_TWICE%"=="yes" net use H: /DELETE /YES >NUL
if "%MAP_TWICE%"=="yes" echo.|net use H: %LOGONSERVER%\%HOMESHARE% /YES %NUOPT% >NUL
if exist H: goto read_user_settings
echo       FEHLER: Laufwerk H: kann nicht verbunden werden!

:read_user_settings
REM Bei der Anmeldung erzeugte Benutzerinformationen lesen
if not exist %LOGONSERVER%\%HOMESHARE%\.logon_settings.bat goto skip_read_user_settings
echo     - Lese Anmeldeeinstellungen
call %LOGONSERVER%\%HOMESHARE%\.logon_settings.bat
:skip_read_user_settings

if "%PGMDRIVE%"=="" set PGMDRIVE=P:
if "%SWPDRIVE%"=="" set SWPDRIVE=T:
if "%TPLDRIVE%"=="" set TPLDRIVE=V:

REM set SHARES=%SWPDRIVE% tausch %PGMDRIVE% pgm %TPLDRIVE% vorlagen %EXTRA_SHARES%
set SHARES=%SWPDRIVE% tausch %PGMDRIVE% pgm %EXTRA_SHARES%
if "%ROLE%"=="student" set SHARES=%SHARES%
if "%ROLE%"=="teacher" set SHARES=%SHARES%
if "%ROLE%"=="admin" set SHARES=%SHARES%
if not "%CUSTOM_SHARES%" == "" set SHARES=%CUSTOM_SHARES%

call %0 map_shares %SHARES%
if "%MAP_TWICE%"=="yes" call %0 map_shares %SHARES%
if "%EARLY_KILL_EXPLORER%"=="yes" taskkill /F /IM explorer.exe
if "%EARLY_KILL_EXPLORER%"=="yes" start explorer.exe

REM echo     - Veranlasse Explorer Refresh
REM %LOGONSERVER%\netlogon\tools\sbekill explorer.exe
REM start %LOGONSERVER%\netlogon\tools\osd -t 3000 -fs 20 Herzlich Willkommen!
echo.

REM *******************************************************
REM *         Uhrzeit mit Server synchronisieren          *
REM *******************************************************
echo   - Synchronisiere Uhrzeit mit %LOGONSERVER%
net time %LOGONSERVER% /SET /YES > NUL

REM *******************************************************
REM *               Sonstige Anpassungen                  *
REM *******************************************************
if not exist %LOGONSERVER%\netlogon\common.bat goto skip_common_bat
echo   - Starte %LOGONSERVER%\netlogon\common.bat
call %LOGONSERVER%\netlogon\common.bat
:skip_common_bat

REM *******************************************************
REM *            Rollenspezifische Anpassungen            *
REM *******************************************************
if not exist %LOGONSERVER%\netlogon\role_%ROLE%.bat goto skip_role_logon
echo   - Starte %LOGONSERVER%\netlogon\role_%ROLE%.bat
call %LOGONSERVER%\netlogon\role_%ROLE%.bat
:skip_role_logon

REM *******************************************************
REM *            Gruppenspezifische Anpassungen           *
REM *******************************************************
if not "%OS%"=="Windows_NT" goto skip_group_logon
for %%g in (%GROUPS%) do if exist %LOGONSERVER%\netlogon\group_%%g.bat (
  echo   - Starte %LOGONSERVER%\netlogon\group_%%g.bat
  call %LOGONSERVER%\netlogon\group_%%g.bat
)
:skip_group_logon

REM *******************************************************
REM *          Benutzerspezifische Anpassungen            *
REM *******************************************************
if not exist %LOGONSERVER%\netlogon\user_%USERNAME%.bat goto skip_user_logon
echo   - Starte %LOGONSERVER%\netlogon\user_%USERNAME%.bat
call %LOGONSERVER%\netlogon\user_%USERNAME%.bat
:skip_user_logon
if not exist H:\my_logon.bat goto skip_my_logon
echo   - Starte H:\my_logon.bat
call H:\my_logon.bat
:skip_my_logon
if "%KILL_EXPLORER%"=="yes" taskkill /F /IM explorer.exe
if "%KILL_EXPLORER%"=="yes" start explorer.exe
goto end

:map_shares
shift
:map
REM *******************************************************
REM *             Verbinde Netzwerkfreigaben              *
REM *******************************************************
if "%1"=="" goto realend
if "%2"=="" goto realend

set DRIVE=%1
set SHARE=%2
shift
shift

if not exist %DRIVE% goto connect
echo   - Trenne Laufwerk %DRIVE%
net use %DRIVE% /DELETE /YES > NUL
if not exist %DRIVE% goto connect
goto map

:connect
echo   - Verbinde %DRIVE% mit %LOGONSERVER%\%SHARE%
cscript.exe %LOGONSERVER%\netlogon\map.vbs %DRIVE% %LOGONSERVER%\%SHARE% //NoLogo
if exist %DRIVE% goto map
echo.|net use %DRIVE% %LOGONSERVER%\%SHARE% /YES %NUOPT% >NUL
goto map

:end

:realend
