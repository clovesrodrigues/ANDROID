@echo off
setlocal EnableExtensions EnableDelayedExpansion

for %%V in (ANDROID_HOME ANDROID_SDK_ROOT ANDROID_NDK_HOME JAVA_HOME) do (
  if "!%%V!"=="" (
    echo [ERRO] Variavel %%V nao definida.
    exit /b 1
  )
)

set "PROJ=PROJ1"
set "PKG=com.programadorzero.proj1"
set "ROOT=%~dp0"
set "APP=%ROOT%app"
set "SRC=%APP%\src\main"
set "CPP=%SRC%\cpp"
set "JAVA=%SRC%\java"
set "RES=%SRC%\res"
set "BUILD=%APP%\build"
set "OUT=%APP%\out"
set "OBJ=%BUILD%\obj"
set "CLASSES=%BUILD%\classes"
set "DEX=%BUILD%\dex"
set "UNSIGNED=%OUT%\base.apk"
set "ALIGNED=%OUT%\aligned.apk"
set "FINAL=%ROOT%%PROJ%_Final.apk"
set "MANIFEST=%APP%\AndroidManifest.xml"
set "KEYSTORE=%ROOT%debug.keystore"

if not exist "%BUILD%" mkdir "%BUILD%"
if not exist "%OUT%" mkdir "%OUT%"
if exist "%FINAL%" del /q "%FINAL%"

echo [1/9] Compilando C++ com CMake+Ninja
cmake -S "%CPP%" -B "%OBJ%" -G Ninja -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-26 -DCMAKE_TOOLCHAIN_FILE="%ANDROID_NDK_HOME%\build\cmake\android.toolchain.cmake" -DANDROID_STL=c++_static || exit /b 1
cmake --build "%OBJ%" || exit /b 1

echo [2/9] Compilando Java com javac
if exist "%CLASSES%" rmdir /s /q "%CLASSES%"
mkdir "%CLASSES%"
javac -source 8 -target 8 -d "%CLASSES%" -classpath "%ANDROID_HOME%\platforms\android-35\android.jar" "%JAVA%\com\programadorzero\proj1\MainActivity.java" || exit /b 1

echo [3/9] Convertendo classes para dex com d8
if exist "%DEX%" rmdir /s /q "%DEX%"
mkdir "%DEX%"
d8 --output "%DEX%" "%CLASSES%\com\programadorzero\proj1\MainActivity.class" "%CLASSES%\com\programadorzero\proj1\MainActivity$NativeRenderer.class" || exit /b 1

echo [4/9] Criando APK base com aapt2
if exist "%UNSIGNED%" del /q "%UNSIGNED%"
aapt2 link -I "%ANDROID_HOME%\platforms\android-35\android.jar" --manifest "%MANIFEST%" -R "%RES%\values\strings.xml" -o "%UNSIGNED%" || exit /b 1

echo [5/9] Injetando classes.dex e libnative-lib.so
copy /y "%DEX%\classes.dex" "%OUT%\classes.dex" >nul || exit /b 1
if not exist "%OBJ%\libnative-lib.so" (
  echo [ERRO] libnative-lib.so nao encontrada em %OBJ%\libnative-lib.so
  exit /b 1
)
mkdir "%OUT%\lib\arm64-v8a" 2>nul
copy /y "%OBJ%\libnative-lib.so" "%OUT%\lib\arm64-v8a\libnative-lib.so" >nul || exit /b 1
pushd "%OUT%" >nul
jar uf "%UNSIGNED%" classes.dex lib/arm64-v8a/libnative-lib.so || (popd & exit /b 1)
jar tf "%UNSIGNED%" || (popd & exit /b 1)
popd >nul

echo [6/9] zipalign
zipalign -P 16 -f 4 "%UNSIGNED%" "%ALIGNED%" || exit /b 1
zipalign -c -P 16 4 "%ALIGNED%" || exit /b 1

echo [7/9] Assinatura
if not exist "%KEYSTORE%" (
  keytool -genkeypair -v -keystore "%KEYSTORE%" -alias androiddebugkey -storepass android -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US" || exit /b 1
)
apksigner sign --ks "%KEYSTORE%" --ks-key-alias androiddebugkey --ks-pass pass:android --key-pass pass:android --out "%FINAL%" "%ALIGNED%" || exit /b 1

echo [8/9] Validando assinatura
apksigner verify -v "%FINAL%" || exit /b 1

echo [9/9] Build finalizado: %FINAL%
exit /b 0
