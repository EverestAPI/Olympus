@echo off
cd src

:RUN
set /p args="love\love.exe --console src "
..\love\love.exe --console . %args%
echo.
goto RUN
