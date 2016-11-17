@echo off
for %%a in (cls echo) do %%a.
setlocal EnableDelayedExpansion

REM Drag 'n' Drop
set dragDrop=%*
set id=0
set list=%~dp0list.txt
if not exist "%list%" type NUL>%list%
for %%I in (!dragDrop!) do (
	set /a id=!id!+1
	echo ID: !id! ^| ITEM: %%I ^| ATTRIB: %%~aI & echo.
	echo %%I>>%list%
)
pause
exit