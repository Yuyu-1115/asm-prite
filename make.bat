@echo off
setlocal

REM --- Configuration ---
REM Add any other common libraries here if your projects need them.
set LIBS=Irvine32.lib Kernel32.lib User32.lib

REM --- Check for commands (clean, run) or a filename ---
if "%1"=="" (
    goto :show_help
)

REM --- Command: clean ---
if /i "%1"=="clean" (
    echo Cleaning build files...
    del *.obj 2>nul
    del *.exe 2>nul
    del *.pdb 2>nul
    del *.ilk 2>nul
    del *.err 2>nul
    echo Done.
    goto :eof
)

REM --- Command: run ---
set RUN_AFTER_BUILD=false
set FILENAME_ARG=%1
if /i "%1"=="run" (
    if "%2"=="" (
        echo Error: "run" command needs a filename.
        echo Usage: make run MyFile.asm
        goto :eof
    )
    set RUN_AFTER_BUILD=true
    set FILENAME_ARG=%2
)

REM --- Get the base filename (e.g., "Lab10" from "Lab10.asm") ---
set FILENAME=%~n1
if /i "%1"=="run" (
    set FILENAME=%~n2
)

echo --- Building %FILENAME%.exe (32-bit x86) ---

REM --- 1. Assemble ---
echo [1] Assembling %FILENAME%.asm...
REM We use ".\" to ensure we use the ML.EXE in this folder.
REM Flags: /c = assemble only, /Zd = line num debug, /coff = standard object format
.\ML.EXE /c /Zd /coff "%FILENAME%.asm"

IF %ERRORLEVEL% NEQ 0 (
    echo.
    echo *** Assembly FAILED. ***
    goto :eof
)

REM --- 2. Link ---
echo [2] Linking %FILENAME%.obj...
REM We use ".\" to ensure we use the Link.exe in this folder.
REM Flags: /subsystem:console = command-line program
.\Link.exe /subsystem:console "%FILENAME%.obj" %LIBS%

IF %ERRORLEVEL% NEQ 0 (
    echo.
    echo *** Linking FAILED. ***
    goto :eof
)

echo [3] Build successful: %FILENAME%.exe
echo.

REM --- 3. Run (if requested) ---
if "%RUN_AFTER_BUILD%"=="true" (
    echo --- Running %FILENAME%.exe ---
    "%FILENAME%.exe"
)

endlocal
goto :eof

:show_help
echo.
echo  Usage:
echo    make [filename.asm]   (Assembles and links the file)
echo    make run [filename.asm] (Builds and then runs the file)
echo    make clean            (Removes all build files)
echo.
