del %USERPROFILE%\Desktop\"Handbuch_Auszug_Lehrer_logodidact-de.lnk"
del %USERPROFILE%\Desktop\"Zagy Neo.URL"

REM *** eingefügt von Langer, da nach Installation immer die 
REM *** Username "Administrator" im Pfad eingetragen ist und
REM *** so beim Start von G E P ein nerfiger Hinweis erscheint.

REG ADD "HKCU\Software\Google\Google Earth Pro" /v KMLPath /t REG_SZ /d "C:\Users\%username%\AppData\LocalLow\Google\GoogleEarth" /f 
REG ADD "HKCU\Software\Google\Google Earth Pro" /v CachePath /t REG_SZ /d "C:\Users\%username%\AppData\LocalLow\Google\GoogleEarth" /f
REM *** Einfügung ENDE

del  "C:\Users\Public\Desktop\Kurswahl.lnk"
xcopy /Y /I "t:\Projekt kurswahl\Kurswahl.lnk" %USERPROFILE%\Desktop

del  "C:\Users\Public\Desktop\winbvs.lnk"
xcopy /Y /I "T:\Projekt schuelerbuecherei-001\bvs\winbvs.lnk" %USERPROFILE%\Desktop