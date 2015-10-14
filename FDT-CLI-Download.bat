@echo off
for %%a in (cls echo echo) do %%a.
REM set host=37.252.129.13
set /p host=Server : 
set /p src=Source : 
set /p dst=Destination : 
if /i not "%dst%"=="" (
	if not exist "%dst%" mkdir "%dst%"
)
echo.
java -jar %~dp0fdt.jar -noupdates -c %host% -pull -P 20 -r -d "%dst%" "%src%"
echo.
echo Press any key to exit...
pause>NUL
exit