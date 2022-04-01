@ECHO off
cls
:start
ECHO.
ECHO 1. Debug
ECHO 2. Release
ECHO.
set choice=
set /p choice=Choose the compilation mode and press [Enter].
if not '%choice%'=='' set choice=%choice:~0,1%
if '%choice%'=='1' (
  set BuildConfig=debug
  goto platform
) 
if '%choice%'=='2' (
  set BuildConfig=release
  goto platform  
)
ECHO.  
ECHO "%choice%" Invalid option, try again.
ECHO.
goto start

:platform
ECHO.
ECHO 1. Win32
ECHO 2. Win64
ECHO.
set choice=
set /p choice=Choose the target platform and press [Enter].
if not '%choice%'=='' set choice=%choice:~0,1%
if '%choice%'=='1' (
  set TargetPlatform=Win32
  goto build
)
if '%choice%'=='2' (
  set TargetPlatform=Win64
  goto build
)
ECHO.
ECHO "%choice%" Invalid option, try again.
ECHO.
goto platform

:build
REM set DPXWorkspace=X:

REM set BuildTarget=clean
REM start /b Build-Instructions.cmd
set BuildTarget=build
start /b Build-Instructions.cmd

goto finish

:finish
pause
exit


