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
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

set "APP=%ROOT%\app"
set "SRC=%APP%\src\main"
set "CPP=%SRC%\cpp"
set "JAVA=%SRC%\java"
set "BUILD=%APP%\build"
set "OUT=%APP%\out"
set "OBJ=%BUILD%\obj"
set "CLASSES=%BUILD%\classes"
set "DEX=%BUILD%\dex"
set "PACK=%OUT%\pack"
set "UNSIGNED=%OUT%\base.apk"
set "ALIGNED=%OUT%\aligned.apk"
set "SIGNED_TMP=%OUT%\signed.apk"
set "FINAL=%ROOT%\%PROJ%_Final.apk"
set "MANIFEST=%APP%\AndroidManifest.xml"
set "ANDROID_JAR=%ANDROID_HOME%\platforms\android-36\android.jar"
set "KEYSTORE=%ROOT%\debug.keystore"

if not exist "%BUILD%" mkdir "%BUILD%"
if not exist "%OUT%" mkdir "%OUT%"
if not exist "%OBJ%" mkdir "%OBJ%"
if not exist "%CLASSES%" mkdir "%CLASSES%"
if not exist "%DEX%" mkdir "%DEX%"
if not exist "%PACK%" mkdir "%PACK%"

echo [1/9] Compilando C++ com CMake + Ninja
cmake -S "%CPP%" -B "%OBJ%" -G Ninja -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-26 -DCMAKE_TOOLCHAIN_FILE="%ANDROID_NDK_HOME%\build\cmake\android.toolchain.cmake" -DANDROID_STL=c++_static || exit /b 1
cmake --build "%OBJ%" || exit /b 1

echo [2/9] Compilando Java com javac
if exist "%CLASSES%" rmdir /s /q "%CLASSES%"
mkdir "%CLASSES%"
javac -source 8 -target 8 -d "%CLASSES%" -classpath "%ANDROID_JAR%" "%JAVA%\com\programadorzero\proj1\MainActivity.java" || exit /b 1

echo [3/9] Convertendo classes para DEX com d8
if exist "%DEX%" rmdir /s /q "%DEX%"
mkdir "%DEX%"
d8 --output "%DEX%" "%CLASSES%\com\programadorzero\proj1\MainActivity.class" "%CLASSES%\com\programadorzero\proj1\MainActivity$NativeRenderer.class" || exit /b 1
if not exist "%DEX%\classes.dex" (
  echo [ERRO] classes.dex nao foi gerado.
  exit /b 1
)

echo [4/9] Gerando base.apk com aapt2 link (android-36)
if not exist "%ANDROID_JAR%" (
  echo [ERRO] android.jar nao encontrado em: %ANDROID_JAR%
  exit /b 1
)
if exist "%UNSIGNED%" del /q "%UNSIGNED%"
aapt2 link -I "%ANDROID_JAR%" --manifest "%MANIFEST%" -o "%UNSIGNED%" || exit /b 1

echo [5/9] Injetando classes.dex e libnative-lib.so
set "LIB_NATIVE="
for /f "delims=" %%F in ('where /r "%BUILD%" libnative-lib.so 2^>nul') do (
  set "LIB_NATIVE=%%F"
  goto :lib_found
)
:lib_found
if "!LIB_NATIVE!"=="" (
  echo [ERRO] libnative-lib.so nao encontrada dentro de: %BUILD%
  exit /b 1
)
echo [INFO] libnative-lib.so encontrada em: !LIB_NATIVE!

if exist "%PACK%" rmdir /s /q "%PACK%"
mkdir "%PACK%\lib\arm64-v8a"
copy /y "%DEX%\classes.dex" "%PACK%\classes.dex" >nul || exit /b 1
copy /y "!LIB_NATIVE!" "%PACK%\lib\arm64-v8a\libnative-lib.so" >nul || exit /b 1
copy /y "%UNSIGNED%" "%OUT%\inject.apk" >nul || exit /b 1

pushd "%PACK%" >nul
jar uf "%OUT%\inject.apk" classes.dex lib/arm64-v8a/libnative-lib.so || (popd & exit /b 1)
popd >nul

echo [INFO] Conteudo do APK apos injecao (jar tf):
jar tf "%OUT%\inject.apk" || exit /b 1

echo [6/9] Executando zipalign
if exist "%ALIGNED%" del /q "%ALIGNED%"
zipalign -P 16 -f 4 "%OUT%\inject.apk" "%ALIGNED%" || exit /b 1
echo [INFO] Validando zipalign
zipalign -c -P 16 4 "%ALIGNED%" || exit /b 1

echo [7/9] Assinando APK com apksigner
if not exist "%KEYSTORE%" (
  echo [INFO] debug.keystore nao existe, gerando automaticamente...
  keytool -genkeypair -v -keystore "%KEYSTORE%" -alias androiddebugkey -storepass android -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US" || exit /b 1
)
if exist "%SIGNED_TMP%" del /q "%SIGNED_TMP%"
apksigner sign --ks "%KEYSTORE%" --ks-key-alias androiddebugkey --ks-pass pass:android --key-pass pass:android --out "%SIGNED_TMP%" "%ALIGNED%" || exit /b 1

echo [8/9] Verificando assinatura
apksigner verify -v "%SIGNED_TMP%" || exit /b 1

echo [9/9] Publicando APK final na raiz do projeto
copy /y "%SIGNED_TMP%" "%FINAL%" >nul || exit /b 1
if not exist "%FINAL%" (
  echo [ERRO] Falha ao gerar APK final em: %FINAL%
  exit /b 1
)

echo [SUCESSO] APK final gerado em:
echo %FINAL%
exit /b 0
