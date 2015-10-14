@echo off
title FDT-CLI Server Console
java -jar %~dp0fdt.jar -noupdates -bs 4M -printStats
