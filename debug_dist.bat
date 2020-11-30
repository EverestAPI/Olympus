@echo off
cd dist

:RUN
set /p args="dist\main.exe --console "
.\main.exe --console %args%
echo.
goto RUN
