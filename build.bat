@echo off
setlocal enabledelayedexpansion
title H5Pic100 build

rem === locate script root ===
set "ROOT=%~dp0"
set "SRC=%ROOT%app\src\main"
set "B=%ROOT%app\build"

rem === locate JDK (JAVA_HOME first, then PATH) ===
set "JAVABIN="
if defined JAVA_HOME if exist "%JAVA_HOME%\bin\javac.exe" set "JAVABIN=%JAVA_HOME%\bin"
if not defined JAVABIN (
    for /f "delims=" %%i in ('where javac 2^>nul') do (
        if not defined JAVABIN set "JAVABIN=%%~dpi"
    )
)
if not defined JAVABIN (
    echo [ERROR] javac not found. Install a JDK and set JAVA_HOME.
    pause
    exit /b 1
)
set "PATH=%JAVABIN%;%PATH%"

rem === locate Android SDK ===
if not defined ANDROID_HOME set "ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk"
if not exist "%ANDROID_HOME%\build-tools" (
    echo [ERROR] Android SDK not found at: %ANDROID_HOME%
    echo Set ANDROID_HOME to your SDK path, e.g. E:\Android\sdk
    pause
    exit /b 1
)
set "SDK=%ANDROID_HOME%"

rem === pick newest build-tools and newest android platform ===
for /f "delims=" %%d in ('dir /b /ad /o-n "%SDK%\build-tools" 2^>nul') do if not defined BT set "BT=%SDK%\build-tools\%%d"
for /f "delims=" %%d in ('dir /b /ad /o-n "%SDK%\platforms" 2^>nul') do (
    set "NAME=%%d"
    if "!NAME:~0,8!"=="android-" if not defined PLAT set "PLAT=%SDK%\platforms\%%d"
)
if not defined BT ( echo [ERROR] No build-tools found in %SDK% & pause & exit /b 1 )
if not defined PLAT ( echo [ERROR] No android-XX platform found in %SDK% & pause & exit /b 1 )
set "AJ=%PLAT%\android.jar"

echo.
echo === Build tools : %BT%
echo === Android jar : %AJ%
echo === JDK         : %JAVABIN%
echo.

for %%d in (compiled gen classes dex linked unsigned) do if not exist "%B%\%%d" mkdir "%B%\%%d"

rem === 1/7 compile resources ===
echo [1/7] aapt2 compile
"%BT%\aapt2.exe" compile --dir "%SRC%\res" -o "%B%\compiled\res.zip"
if errorlevel 1 goto :fail

rem === 2/7 link resources, assets, manifest (also generates R.java) ===
echo [2/7] aapt2 link
"%BT%\aapt2.exe" link -o "%B%\linked\base.apk" -I "%AJ%" --manifest "%SRC%\AndroidManifest.xml" -A "%SRC%\assets" --java "%B%\gen" "%B%\compiled\res.zip" --auto-add-overlay
if errorlevel 1 goto :fail

rem === 3/7 compile java ===
echo [3/7] javac
del /q "%B%\classes\com\h5pic100\*.class" 2>nul
javac -source 1.8 -target 1.8 -classpath "%AJ%" -d "%B%\classes" "%B%\gen\com\h5pic100\R.java" "%SRC%\java\com\h5pic100\MainActivity.java"
if errorlevel 1 goto :fail

rem === 4/7 dex ===
echo [4/7] d8 (dex)
set "CLASSLIST="
for %%f in ("%B%\classes\com\h5pic100\*.class") do set "CLASSLIST=!CLASSLIST! "%%f""
java -cp "%BT%\lib\d8.jar" com.android.tools.r8.D8 --release --lib "%AJ%" --output "%B%\dex" !CLASSLIST!
if errorlevel 1 goto :fail

rem === 5/7 add classes.dex into the apk ===
echo [5/7] jar update
copy /y "%B%\linked\base.apk" "%B%\unsigned\app-unsigned.apk" >nul
"%JAVABIN%\jar.exe" uf "%B%\unsigned\app-unsigned.apk" -C "%B%\dex" classes.dex
if errorlevel 1 goto :fail

rem === 6/7 zipalign ===
echo [6/7] zipalign
"%BT%\zipalign.exe" -f 4 "%B%\unsigned\app-unsigned.apk" "%B%\unsigned\app-aligned.apk"
if errorlevel 1 goto :fail

rem === 7/7 sign ===
echo [7/7] apksigner
if not exist "%B%\debug.keystore" (
    echo Creating debug keystore...
    "%JAVABIN%\keytool.exe" -genkeypair -keystore "%B%\debug.keystore" -alias androiddebugkey -storepass android -keypass android -dname "CN=Android Debug,O=Android,C=US" -keyalg RSA -keysize 2048 -validity 10000
    if errorlevel 1 goto :fail
)
java -jar "%BT%\lib\apksigner.jar" sign --ks "%B%\debug.keystore" --ks-pass pass:android --ks-key-alias androiddebugkey --out "%B%\H5Pic100.apk" "%B%\unsigned\app-aligned.apk"
if errorlevel 1 goto :fail

java -jar "%BT%\lib\apksigner.jar" verify "%B%\H5Pic100.apk" >nul 2>nul
if errorlevel 1 (
    echo [ERROR] APK signature verification failed.
    goto :fail
)

echo.
echo ============================================
echo  BUILD OK
echo  APK: %B%\H5Pic100.apk
echo ============================================
echo.
echo Install with: adb install -r "%B%\H5Pic100.apk"
echo.
pause
exit /b 0

:fail
echo.
echo ============================================
echo  BUILD FAILED - see errors above
echo ============================================
echo.
pause
exit /b 1
