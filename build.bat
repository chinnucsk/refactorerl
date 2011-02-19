@echo off
REM See INSTALL-WIN.txt for instructions.

REM Configuration section ---------------------------------------------------
REM Please use forward slashes in the paths below.

REM Base directory drive and path of RefactorErl source code
set BASEDRIVE=C:
set BASEPATH=RefactorErl-0.1

REM Base directory of Erang/OTP
set ERLANG=C:/Program Files/erl5.5.5

REM No changes are needed below this line -----------------------------------

set ERL=%ERLANG%\bin\erl.exe

%BASEDRIVE%
cd "\%BASEPATH%\distel\src"
"%ERL%" -make

cd "\%BASEPATH%\refactor\src"
"%ERL%" -make

cd "\%BASEPATH%"

echo Creating startup scripts...
echo @echo off> runerl.bat
echo set BASE="%BASEDRIVE%\%BASEPATH%">> runerl.bat
echo set ERLANG="%ERLANG%">> runerl.bat
type inst\runerl.win >> runerl.bat

echo (setq refactorer-base-dir "%BASEDRIVE%/%BASEPATH%")> load-refac.el
echo (setq erlang-root-dir "%ERLANG%")>> load-refac.el
type inst\load-refac >> load-refac.el