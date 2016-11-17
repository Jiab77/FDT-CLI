@echo off
if "%1"=="" goto param_needed
for %%A in (%*) do if "%%A" == "-c" goto do_exec
echo "***************************************************"
echo "******* Please specify the server address *********"
echo "***************************************************"
goto help
:do_exec
java -jar fdt.jar %*
goto :EOF
:param_needed
		echo "***************************************************"
		echo "************** Parameters needed ******************"
		echo "***************************************************"
		goto help
:help
		java -jar fdt.jar -h
		goto :EOF
:end
