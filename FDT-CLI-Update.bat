@echo off
REM Copyright (C) 2013  Jonathan Barda <jonathan.barda@gmail.com>

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

REM Last Modification: 10.02.2015 - 22:54
REM Last Changes:
REM - Added copyright stuff and kind of changelog
REM - Fixed .jar file path
REM - Fixed Java detection
REM - Removed old copyright stuff
REM - Removed unneeded "REM" command
REM - GPL v3.0 text added
REM - Updated path for Java8

:begin
for %%a in (cls echo) do %%a.
setlocal EnableDelayedExpansion
title %~nx0 - FDT CLI Updater

REM FDT Config
set "fdtPath=%~dp0" & set fdtPath=!fdtPath:~0,-1!

REM Java Config
set javaVersion=7
if "%javaVersion%"=="7" (
	set javaPath=jre7
) else if "%javaVersion%"=="8" (
	set javaBuild=1.8.0_31
	set javaPath=jre!javaBuild!
)

REM Adding java to the path if not already exist
if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
	(echo "%path%" | find "%ProgramFiles%\Java\!javaPath!\bin">NUL) || set "path=%path%;%ProgramFiles%\Java\!javaPath!\bin"
) else (
	(echo "%path%" | find "%ProgramFiles(x86)%\Java\!javaPath!\bin">NUL) || set "path=%path%;%ProgramFiles(x86)%\Java\!javaPath!\bin"
)
goto detect_server

REM Detect if FDT is started
:detect_server
REM netstat -ano		List all open ports without dns resolution and programs PID given
REM find /c /i "54321"		Search in the result from netstat if the FDT port is open, if not, starting the server
for /f "delims=" %%s in ('netstat -ano ^| find /c /i "54321"') do (
	if %%s NEQ 0 (
		echo FDT Server already started, YOU MUST CLOSE IT before continue. & echo.
		goto quit
	) else (
		echo FDT Server not started, Good. Trying to update it... & echo.
		pushd %fdtPath%
		REM (java -jar fdt.jar -update >NUL) && ( call :success ) || ( call :failed )
		java -jar fdt.jar -update >NUL
		if !ERRORLEVEL! EQU 100 (
			call :updated
		) else (
			if !ERRORLEVEL! EQU 0 (
				call :success
			) else (
				call :failed
			)
		)
		goto quit
	)
)

:success
echo.
echo Congratulation ^^! You have successfully updated your FDT binary.
echo.
goto :EOF

:failed
echo.
echo Unexpected error ^^! Something wrong happened, your FDT binary should not been touched.
echo Your FDT server was not updated has you got an issue.
goto :EOF

:updated
echo.
echo Great ^^! Your FDT binary is already up to date.
echo Nothing were done.
echo.
goto :EOF

:quit
echo.
echo Thanks for using this FDT updater script.
REM echo RETURNED CODE: !ERRORLEVEL!
if !ERRORLEVEL! NEQ 0 (
	if !ERRORLEVEL! NEQ 100 (
		echo Sad to know it was not without errors... hope I'll find what's wrong.
	)
) else (
	echo Glad to know it was without any errors ^^!
)
popd
echo.
echo Press any key to exit...
pause>NUL
exit
