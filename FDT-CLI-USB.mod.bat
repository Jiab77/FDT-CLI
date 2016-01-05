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

REM Last Modification: 27.10.2015 - 11:35
REM Last Changes:
REM - Added local java binary to make the script portable
REM - Added some debug stuff. set debug var to true to enable
REM - Cleaned the code a bit
REM - Added portability code in every files

REM TODO:
REM - Fix issue with "()" in files and folders names


:begin
REM Setting command line window
for %%a in (cls echo) do %%a.
title %~nx0 - CLI For FDT

REM FDT Config
set debug=
set "fdtPath=%~dp0" & set fdtPath=!fdtPath:~0,-1!
if defined debug title %~nx0 - CLI For FDT [Debug Mode]

REM Java Config
set javaBuild=1.8.0_60
set javaPath=!fdtPath!\java\{ARCH}\jre!javaBuild!\bin

REM Check the script named "FDT-CLI-Update.bat" to update the jar file.
REM Server parameters :
REM -noupdates	= Do not update the java binary before starting
REM -bs 4M		= Size for the I/O buffers. K (KiloBytes) or M (MegaBytes) may be used as suffixes. The default value is 512K.
REM -printStats	= Various statistics about buffer pools, sessions, etc will be printed
set fdtParamsSRV=-noupdates -bs 4M
set /p fdtServer=Enter server ip / name : 

REM Client parameters :
REM -P 6  		= Number of paralel streams to use. Default is 4. May vary the transfer speed
REM -noupdates	= Do not update the java binary before starting
set fdtParamsCLT=-noupdates -c %fdtServer% -P 20

REM According the local java path to the processor architecture
if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
	REM (echo "%path%" | find "%ProgramFiles%\Java\!javaPath!\bin">NUL) || set "path=%path%;%ProgramFiles%\Java\!javaPath!\bin"
	set javaPath=!javaPath:{ARCH}=x64!
) else (
	REM (echo "%path%" | find "%ProgramFiles(x86)%\Java\!javaPath!\bin">NUL) || set "path=%path%;%ProgramFiles(x86)%\Java\!javaPath!\bin"
	set javaPath=!javaPath:{ARCH}=x86!
)
set java=!javaPath!\java.exe
if defined debug (
	echo. & echo Java Executable: !java! & pause & echo.
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
		if /i "%fdtServer%"=="localhost" (
			echo FDT Server not started. trying to start it... & echo.
			start /min /normal "FDT Server Console" cmd /k !java! -jar %fdtPath%\fdt.jar %fdtParamsSRV%
		)
		goto config
	)
)

REM Item type detection
:detect_itemType
echo. & echo Detecting type...
REM Debugging specified data
if defined debug echo. & echo - Received parameter: %1
for /f "delims==" %%I in ("%~1") do (
	REM Debugging returned type
	if defined debug echo - Item attributes: %%~aI & echo.

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
if not "!itemType!"=="" echo Detected... !itemType!
goto :EOF

:config
REM Drag'n'Drop
set dragDrop=%*

REM Showing content from memory
if not "%dragDrop%"=="" (
	echo. & echo - Will process:
	for %%m in (%dragDrop%) do (
		echo ^	^* %%m
	)
	echo.
)

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
	if defined debug echo. & echo - dragDrop variable [NOT EMPTY]
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
	if defined debug echo. & echo - dragDrop variable [EMPTY]
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
	if defined debug echo - listFile NOT defined [OK]
	if defined tempList (
		if defined debug echo - tempList defined [!tempList!]
		type NUL>!tempList!
		if defined dataIn (
			if defined debug (
				echo - dataIn defined:
				for %%d in (!dataIn!) do (
					echo ^	^* %%d
				)
			)

			REM Temporary count
			for %%? in (!dataIn!) do ( set /a countTemp=!countTemp!+1 )
			
			if defined debug echo - Temporary count: !countTemp!

			if !countTemp! LEQ 1 (
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
if defined debug (
	if defined tempList (
		echo - Showing 'tempList' content: & echo.
		type !tempList!
	) else if defined listFile (
		echo - Showing 'listFile' content: & echo.
		type !listFile!
	)
	echo. & echo - Temporary count: !countTemp! & echo. & pause & echo.
)

REM Checking if tempList is created
if not defined "!listFile!" (
	if not exist "!tempList!" (
		echo. & echo Temporary file list not created, source is probably empty. Exiting... & echo.
		goto quit
	)
)

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
	set /p dataOut=Destination drive or directory ^(Without '\' at the end ^) :
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
if defined debug echo Called Function=%0
set "status=Parsing list [!listFile!]..." & title !status! & echo. & echo. & echo !status!
for /f "delims=" %%t in (!listFile!) do (
	REM Config
	set "src=%%~t" & set "src_name=%%~nxt"
	set "src_path=%%~dpt" & set src_path=!src_path:~0,-1!
	set dst=!dataOut!
	set /a count=!count!+1
	if defined debug (
		echo SRC=!src! ^| PATH=!src_path! ^| NAME=!src_name!
		echo DST=!dst!
		pause
	)

	REM Check if item exist
	if exist "!src!" (
		REM Starting process
		echo. & echo *******************************************************************************
		echo Preparing to %choosedProcessDataMode% [!src_name!]...
		call :detect_itemType "!src!"
		echo Processing !itemType! [!src_name!]...
		echo %processState% !itemType! From [!src_path!] To [!dst!]...
		echo *******************************************************************************

		REM Creating output directory if not exist (only if server runs on localhost)
		if /i "%fdtServer%"=="localhost" (
			if not exist "!dst!" mkdir "!dst!"
		)

		REM Fix for empty folders
		if not "!genericType!"=="file" (
			(dir /b /a "!src!" | findstr .)>NUL && (
				REM Command construction
				title %fdtServer% ^| %processState% !itemType! [!count!/!countTotal!] ^| [!src_name!] From [!src_path!] To [!dst!]...
				set fdtCMD=!java! -jar %fdtPath%\fdt.jar !fdtParamsCLT! !fdtRecursive! -d "!dst!" "!src!"
				if defined debug (
					echo Executing command:
					echo !fdtCMD! & call !fdtCMD! 2>NUL
				) else (
					call !fdtCMD! 2>NUL
				)
			) || (
				REM Put some code here if you want to some text
			)
		) else (
			REM Command construction
			title %fdtServer% ^| %processState% !itemType! [!count!/!countTotal!] ^| [!src_name!] From [!src_path!] To [!dst!]...
			set fdtCMD=!java! -jar %fdtPath%\fdt.jar !fdtParamsCLT! !fdtRecursive! -d "!dst!" "!src!"
			if defined debug (
				echo Executing command:
				echo !fdtCMD! & call !fdtCMD! 2>NUL
			) else (
				call !fdtCMD! 2>NUL
			)
		)

		REM Checking command result
		if defined debug echo. & echo RETURNED ERRORLEVEL CODE: !ERRORLEVEL! & echo.
		if !ERRORLEVEL! EQU 0 (
			REM Checking the destination only if server runs on localhost
			if /i "%fdtServer%"=="localhost" (
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

if defined debug echo Called Function=%0
set "status=Parsing list [!listFile!]..." & title !status! & echo. & echo. & echo !status!
if defined debug echo Before the loop & echo.
for /f "usebackq tokens=1-2* delims=;" %%t in ("!listFile!") do (
	if defined debug echo Inside the loop
	REM Config
	set "src=%%~t" & set "src_name=%%~nxt"
	set "src_path=%%~dpt" & set src_path=!src_path:~0,-1!
	if not "%%u"=="" (
		set "dst=%%u" & set "dst_name=%%~nxu"
		set "dst_path=%%~dpu" & set dst_path=!dst_path:~0,-1!
	)
	set /a count=!count!+1
	if defined debug (
		echo SRC=!src! ^| PATH=!src_path! ^| NAME=!src_name!
		echo DST=!dst! ^| PATH=!dst_path! ^| NAME=!dst_name!
		pause
	)

	REM Check if item exist
	if exist "!src!" (
		REM Starting process
		echo. & echo *******************************************************************************
		echo Preparing to %choosedProcessDataMode% [!src_name!]...
		call :detect_itemType "!src!"
		echo Processing !itemType! [!src_name!]...
		echo %processState% !itemType! [!src!] To [!dst!]...
		echo *******************************************************************************

		REM Creating output directory if not exist (only if server runs on localhost)
		if /i "%fdtServer%"=="localhost" (
			if not exist "!dst!" mkdir "!dst!"
		)

		if not "!genericType!"=="file" (
			REM Source directory name is equal to Destination directory name
			REM -> Copying source directory to the destination root directory
			if /i "!src_name!"=="!dst_name!" (
				(dir /b /a "!src!" | findstr .)>NUL && (
					echo. & echo **** Changed directory to [!dst_path!] **** & echo.
					title %fdtServer% ^| %processState% !itemType! [!count!/!countTotal!] ^| [!src_name!] From [!src_path!] To [!dst_path!]...
					set fdtCMD=!java! -jar %fdtPath%\fdt.jar !fdtParamsCLT! !fdtRecursive! -d "!dst_path!" "!src!"
					if defined debug (
						echo Executing command:
						echo !fdtCMD! & call !fdtCMD! 2>NUL
					) else (
						call !fdtCMD! 2>NUL
					)
				) || (
					REM Put some code here if you want to some text
				)
				
				REM Checking command result
				if defined debug echo. & echo RETURNED ERRORLEVEL CODE: !ERRORLEVEL! & echo.
				if !ERRORLEVEL! EQU 0 (
					REM Checking the destination only if server runs on localhost
					if /i "%fdtServer%"=="localhost" (
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
					)
				) else (
					echo. & echo RETURNED ERRORLEVEL CODE: !ERRORLEVEL! & echo.
					goto quit
				)
			) else (
				REM Source directory name is not equal to Destination directory name
				REM -> Copying source directory to destination as expected
				(dir /b /a "!src!" | findstr .)>NUL && (
					title %fdtServer% ^| %processState% !itemType! [!count!/!countTotal!] ^| [!src_name!] From [!src_path!] To [!dst!]...
					set fdtCMD=!java! -jar %fdtPath%\fdt.jar !fdtParamsCLT! !fdtRecursive! -d "!dst!" "!src!"
					if defined debug (
						echo Executing command:
						echo !fdtCMD! & call !fdtCMD! 2>NUL
					) else (
						call !fdtCMD! 2>NUL
					)
				) || (
					REM Put some code here if you want to some text
				)

				REM Checking command result
				if defined debug echo. & echo RETURNED ERRORLEVEL CODE: !ERRORLEVEL! & echo.
				if !ERRORLEVEL! EQU 0 (
					REM Checking the destination only if server runs on localhost
					if /i "%fdtServer%"=="localhost" (
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
			title %fdtServer% ^| %processState% !itemType! [!count!/!countTotal!] ^| [!src_name!] From [!src_path!] To [!dst!]...
			set fdtCMD=!java! -jar %fdtPath%\fdt.jar !fdtParamsCLT! !fdtRecursive! -d "!dst!" "!src!"
			if defined debug (
				echo Executing command:
				echo !fdtCMD! & call !fdtCMD! 2>NUL
			) else (
				call !fdtCMD! 2>NUL
			)

			REM Checking command result
			if defined debug echo. & echo RETURNED ERRORLEVEL CODE: !ERRORLEVEL! & echo.
			if !ERRORLEVEL! EQU 0 (
				REM Checking the destination only if server runs on localhost
				if /i "%fdtServer%"=="localhost" (
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
if defined debug echo Outside the loop
goto :EOF

:quit
if !ERRORLEVEL! NEQ 0 ( set "exitState=with error [!ERRORLEVEL!]" ) else ( set "exitState=with success" )
set exitString=FDT Script execution terminated !exitState!.
title !exitString! & echo ^		^!exitString! & echo ^			     ^Processed Items: !countTotal! & echo.
echo Press any key to exit... & pause>NUL
for %%v in (fdtPath fdtParamsCLT fdtRecursive fdtLimit dataIn dataOut listFile) do set %%v=
if exist "!listFile!" del /f /q !listFile!
if exist "!tempList!" del /f /q !tempList!
exit
