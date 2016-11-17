@echo off
setlocal EnableDelayedExpansion
REM Copyright (C) 2015  Jonathan Barda <jonathan.barda@gmail.com>

REM This program is free software: you can redistribute it and/or modify
REM it under the terms of the GNU General Public License as published by
REM the Free Software Foundation, either version 3 of the License, or
REM (at your option) any later version.

REM This program is distributed in the hope that it will be useful,
REM but WITHOUT ANY WARRANTY; without even the implied warranty of
REM MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
REM GNU General Public License for more details.

REM You should have received a copy of the GNU General Public License
REM along with this program.  If not, see <http://www.gnu.org/licenses/>.

REM 32Bit and 64Bit Version

REM File to extract
set file=jre-8u60-windows-x64.rar
set file=%~dp0!file!

REM Searching for WinRAR
if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
	set "wrar_path=%ProgramFiles%\WinRAR"
) else (
	set "wrar_path=%ProgramFiles(x86)%\WinRAR"
)

REM Extracting files if WinRAR exist
if exist "%wrar_path%\Rar.exe" (
	set "rar=%wrar_path%\Rar.exe"
	call "!rar!" x "%file%" * .\
	echo. & echo Press any key to exit... & pause>NUL
) else (
	echo. & echo '!rar!' not found ^^! Can't extract the java files & echo.
	echo Press any key to exit... & pause>NUL
)
exit