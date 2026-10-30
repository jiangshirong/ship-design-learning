@echo off
setlocal
start "" "%~dp0runtime\godot.exe" --path "%~dp0." %*
endlocal
