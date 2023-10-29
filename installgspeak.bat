@echo off

set teamspeakDestination=%1
set garrysmodDestination=%2

set channel=Release

IF NOT "%3"=="" (
	set channel=%3
)

set sourceTsLib32="%~dp0\GspeakGarrysmodPlugin\projects\windows\vs2022\x86\%channel%"
set sourceTsLib64="%~dp0\GspeakGarrysmodPlugin\projects\windows\vs2022\x86_64\%channel%"
set sourceGspeak32="%~dp0\GspeakTeamspeakPlugin\bin\%channel%\Win32\Gspeak"
set sourceGspeak64="%~dp0\GspeakTeamspeakPlugin\bin\%channel%\x64\Gspeak"

robocopy %sourceTsLib32% %garrysmodDestination% "gmcl_tslib_win32.dll" /is /it /R:0 /W:0
robocopy %sourceTsLib64% %garrysmodDestination% "gmcl_tslib_win64.dll" /is /it /R:0 /W:0
robocopy %sourceGspeak32% %teamspeakDestination% "gspeak_win32.dll" /is /it /R:0 /W:0
robocopy %sourceGspeak64% %teamspeakDestination% "gspeak_win64.dll" /is /it /R:0 /W:0

exit