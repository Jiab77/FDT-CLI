@echo off
for %%a in (cls echo echo) do %%a.
set src=%*
set /p host=Server :
set /p dst=Destination :
echo.
java -jar %~dp0fdt.jar -noupdates -c %host% -P 20 -r -d "%dst%" "%src%"
echo.
echo Press any key to exit...
pause>NUL
exit