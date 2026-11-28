@echo off
setlocal

echo ==================================================
echo  Build and Install pyfxr on Windows (MSVC)
echo ==================================================
echo.
echo BEFORE RUNNING THIS SCRIPT:
echo  1. Install Visual Studio Build Tools (or Visual Studio)
echo     with the "Desktop development with C++" workload.
echo  2. Open "x64 Native Tools Command Prompt for VS" from the
echo     Windows Start Menu (so cl.exe is in your PATH).
echo     You can verify that by typing:
echo         where cl
echo     -- and ENTER.
echo  3. Ensure your intended Python 3.14 is active or first in PATH.
echo     This script will show the exact interpreter and install target.
echo  4. Run this script from a directory owned and controlled
echo     by your current account, not a protected OS folder.
echo ==================================================
echo.

set /p "confirm=Have you completed the steps above and opened the x64 Native Tools Command Prompt? (y/n): "
if /i not "%confirm%"=="y" (
    echo Complete the prerequisites and run this script again.
    echo This script will now exit.
    pause
    exit /b 1
)

echo.
echo ==================================================
echo Step 1: Verifying MSVC compiler, Git, and Python...
echo ==================================================
where cl >nul 2>&1
if errorlevel 1 (
    echo ERROR: 'cl' compiler was not found in PATH.
    echo Please run this script from "x64 Native Tools Command Prompt for VS".
    pause
    exit /b 1
)
where git >nul 2>&1
if errorlevel 1 (
    echo ERROR: 'git' was not found in PATH.
    pause
    exit /b 1
)
where python >nul 2>&1
if errorlevel 1 (
    echo ERROR: 'python' was not found in PATH.
    pause
    exit /b 1
)

python --version
if errorlevel 1 goto :error

rem Detect whether this process is elevated (Administrator).
set "IS_ADMIN="
for /f "delims=" %%A in ('powershell -NoProfile -Command "$p = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent()); if ($p.IsInRole([Security.Principal.WindowsBuiltIn]::Administrator)) { Write-Output 1 } else { Write-Output 0 }"') do set "IS_ADMIN=%%A"
if not defined IS_ADMIN (
    echo ERROR: Could not determine whether this script is running elevated.
    pause
    exit /b 1
)

rem Detect whether Python is running inside a virtual environment.
set "IN_VENV="
for /f "delims=" %%A in ('python -c "import sys; print(0 if sys.prefix == sys.base_prefix else 1)"') do set "IN_VENV=%%A"
if not defined IN_VENV (
    echo ERROR: Could not determine whether Python is running in a virtual environment.
    pause
    exit /b 1
)

rem Resolve the Python installation's global/environment package directory and user site.
set "PYTHON_EXE="
set "PYTHON_PURELIB="
set "PYTHON_PLATLIB="
set "PYTHON_USER_SITE="
for /f "delims=" %%A in ('python -c "import sys; print(sys.executable)"') do set "PYTHON_EXE=%%A"
for /f "delims=" %%A in ('python -c "import sysconfig; print(sysconfig.get_path(chr(112)+chr(117)+chr(114)+chr(101)+chr(108)+chr(105)+chr(98)))"') do set "PYTHON_PURELIB=%%A"
for /f "delims=" %%A in ('python -c "import sysconfig; print(sysconfig.get_path(chr(112)+chr(108)+chr(97)+chr(116)+chr(108)+chr(105)+chr(98)))"') do set "PYTHON_PLATLIB=%%A"
for /f "delims=" %%A in ('python -c "import site; print(site.getusersitepackages())"') do set "PYTHON_USER_SITE=%%A"

if not defined PYTHON_EXE goto :error
if not defined PYTHON_PURELIB goto :error
if not defined PYTHON_PLATLIB goto :error
if not defined PYTHON_USER_SITE goto :error

rem Determine and explicitly choose the installation destination policy.
set "INSTALL_ARGS="
set "INSTALL_TARGET="
set "VERIFY_TARGET_2=%PYTHON_PLATLIB%"
set "INSTALL_MODE="

if "%IN_VENV%"=="1" (
    set "INSTALL_TARGET=%PYTHON_PURELIB%"
    set "INSTALL_MODE=active virtual environment"
    set "INSTALL_ARGS="
) else if "%IS_ADMIN%"=="1" (
    set "INSTALL_TARGET=%PYTHON_PURELIB%"
    set "INSTALL_MODE=global site-packages (elevated Administrator; pip default scheme)"
    set "INSTALL_ARGS="
) else (
    set "INSTALL_TARGET=%PYTHON_USER_SITE%"
    set "VERIFY_TARGET_2=%PYTHON_USER_SITE%"
    set "INSTALL_MODE=user site-packages (--user)"
    set "INSTALL_ARGS=--user"
    python -c "import site, sys; sys.exit(not site.ENABLE_USER_SITE)"
    if errorlevel 1 (
        echo ERROR: Python user-site installations are disabled for this interpreter.
        echo Cannot install pyfxr to the intended non-elevated user site.
        pause
        exit /b 1
    )
)

rem Remove any conflicting pathlib.py that shadows the standard
rem library. This MUST run before any pip invocation, because a shadowing
rem pathlib can break pip itself. Scan every sys.path entry (not just one
rem directory), attempt pip uninstall first (cleans metadata too), and
rem fall back to del for manually-dropped files.
for /f "delims=" %%P in ('python -c "import sys; print(chr(10).join(sys.path))"') do (
    if exist "%%P\pathlib.py" (
        echo.
        echo WARNING: Found conflicting pathlib.py in:
        echo     %%P
        echo Attempting removal via pip...
        python -m pip uninstall -y pathlib >nul 2>&1
        if exist "%%P\pathlib.py" (
            echo pip could not remove it ^(no dist-info^); deleting directly...
            del /f /q "%%P\pathlib.py"
            if errorlevel 1 goto :error
        )
        if exist "%%P\__pycache__\pathlib.*.pyc" (
            del /f /q "%%P\__pycache__\pathlib.*.pyc" >nul 2>&1
        )
    )
)

echo.
echo --------------------------------------------------
echo Python installation diagnostics:
echo --------------------------------------------------
echo Python executable: %PYTHON_EXE%
echo Python version:
python --version
echo.
echo pip:
python -m pip --version
echo.
echo Is elevated Administrator: %IS_ADMIN%
echo Active virtual environment: %IN_VENV%
echo Install mode: %INSTALL_MODE%
echo Expected installation target: %INSTALL_TARGET%
echo Python purelib: %PYTHON_PURELIB%
echo Python platlib: %PYTHON_PLATLIB%
echo Python user site: %PYTHON_USER_SITE%
echo.
echo Python sys.path and site configuration:
python -m site

echo.
echo ==================================================
echo Step 2: Installing Cython, wheel, and setuptools^<78...
echo ==================================================
python -m pip install %INSTALL_ARGS% --upgrade pip cython wheel
if errorlevel 1 goto :error

rem TO DO: see if it works without this constraint;
rem try commenting the next two lines out:
python -m pip install %INSTALL_ARGS% "setuptools<78"
if errorlevel 1 goto :error

rem Verify Cython via the Python import rather than the `cython`
rem console script, because --user installs put Scripts\ in a directory
rem that is usually not on PATH. Importing Cython works from any
rem interpreter that can see the package.
python -c "import Cython; print('Cython', Cython.__version__)"
if errorlevel 1 goto :error

echo.
echo ==================================================
echo Step 3: Building and installing pyfxr...
echo ==================================================
set "BUILD_ROOT=%TEMP%\pyfxr_build"
set "START_DIR=%CD%"

if exist "%BUILD_ROOT%" (
    rmdir /s /q "%BUILD_ROOT%"
    if errorlevel 1 goto :error
)

mkdir "%BUILD_ROOT%"
if errorlevel 1 goto :error

cd /d "%BUILD_ROOT%"
if errorlevel 1 goto :error

git clone https://github.com/lordmauve/pyfxr.git
if errorlevel 1 goto :error

cd /d "%BUILD_ROOT%\pyfxr"
if errorlevel 1 goto :error

rem Patch setup.cfg: the file holds [metadata] name/version
if exist "setup.cfg" (
    echo Patching setup.cfg: switching compiler from MinGW to MSVC...
    powershell -NoProfile -Command "(Get-Content setup.cfg) | ForEach-Object { $_ -replace '^(\s*compiler\s*=\s*)mingw32\s*$', '${1}msvc' } | Set-Content setup.cfg"
    if errorlevel 1 goto :error
)

rem fail fast if metadata absent
for /f "delims=" %%N in ('python -c "import configparser; c=configparser.ConfigParser(); c.read('setup.cfg'); print(c.get('metadata','name',fallback=''))"') do set "PKG_NAME=%%N"
if "%PKG_NAME%"=="" (
    echo ERROR: setup.cfg has no [metadata] name; the wheel would be named UNKNOWN.
    goto :error
)
echo Building package: %PKG_NAME%

echo Building wheel with --no-build-isolation...
python -m pip wheel --no-build-isolation --wheel-dir "%BUILD_ROOT%" .
if errorlevel 1 goto :error

echo.
echo Installing wheel into the verified target...
set "FOUND_WHEEL=0"

for %%f in ("%BUILD_ROOT%\pyfxr-*.whl") do (
    if exist "%%~f" (
        set "FOUND_WHEEL=1"
        python -m pip install %INSTALL_ARGS% --no-deps --force-reinstall "%%~f"
        if errorlevel 1 goto :error
    )
)

if "%FOUND_WHEEL%"=="0" (
    echo ERROR: No pyfxr wheel was found in %BUILD_ROOT%.
    goto :error
)

rem Verify the import resolves inside the intended installation directory.
echo.
echo ==================================================
echo Step 4: Verifying pyfxr's actual installed location...
echo ==================================================
cd /d "%START_DIR%"
if errorlevel 1 goto :error
set "PYFXR_EXPECTED_TARGET=%INSTALL_TARGET%"
set "PYFXR_EXPECTED_PLATLIB=%VERIFY_TARGET_2%"

python -c "import os, sys, pyfxr; p=os.path.normcase(os.path.abspath(pyfxr.__file__)); targets=[os.path.normcase(os.path.abspath(os.environ['PYFXR_EXPECTED_TARGET'])), os.path.normcase(os.path.abspath(os.environ['PYFXR_EXPECTED_PLATLIB']))]; print('Python executable:',sys.executable); print('Imported pyfxr from:',p); print('Expected target directories:',targets); ok=any(os.path.commonpath([p,t]) == t for t in targets); print('Target verification:', 'PASS' if ok else 'FAIL'); sys.exit(0 if ok else 1)"
if errorlevel 1 goto :error

rmdir /s /q "%BUILD_ROOT%"
if errorlevel 1 goto :error

echo.
echo ==================================================
echo  SUCCESS: pyfxr wheel built and installed!
echo ==================================================
echo.
echo pyfxr was verified inside:
echo     %INSTALL_TARGET%
echo.
echo NEXT STEP:
echo  The installation has already been verified by this script.
echo  You can also run this in a Python terminal:
echo      import pyfxr
echo ==================================================
echo.

set /p "launch_py=Would you like to open an interactive Python shell now to test 'import pyfxr'? (y/n): "
if /i "%launch_py%"=="y" (
    echo Type: import pyfxr
    python
)

pause
exit /b 0

:error
if defined START_DIR cd /d "%START_DIR%" >nul 2>&1
echo.
echo ==================================================
echo  ERROR: A build, installation, or verification command failed.
echo  Review the output above for details.
echo  The temporary build directory has been left for inspection,
echo  unless failure occurred before it was created.
echo ==================================================
pause
exit /b 1