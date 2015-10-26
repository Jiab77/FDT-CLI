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

for %%a in (cls echo echo) do %%a.
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