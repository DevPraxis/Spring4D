@echo off
if '%BuildConfig%' =='' (
  echo Invalid build configuration, try to execute "Build-Exec.cmd" instead
  goto buildfinish
)

goto build

:build

call "C:\Program Files (x86)\Embarcadero\Studio\21.0\bin\rsvars.bat"
call "C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\rsvars.bat"

MSBuild /t:%BuildTarget% /p:DCC_Hints=false;DCC_Warnings=false;config=%BuildConfig%;Platform=%TargetPlatform% "..\Packages\Delphi11\Spring4D_RunTime.groupproj"
if errorlevel=1 goto builderror

goto buildfinish

:builderror
echo ############ BUILD ERROR ############ 

ECHO.
ECHO 1. Try Again. Or press any key to Exit.
ECHO.
set choice=
set /p choice=Choose the compilation mode and press [Enter].
if not '%choice%'=='' set choice=%choice:~0,1%
if '%choice%'=='1' (
  goto build
) 
exit 

:buildfinish
pause
exit
