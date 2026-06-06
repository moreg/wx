@echo off
setlocal

set "ROOT=%~dp0"
set "ANDROID_DIR=%ROOT%android"
set "LOCAL_PROPERTIES=%ANDROID_DIR%\local.properties"

pushd "%ROOT%" >nul

rem Java Properties files are ISO-8859-1 by default, so keep Chinese path
rem segments escaped for Gradle.
(
  echo sdk.dir=E:/minimax\u9879\u76ee/\u73af\u5883/android-sdk
  echo flutter.sdk=E:/minimax\u9879\u76ee/\u73af\u5883/flutter
  echo flutter.buildMode=debug
  echo flutter.versionName=1.0.0
  echo flutter.versionCode=1
) > "%LOCAL_PROPERTIES%"

pushd "%ANDROID_DIR%" >nul
call gradlew.bat assembleDebug
set "BUILD_EXIT=%ERRORLEVEL%"
popd >nul

if not "%BUILD_EXIT%"=="0" (
  echo.
  echo Build failed with exit code %BUILD_EXIT%.
  popd >nul
  exit /b %BUILD_EXIT%
)

echo.
echo Build successful:
echo %ROOT%build\app\outputs\apk\debug\app-debug.apk

popd >nul
endlocal
