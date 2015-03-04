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

REM Last Modification: 04.03.2015 - 17:22
REM Last Changes:
REM - GPL v3.0 text added
REM - Updated path for Java8
REM - Changed params delimiter in for loops
REM - Added feature to parse CSV files
REM - Cleaned the code a bit
REM - Fixed empty folder bug
REM - Removed quotes on dragDrop variable
REM - Fixed serious quotes handling issue
REM - Updated CSV parsing feature
REM - Removed line skipping from CSV feature

REM TODO:
REM - Fix issue with "()" in files and folders names


:begin
for %%a in (cls echo) do %%a.
setlocal EnableDelayedExpansion
title %~nx0 - CLI For FDT

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

REM Check the script named "FDT-CLI-Update.bat" to update the jar file.

REM Added "-noupdates" parameter in order to not interrupt the script process.
REM Added "-bs 4M" parameter in order to get more I/O buffers than default value [1M(ega)]
REM Added "-printStats" parameter in order to get more info on the server side.
REM Removed "-printStats" for debugging reason
set fdtParamsSRV=-noupdates -bs 4M

REM Removed -P 6, now using 4 streams as default. It seems to be better for multiple transfers
REM Added "-noupdates" parameter in order to not interrupt the script process.
set fdtParamsCLT=-noupdates -nbio -iof 3 -c localhost
REM set fdtParamsCLT=-noupdates -c localhost

REM Adding java to the path if not already exist
if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
	(echo "%path%" | find "%ProgramFiles%\Java\!javaPath!\bin">NUL) || set "path=%path%;%ProgramFiles%\Java\!javaPath!\bin"
) else (
	(echo "%path%" | find "%ProgramFiles(x86)%\Java\!javaPath!\bin">NUL) || set "path=%path%;%ProgramFiles(x86)%\Java\!javaPath!\bin"
)
goto detect_server

REM Detecting if FDT is started
:detect_server
REM netstat -ano			List all open ports without dns resolution and programs PID given
REM find /c /i "54321"		Search in the result from netstat if the FDT port is open, if not, starting the server
for /f "delims=" %%s in ('netstat -ano ^| find /c /i "54321"') do (
	if %%s NEQ 0 (
		echo FDT Server already started, Good. & echo.
		goto config
	) else (
		echo FDT Server not started. trying to start it... & echo.
		start /min /normal "FDT Server Console" cmd /k java -jar %fdtPath%\fdt.jar %fdtParamsSRV%
		goto config
	)
)

REM Item type detection
:detect_itemType
echo Detecting type...
REM Debugging specified data
REM echo. & echo %1
for /f "delims==" %%I in ("%~1") do (
	REM Debugging returned type
	REM echo %%~aI & echo.

	REM Windows 7 SP1 x64
	REM 	Folder types:
	REM		d--------
	REM		d-a------
	REM		dr-------
	REM		dr--s----
	REM		d--h-----
	REM		dr-h-----
	REM		d--hs---l
	REM 	File types:
	REM		-rah-----
	REM		--ahs----
	REM		--a------

	REM	Windows 8.1 x64
	REM 	Folder types:
	REM		d----------
	REM		d-a--------
	REM 	File types:
	REM		--a--------
	if "%%~aI"=="d--------" (
		set itemType=Directory
		set genericType=directory
	) else if "%%~aI"=="d----------" (
		REM Patch for Windows 8.1 x64
		set itemType=Directory
		set genericType=directory
		REM End of patch
	) else if "%%~aI"=="d-a------" (
		set itemType=Directory [AR]
		set genericType=directory
	) else if "%%~aI"=="d-a--------" (
		REM Patch for Windows 8.1 x64
		set itemType=Directory [AR]
		set genericType=directory
		REM End of patch
	) else if "%%~aI"=="dr-------" (
		set itemType=Directory [RO]
		set genericType=directory
	) else if "%%~aI"=="dr--s----" (
		set itemType=Directory [SYS]
		set genericType=directory
	) else if "%%~aI"=="d--h-----" (
		set itemType=Directory [HID]
		set genericType=directory
	) else if "%%~aI"=="dr-h-----" (
		set itemType=Directory [HID]
		set genericType=directory
	) else if "%%~aI"=="d--hs---l" (
		set itemType=Directory [HID][SYS]
		set genericType=directory
	) else if "%%~aI"=="-rah-----" (
		set itemType=File [RO][HID]
		set genericType=file
	) else if "%%~aI"=="--ahs----" (
		set itemType=File [HID][SYS]
		set genericType=file
	) else if "%%~aI"=="--a------" (
		set itemType=File
		set genericType=file
	) else if "%%~aI"=="--a--------" (
		REM Patch for Windows 8.1 x64
		set itemType=File
		set genericType=file
		REM End of patch
	) else (
		set itemType=File
		set genericType=file
	)

	if "!genericType!"=="directory" (
		set fdtRecursive=-r
		set delCMD=rmdir /s/q
	) else (
		set fdtRecursive=
		set delCMD=del /f/q
	)
)
goto :EOF

:config
REM Drag'n'Drop
set dragDrop=%*

REM Debugging memory
echo Memory content:
for %%m in (%dragDrop%) do (
	echo ^	^* %%m
)
echo.

REM Initializing counters
set count=0
set countTemp=0
set countTotal=0

REM Processing Mode
set /p processDataMode=Move or Copy ? [M, C] : 
if /i "%processDataMode%"=="M" (
	set choosedProcessDataMode=move
	set processState=Moving
) else if /i "%processDataMode%"=="C" (
	set choosedProcessDataMode=copy
	set processState=Copying
) else (
	goto begin
)

REM Reading the input
if defined dragDrop (
	REM echo. & echo - dragDrop variable [NOT EMPTY]
	REM Reading from memory
	if /i "%~1"=="auto" (
		set startMode=%~1
		set "listFile=%2"
	) else (
		set startMode=
		(echo "%dragDrop%" | find /i "list.txt">NUL) && (
			set "listFile=%dragDrop%"
		) || (
			(echo "%dragDrop%" | find /i "list.csv">NUL) && (
				set startMode=auto
				set "listFile=%dragDrop%"
			) || (
				set "dataIn=%dragDrop%"
				set "tempList=%temp%\tempList_%random%.txt"
			)
		)
	)
) else (
	REM echo. & echo - dragDrop variable [EMPTY]
	REM Reading from script
	set /p useList="Use list ? [Y, N] : 
	if /i "!useList!"=="Y" (
		set /p listFile=File list to read : 
	) else if /i "!useList!"=="N" (
		set /p dataIn=Source drive or directory : 
		set "tempList=%temp%\tempList_%random%.txt"
	)
)

REM Creating dynamic input list if no list file provided
if not defined listFile (
	REM echo. & echo - listFile NOT defined [OK]
	if defined tempList (
		REM echo - tempList defined [!tempList!]
		if defined dataIn (
			REM echo - dataIn defined:
			REM for %%d in (!dataIn!) do (
				REM echo ^	^* %%d
			REM )

			REM Temporary count
			for %%? in (!dataIn!) do ( set /a countTemp=!countTemp!+1 )

			if !countTemp! LEQ 1 (
				REM echo JUST ONE ENTRY
				call :detect_itemType !dataIn!

				if "!genericType!"=="directory" (
					set /p processContent=!processState! content or folder itself ? [C,I] : 
					if /i "!processContent!"=="C" (
						for /f "delims==" %%e in ('dir /b/a !dataIn! 2^>NUL') do (
							REM Filtering Windows cache files
							if /i not "%%e"=="thumbs.db" (
								REM Removing quotes added from the system
								set dataIn=!dataIn:"=!

								REM Adding quotes as it should be done
								echo "!dataIn!\%%e">>!tempList!
							)
						)
					) else if /i "!processContent!"=="I" (
						for %%e in (!dataIn!) do (
							REM Filtering Windows cache files
							if /i not "%%e"=="thumbs.db" (
								echo %%e>>!tempList!

							)
						)
					)
				) else (
					REM Filtering Windows cache files
					if /i not "!dataIn!"=="thumbs.db" (
						echo !dataIn!>>!tempList!
					)
				)
			) else (
				REM echo MULTIPLE ENTRIES [!countTemp!]
				for %%e in (!dataIn!) do (
					REM Filtering Windows cache files
					if /i not "%%e"=="thumbs.db" (
						echo %%e>>!tempList!
					)
				)
			)
			set listFile=!tempList!
		)
	)
)

REM Debugging list file
REM if defined tempList (
	REM echo. & echo SHOWING tempList CONTENT: & echo.
	REM type !tempList!
REM ) else if defined listFile (
	REM echo. & echo SHOWING listFile CONTENT: & echo.
	REM type !listFile!
REM )
REM echo. & echo countTemp: !countTemp! & echo. & pause & echo.

REM Checking if tempList is created
REM if not defined "!listFile!" (
	REM if not exist "!tempList!" (
		REM echo. & echo Temporary file list not created, source is probably empty. Exiting... & echo.
		REM goto quit
	REM )
REM )

REM Counting all items
if not defined startMode (
	for /f "delims=" %%? in (!listFile!) do ( set /a countTotal=!countTotal!+1 )
) else (
	for /f "skip=2 delims=" %%? in (!listFile!) do ( set /a countTotal=!countTotal!+1 )
)

REM Output drive or directory
:output_directory
if not defined startMode (
	echo.
	set /p dataOut=Destination drive or directory : 
	if "!dataOut!"=="" (
		echo - Destination must be specified ^^! & echo.
		goto :output_directory
	)
)

REM Limiting the speed
set /p speedLimit=Limit the speed ? [Y, N] : 
if /i "%speedLimit%"=="Y" (
	set fdtLimitDefault=4M
	set /p fdtLimit=Set limit to ^(Default^=4M^) ? [G, M] : 
	if "!fdtLimit!"=="" ( set "fdtLimit=!fdtLimitDefault!" )
	set fdtParamsCLT=%fdtParamsCLT% -limit !fdtLimit!
) else if /i "%speedLimit%"=="N" (
	set fdtLimit=
)

REM Showing Settings
cls
echo. & echo Config details: & echo.
echo - Processing Mode: %choosedProcessDataMode%
echo - FDT Parameters: !fdtParamsCLT!
if exist "!listFile!" (
	echo - Using list: Yes
	echo - List used: !listFile:"=!
) else (
	echo - Using list: No
)
REM Showing the data source
if not defined dragDrop ( echo - Source: !dataIn! ) else ( echo - Source: From list )
if not defined startMode ( echo - Destination: %dataOut% ) else ( echo - Destination: From list )
if /i "%speedLimit%"=="Y" (
	echo - Speed Limit: Yes
	echo - Bandwidth limited to: !fdtLimit!b/s
) else if /i "%speedLimit%"=="N" (
	echo - Speed Limit: No
)
echo.
set /p configGood=Everything is correct ? [Y, N] : 
REM if /i "%configGood%"=="Y" ( call :process ) else ( goto begin )
if /i "%configGood%"=="Y" (
	if not defined startMode (
		call :process
	) else (
		call :process_auto
	)
) else (
	goto begin
)
goto quit

:process
echo Called Function=%0
set "status=Parsing list [!listFile!]..." & title !status! & echo. & echo. & echo !status!
for /f "delims=" %%t in (!listFile!) do (
	REM Config
	set "src=%%~t" & set "src_name=%%~nxt"
	set "src_path=%%~dpt" & set src_path=!src_path:~0,-1!
	set dst=!dataOut!
	set /a count=!count!+1
	REM echo SRC=!src! ^| PATH=!src_path! ^| NAME=!src_name!
	REM echo DST=!dst!
	REM pause

	REM Check if item exist
	if exist "!src!" (
		REM Starting process
		echo. & echo *******************************************************************************
		echo Preparing to %choosedProcessDataMode% [!src_name!]...
		call :detect_itemType "!src!"
		echo Processing !itemType! [!src_name!]...
		echo %processState% !itemType! From [!src_path!] To [!dst!]...
		echo *******************************************************************************

		REM Creating output directory if not exist
		if not exist "!dst!" mkdir "!dst!"

		REM Fix for empty folders
		if not "!genericType!"=="file" (
			(dir /b /a "!src!" | findstr .)>NUL && (
				REM Command construction
				title %processState% !itemType! [!count!/!countTotal!] ^| [!src_name!] From [!src_path!] To [!dst!]...
				set fdtCMD=java -jar %fdtPath%\fdt.jar !fdtParamsCLT! !fdtRecursive! "!src!" -d "!dst!"
				echo Executing command: !fdtCMD! & call !fdtCMD! 2>NUL
			) || (
				REM Put some code here if you want to some text
			)
		) else (
			REM Command construction
			title %processState% !itemType! [!count!/!countTotal!] ^| [!src_name!] From [!src_path!] To [!dst!]...
			set fdtCMD=java -jar %fdtPath%\fdt.jar !fdtParamsCLT! !fdtRecursive! "!src!" -d "!dst!"
			echo Executing command: !fdtCMD! & call !fdtCMD! 2>NUL
		)

		REM Checking command result
		REM echo. & echo RETURNED ERRORLEVEL CODE: !ERRORLEVEL! & echo.
		if !ERRORLEVEL! EQU 0 (
			if exist "!dst!\!src_name!" (
				echo. & echo *******************************************************************************
				echo !itemType! [!src_name!] exist in [!dst!]
				echo This mean it has been copied with success.
				if /i "%processDataMode%"=="M" (
					echo Deleting [!src_name!] from local...
					call !delCMD! "!src!"
				)
				echo ******************************************************************************* & echo.
			) else (
				echo. & echo *******************************************************************************
				echo Error ^^!^^! [!ERRORLEVEL!]
				echo !itemType! [!src_name!] NOT EXIST in [!dst!]
				echo This mean there was an error during the %choosedProcessDataMode% process.
				echo Stopping the script...
				echo ******************************************************************************* & echo.
				goto quit
			)
		) else (
			if !ERRORLEVEL! EQU 1 (
				echo Location is probably empty, Skipping it... & echo.
			) else if !ERRORLEVEL! GTR 1 (
				goto quit
			)
		)
	) else (
		echo. & echo Location: !src! & echo does not exist. Going to the next... & echo.
	)
)
goto :EOF

:process_auto
REM Not sure I'm still need this :
set listFile=!listFile:"=!
REM End Not sure

echo Called Function=%0
set "status=Parsing list [!listFile!]..." & title !status! & echo. & echo. & echo !status!
REM echo Before the loop & echo.
for /f "usebackq tokens=1-2* delims=;" %%t in ("!listFile!") do (
	REM echo Inside the loop
	REM Config
	set "src=%%~t" & set "src_name=%%~nxt"
	set "src_path=%%~dpt" & set src_path=!src_path:~0,-1!
	if not "%%u"=="" (
		set "dst=%%u" & set "dst_name=%%~nxu"
		set "dst_path=%%~dpu" & set dst_path=!dst_path:~0,-1!
	)
	set /a count=!count!+1
	REM echo SRC=!src! ^| PATH=!src_path! ^| NAME=!src_name!
	REM echo DST=!dst! ^| PATH=!dst_path! ^| NAME=!dst_name!
	REM pause

	REM Check if item exist
	if exist "!src!" (
		REM Starting process
		echo. & echo *******************************************************************************
		echo Preparing to %choosedProcessDataMode% [!src_name!]...
		call :detect_itemType "!src!"
		echo Processing !itemType! [!src_name!]...
		echo %processState% !itemType! [!src!] To [!dst!]...
		echo *******************************************************************************

		REM Creating output directory if not exist
		if not exist "!dst!" mkdir "!dst!"

		if not "!genericType!"=="file" (
			REM Source directory name is equal to Destination directory name
			REM -> Copying source directory to the destination root directory
			if /i "!src_name!"=="!dst_name!" (
				(dir /b /a "!src!" | findstr .)>NUL && (
					echo. & echo **** Changed directory to [!dst_path!] **** & echo.
					title %processState% !itemType! [!count!/!countTotal!] ^| [!src_name!] From [!src_path!] To [!dst_path!]...
					set fdtCMD=java -jar %fdtPath%\fdt.jar !fdtParamsCLT! !fdtRecursive! "!src!" -d "!dst_path!"
					echo Executing command: !fdtCMD! & call !fdtCMD! 2>NUL
					REM echo Executing command: !fdtCMD! & pause
				) || (
					REM Put some code here if you want to some text
				)
				
				REM Checking command result
				REM echo. & echo RETURNED ERRORLEVEL CODE: !ERRORLEVEL! & echo.
				if !ERRORLEVEL! EQU 0 (
					if exist "!dst_path!\!src_name!" (
						echo. & echo *******************************************************************************
						echo !itemType! [!src_name!] exist in [!dst_path!]
						echo This mean it has been copied with success.
						if /i "%processDataMode%"=="M" (
							echo Deleting [!src_name!] from local...
							call !delCMD! "!src!"
						)
						echo ******************************************************************************* & echo.
					) else (
						echo. & echo *******************************************************************************
						echo Error ^^!^^! [!ERRORLEVEL!]
						echo !itemType! [!src_name!] NOT EXIST in [!dst_path!]
						echo This mean there was an error during the %choosedProcessDataMode% process.
						echo Stopping the script...
						echo ******************************************************************************* & echo.
						goto quit
					)
				) else (
					echo. & echo RETURNED ERRORLEVEL CODE: !ERRORLEVEL! & echo.
					goto quit
				)
			) else (
				REM Source directory name is not equal to Destination directory name
				REM -> Copying source directory to destination as expected
				(dir /b /a "!src!" | findstr .)>NUL && (
					title %processState% !itemType! [!count!/!countTotal!] ^| [!src_name!] From [!src_path!] To [!dst!]...
					set fdtCMD=java -jar %fdtPath%\fdt.jar !fdtParamsCLT! !fdtRecursive! "!src!" -d "!dst!"
					echo Executing command: !fdtCMD! & call !fdtCMD! 2>NUL
					REM echo Executing command: !fdtCMD! & pause
				) || (
					REM Put some code here if you want to some text
				)

				REM Checking command result
				REM echo. & echo RETURNED ERRORLEVEL CODE: !ERRORLEVEL! & echo.
				if !ERRORLEVEL! EQU 0 (
					if exist "!dst!\!src_name!" (
						echo. & echo *******************************************************************************
						echo !itemType! [!src_name!] exist in [!dst!]
						echo This mean it has been copied with success.
						if /i "%processDataMode%"=="M" (
							echo Deleting [!src_name!] from local...
							call !delCMD! "!src!"
						)
						echo ******************************************************************************* & echo.
					) else (
						echo. & echo *******************************************************************************
						echo Error ^^!^^! [!ERRORLEVEL!]
						echo !itemType! [!src_name!] NOT EXIST in [!dst!]
						echo This mean there was an error during the %choosedProcessDataMode% process.
						echo Stopping the script...
						echo ******************************************************************************* & echo.
						goto quit
					)
				) else (
					echo. & echo RETURNED ERRORLEVEL CODE: !ERRORLEVEL! & echo.
					goto quit
				)

				REM Disabled as it is not the right behaviour
				REM Source directory name is not equal to Destination directory name
				REM -> Copying source directory content
				REM for /f "delims=" %%z in ('dir /b/a !src!') do (
					REM REM Command construction
					REM echo.
					REM call :detect_itemType "!src!\%%z"
					REM echo !itemType! found inside [!src!]: %%z. & echo.
					REM title %processState% Directory - Content - [!count!/!countTotal!] ^| [!src_name!] From [!src_path!] To [!dst!]...
					REM set fdtCMD=java -jar %fdtPath%\fdt.jar !fdtParamsCLT! "!src!\%%z" -d "!dst!"
					REM echo Executing command: !fdtCMD! & call !fdtCMD! 2>NUL
					REM REM echo Executing command: !fdtCMD! & pause

					REM REM Checking command result
					REM REM echo. & echo RETURNED ERRORLEVEL CODE: !ERRORLEVEL! & echo.
					REM if !ERRORLEVEL! EQU 0 (
						REM if exist "!dst!\%%z" (
							REM echo. & echo *******************************************************************************
							REM echo !itemType! [%%z] exist in [!dst!]
							REM echo This mean it has been copied with success.
							REM if /i "%processDataMode%"=="M" (
								REM echo Deleting [%%z] from local...
								REM call !delCMD! "!src!\%%z"
							REM )
							REM echo ******************************************************************************* & echo.
						REM ) else (
							REM echo. & echo *******************************************************************************
							REM echo Error ^^!^^! [!ERRORLEVEL!]
							REM echo !itemType! [%%z] NOT EXIST in [!dst!]
							REM echo This mean there was an error during the %choosedProcessDataMode% process.
							REM echo Stopping the script...
							REM echo ******************************************************************************* & echo.
							REM goto quit
						REM )
					REM ) else (
						REM echo. & echo RETURNED ERRORLEVEL CODE: !ERRORLEVEL! & echo.
						REM goto quit
					REM )
				REM )
			)
		) else (
			REM Source is a file and not a directory
			title %processState% !itemType! [!count!/!countTotal!] ^| [!src_name!] From [!src_path!] To [!dst!]...
			set fdtCMD=java -jar %fdtPath%\fdt.jar !fdtParamsCLT! !fdtRecursive! "!src!" -d "!dst!"
			echo Executing command: !fdtCMD! & call !fdtCMD! 2>NUL
			REM echo Executing command: !fdtCMD! & pause

			REM Checking command result
			REM echo. & echo RETURNED ERRORLEVEL CODE: !ERRORLEVEL! & echo.
			if !ERRORLEVEL! EQU 0 (
				if exist "!dst!\!src_name!" (
					echo. & echo *******************************************************************************
					echo !itemType! [!src_name!] exist in [!dst!]
					echo This mean it has been copied with success.
					if /i "%processDataMode%"=="M" (
						echo Deleting [!src_name!] from local...
						call !delCMD! "!src!"
					)
					echo ******************************************************************************* & echo.
				) else (
					echo. & echo *******************************************************************************
					echo Error ^^!^^! [!ERRORLEVEL!]
					echo !itemType! [!src_name!] NOT EXIST in [!dst!]
					echo This mean there was an error during the %choosedProcessDataMode% process.
					echo Stopping the script...
					echo ******************************************************************************* & echo.
					goto quit
				)
			) else (
				echo. & echo RETURNED ERRORLEVEL CODE: !ERRORLEVEL! & echo.
				goto quit
			)
		)
		REM exit
	) else (
		echo. & echo Location: !src! & echo does not exist. Going to the next... & echo.
	)
)
REM echo Outside the loop
goto :EOF

:quit
if !ERRORLEVEL! NEQ 0 ( set "exitState=with error [!ERRORLEVEL!]" ) else ( set "exitState=with success" )
set exitString=FDT Script execution terminated !exitState!.
title !exitString! & echo ^		^!exitString! & echo ^			     ^Processed Items: !countTotal! & echo.
echo Press any key to exit... & pause>NUL
for %%v in (fdtPath fdtParamsCLT fdtRecursive fdtLimit dataIn dataOut listFile) do set %%v=
if exist "!listFile!" del /f /q !listFile!
exit
