@REM this script must be run from the GSAS installation directory
@REM This is run to update the installation, the name of the EXP file is 
@REM expected as an argument
@echo ****************************
@echo Press return to start update
@echo ****************************
@pause
.\svn\bin\svn cleanup .
.\svn\bin\svn update .
@if (%1)==() goto Install2
@echo ****************************************************
@echo Update has completed. Press return to restart EXPGUI
@echo ****************************************************
@pause
%COMSPEC% /c "start exe\ncnrpack.exe expgui\expgui %1"
exit
:Install2
@echo ****************************************************
@echo Update has completed. EXPGUI starting w/o .EXP file
@echo ****************************************************
@pause
%COMSPEC% /c "start exe\ncnrpack.exe expgui\expgui"
exit
