@echo off
setlocal enabledelayedexpansion
REM ctags-lookup using rg + jq
REM Usage:
REM   lookup.cmd --name "Dispose"
REM   lookup.cmd --prefix "Get"
REM   lookup.cmd --name "Dispose" --tags-file C:\path\to\tags

set "SCRIPT_DIR=%~dp0"
set "TAGS_FILE="
set "NAME="
set "PREFIX="

:parse_args
if "%~1"=="" goto :validate
if /i "%~1"=="--name" (
    set "NAME=%~2"
    shift & shift
    goto :parse_args
)
if /i "%~1"=="--prefix" (
    set "PREFIX=%~2"
    shift & shift
    goto :parse_args
)
if /i "%~1"=="--tags-file" (
    set "TAGS_FILE=%~2"
    shift & shift
    goto :parse_args
)
echo Error: Unknown argument: %~1 >&2
exit /b 1

:validate
if not defined TAGS_FILE set "TAGS_FILE=%SCRIPT_DIR%tags"

if defined NAME if defined PREFIX (
    echo Error: specify either --name or --prefix, not both. >&2
    exit /b 1
)

if not defined NAME if not defined PREFIX (
    echo Error: specify at least one of: --name, --prefix >&2
    exit /b 1
)

if not exist "%TAGS_FILE%" (
    echo Error: tags file not found: %TAGS_FILE% >&2
    exit /b 1
)

where rg >nul 2>&1
if errorlevel 1 (
    echo Error: ripgrep ^(rg^) not found on PATH. >&2
    exit /b 1
)

where jq >nul 2>&1
if errorlevel 1 (
    echo Error: jq not found on PATH. >&2
    exit /b 1
)

REM Build rg pattern
if defined NAME (
    set "RG_PATTERN=^%NAME%	"
) else (
    set "RG_PATTERN=^%PREFIX%[^	]*	"
)

REM Set env var for jq filter to do exact-name post-filtering
set "CTAGS_EXACT_NAME=%NAME%"

REM Run pipeline. rg exit code 1 = no matches, jq will output []
rg --no-filename --no-line-number -e "%RG_PATTERN%" "%TAGS_FILE%" 2>nul | jq -nMRf "%SCRIPT_DIR%parse-ctags.jq"
if errorlevel 2 (
    echo []
)

endlocal
