set f_logon=Anmeldung
set f_patches=Patches
set f_groups=Gruppen
set f_roles=Rollen
set f_users=Benutzer
set f_programs=Programme

if not "%1"=="" goto %1
if exist %LOGONSERVER%\netlogon\settings.bat call %LOGONSERVER%\netlogon\settings.bat
if "%PGMDRIVE%"=="" set PGMDRIVE=P:


:old_patches
if not exist %PGMDRIVE%\%f_patches% goto old_patches_end
for %%i in (%PGMDRIVE%\%f_patches%\%f_logon%\*.bat) do call %%i
for /D %%i in (%PGMDRIVE%\%f_patches%\%f_logon%\*.*) do if exist %%i\start.bat if not exist %%i\disable call %%i\start.bat
:old_patches_end

:logon_patches
if not exist %PGMDRIVE%\%f_logon% goto end
for %%i in (%PGMDRIVE%\%f_logon%\*.bat) do call %%i
for /D %%i in (%PGMDRIVE%\%f_logon%\*.*) do if exist %%i\start.bat if not exist %%i\disable call %%i\start.bat
:logon_patches_end

:role_patches
call %0 process %PGMDRIVE%\%f_logon%\%f_roles%\%ROLE%
:role_patches_end

:group_patches
for %%g in (%GROUPS%) do call %0 process %PGMDRIVE%\%f_logon%\%f_groups%\%%g
:group_patches_end

:user_patches
call %0 process %PGMDRIVE%\%f_logon%\%f_users%\%USERNAME%
:user_patches_end

goto end

:process
if exist %2.reg call %0 import_reg %2.reg
if exist %2.bat call %0 run_bat %2.bat
if exist %2.rb call %0 run_rb %2.rb
if exist %2\start.reg call %0 import_reg %2\start.reg
if exist %2\start.bat if not exist %2\disable call %0 run_bat %2\start.bat
if exist %2\start.rb if not exist %2\disable call %0 run_rb %2\start.rb
goto end

:import_reg
echo   - Registry import: %2
regedit /s %2
goto end

:run_bat
echo   - Run script: %2
call %2
goto end

:run_rb
set ruby=%PGMDRIVE%\%f_programs%\Ruby\bin\ruby.exe
if not exist %ruby% goto end
echo   - Run script: %2
%ruby% %2
goto end

:run_exe
echo   - Run .exe: %2
%2
goto end

:end
