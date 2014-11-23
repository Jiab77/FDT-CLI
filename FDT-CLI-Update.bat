@echo off
REM Made by Jonathan Barda AKA Jon - 2013
REM 32Bit and 64Bit Version
REM
REM eMail: Jonathan Barda <jonathan.barda@gmail.com>
REM
REM Last Modification: 19.11.2014 - 12:32
REM Last Changes:
REM - Added copyright stuff and kind of changelog
REM - Fixed .jar file path
REM - Fixed Java detection


for %%a in (cls echo) do %%a.
setlocal EnableDelayedExpansion
title %~nx0 - FDT CLI Updater

REM FDT Config
set "fdtPath=%~dp0" & set fdtPath=!fdtPath:~0,-1!

REM Adding java to the path if not already exist
if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
	(echo "%path%" | find "%ProgramFiles%\Java\jre7\bin">NUL) || set "path=%path%;%ProgramFiles%\Java\jre7\bin"
) else (
	(echo "%path%" | find "%ProgramFiles(x86)%\Java\jre7\bin">NUL) || set "path=%path%;%ProgramFiles(x86)%\Java\jre7\bin"
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
