@ECHO OFF

SETLOCAL

set PST_PATH=%CD%

set RC=0

:: get installed perl ; version dont care
for /f %%I in ('dir c:\progagk\perl64\perl.exe /s/b') do (
     set PERL_VERSION=%%I
     goto :ACTION
  )
  
:ACTION  
echo Using : %PERL_VERSION%

if EXIST %PERL_VERSION% goto BATCHBEGIN

::set PERL_VERSION="N:\Programme\Tools\PERL\v5.8.0\bin\perl.exe"

::if EXIST %PERL_VERSION% goto BATCHBEGIN


goto NO_PERL




:BATCHBEGIN
SET FILE=".\A2L_DAI_ExtendedLimits_Patch_1v1.pl"

echo. 
echo      A2L_DAI_ExtendedLimits_Patch 1v1
echo      ================================
echo.
echo.


:: **** PVER-Name ermitteln *******************************************
:GETPVERNAME
SET TEMP_NAME=

if NOT EXIST %PST_PATH%\_bin\swb goto HEX_NOT_EXIST
cd _bin\swb\

for %%i in (*.hex) do (
	SET TEMP_NAME=%%i
)

if %TEMP_NAME%=="" goto HEX_NOT_EXIST
set PST_NAME=%TEMP_NAME:~0,-4%

cd ..
cd ..


:: **** Pfad-Pruefung ************************************************
if NOT EXIST %PST_PATH%\_bin\swb\%PST_NAME%_customer_patch_final.a2l goto NO_XMLTC

if NOT EXIST %PST_PATH%\A2lStrip_Fkt_List.txt goto CHECK_FKTLIST_XMLTC
SET FKTLIST="%PST_PATH%\A2lStrip_Fkt_List.txt"
goto SET_A2LNAME_XMLTC

:CHECK_FKTLIST_XMLTC
if NOT EXIST %PST_PATH%\_gen\swb\module\data\mdx2msr_fdef_list.txt goto NO_FKTLIST
SET FKTLIST="%PST_PATH%\_gen\swb\module\data\mdx2msr_fdef_list.txt"


:: **** Set A2L-Name ************************************************
:SET_A2LNAME_XMLTC
set A2LNAME=%PST_NAME%_customer_patch_final
set A2LPATH=%PST_PATH%\_bin\swb\
goto CALL_PERL


:NO_XMLTC
echo.
echo NO XML-TOOLCHAIN A2L found...
if NOT EXIST %PST_PATH%\_bin\swb\%PST_NAME%.a2l goto NO_A2L

if NOT EXIST %PST_PATH%\A2lStrip_Fkt_List.txt goto CHECK_FKTLIST
SET FKTLIST="%PST_PATH%\A2lStrip_Fkt_List.txt"
goto SET_A2LNAME

:CHECK_FKTLIST
if NOT EXIST %PST_PATH%\_gen\swb\module\data\mdx2msr_fdef_list.txt goto NO_FKTLIST
SET FKTLIST="%PST_PATH%\_gen\swb\module\data\mdx2msr_fdef_list.txt"


:: **** Set A2L-Name ************************************************
:SET_A2LNAME
set A2LNAME=%PST_NAME%
set A2LPATH=%PST_PATH%\_bin\swb\
goto CALL_PERL


:: **** Script-Aufruf ************************************************
:CALL_PERL

%PERL_VERSION% %FILE% %A2LNAME% %A2LPATH% %FKTLIST% %PST_NAME%
	set RC=%errorlevel%

if %RC% neq 0 (
	if "%1"=="" goto PAUSE
	goto RESET_VARIABLES
	)
		
if "%1" neq "" goto RESET_VARIABLES


:PAUSE
pause
goto RESET_VARIABLES

:NO_A2L
echo %PST_PATH%\_bin\swb\%PST_NAME%.a2l not found
pause
goto RESET_VARIABLES

:NO_FKTLIST
echo %PST_PATH%\_gen\swb\module\data\mdx2msr_fdef_list.txt not found
pause
goto RESET_VARIABLES

:HEX_NOT_EXIST
echo Hex-File not found
pause
goto RESET_VARIABLES


:NO_PERL
cls
ECHO.
ECHO ****************************************************
ECHO * No Perl Version found                            *
ECHO * Please adapt Batch file and add your path        *
ECHO * to the existing Perl Tool                        *
ECHO *                                                  *
ECHO ****************************************************
ECHO.
pause
goto RESET_VARIABLES

:: **** reset variables **********************************************

:RESET_VARIABLES
SET PST_PATH=
SET PST_NAME=
SET PERL=
SET FILE=

if %RC% neq 0 (
		ENDLOCAL
		exit /B 1
	)

ENDLOCAL

exit /B 0

:: *----------- end of file --------------


