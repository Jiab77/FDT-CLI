@echo off
setlocal EnableDelayedExpansion

REM FDT-CLI - Command line interface for FDT
REM Copyright (C) 2015 - 2016  Jonathan Barda <jonathan.barda@gmail.com>

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

REM Last Modification: 27.10.2015 - 11:35
REM Last Changes:
REM - Added local java binary to make the script portable
REM - Added some debug stuff. set debug var to true to enable
REM - Cleaned the code a bit
REM - Added portability code in every files

REM Setting command line window
for %%a in (cls echo echo) do %%a.

REM FDT Config
set debug=
set "fdtPath=%~dp0" & set fdtPath=!fdtPath:~0,-1!
if defined debug title %~nx0 - CLI For FDT [Debug Mode]

REM Java Config
set javaBuild=1.8.0_60
set javaPath=!fdtPath!\java\{ARCH}\jre!javaBuild!\bin

REM According the local java path to the processor architecture
if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
	set javaPath=!javaPath:{ARCH}=x64!
) else (
	set javaPath=!javaPath:{ARCH}=x86!
)
set java=!javaPath!\java.exe
if defined debug (
	echo. & echo Java Executable: !java! & pause & echo.
)

REM User questions
set /p host=Server : 
set /p src=Source : 
set /p dst=Destination : 
if /i not "%dst%"=="" (
	if not exist "%dst%" mkdir "%dst%"
)
set fdtParamsCLT=-noupdates -c %host% -P 20

REM Initiating server connection
echo.
call !java! -jar %fdtPath%\fdt.jar %fdtParamsCLT% -pull -r -d "%dst%" "%src%"
echo.
echo Press any key to exit...
pause>NUL
exit