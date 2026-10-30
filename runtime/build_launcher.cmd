@echo off
"%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /nologo /target:winexe /reference:System.Windows.Forms.dll /out:"%~dp0godot.exe" "%~dp0engine_launcher.cs"
