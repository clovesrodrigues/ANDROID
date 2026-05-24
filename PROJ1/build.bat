@echo off
setlocal EnableExtensions EnableDelayedExpansion

for %%V in (ANDROID_HOME ANDROID_SDK_ROOT ANDROID_NDK_HOME JAVA_HOME) do (
  if "!%%V!"=="" (
    echo [ERRO] Variavel %%V nao definida.
    exit /b 1
  )
)

set "PROJ=PROJ1"
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
set "INJECT=%OUT%\inject.apk"
set "ALIGNED=%OUT%\aligned.apk"
set "SIGNED_TMP=%OUT%\signed.apk"
set "FINAL=%ROOT%\%PROJ%_Final.apk"
set "MANIFEST=%APP%\AndroidManifest.xml"
set "ANDROID_JAR=%ANDROID_HOME%\platforms\android-36\android.jar"
set "KEYSTORE=%ROOT%\debug.keystore"
set "JAVA_MAIN=%JAVA%\com\programadorzero\proj1\MainActivity.java"
set "CLASS_MAIN=%CLASSES%\com\programadorzero\proj1\MainActivity.class"
set "CLASS_RENDERER=%CLASSES%\com\programadorzero\proj1\MainActivity$NativeRenderer.class"
set "LIB_NATIVE="

if not exist "%BUILD%" mkdir "%BUILD%"
if not exist "%OUT%" mkdir "%OUT%"

echo ============================================================
echo [1/9] CMake + Ninja
echo ============================================================
echo [DEBUG] CPP source: %CPP%
echo [DEBUG] CMake build dir: %OBJ%
cmake -S "%CPP%" -B "%OBJ%" -G Ninja -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-26 -DCMAKE_TOOLCHAIN_FILE="%ANDROID_NDK_HOME%\build\cmake\android.toolchain.cmake" -DANDROID_STL=c++_static
if errorlevel 1 (
  echo [ERRO] Comando CMake configure/build system falhou.
  exit /b 1
)
cmake --build "%OBJ%"
if errorlevel 1 (
  echo [ERRO] Comando CMake build falhou.
  exit /b 1
)
echo [DEBUG] Procurando libnative-lib.so em: %BUILD%
dir /s /b "%BUILD%\libnative-lib.so"
for /f "delims=" %%F in ('dir /s /b "%BUILD%\libnative-lib.so" 2^>nul') do (
  set "LIB_NATIVE=%%F"
  goto :lib_found
)
:lib_found
if "!LIB_NATIVE!"=="" (
  echo [ERRO] Arquivo esperado nao encontrado: libnative-lib.so
  echo [ERRO] Caminho pesquisado: %BUILD%
  exit /b 1
)
echo [DEBUG] libnative-lib.so encontrada: !LIB_NATIVE!

echo ============================================================
echo [2/9] javac
echo ============================================================
echo [DEBUG] Java source: %JAVA_MAIN%
echo [DEBUG] Classes dir: %CLASSES%
if exist "%CLASSES%" rmdir /s /q "%CLASSES%"
mkdir "%CLASSES%"
javac -source 8 -target 8 -d "%CLASSES%" -classpath "%ANDROID_JAR%" "%JAVA_MAIN%"
if errorlevel 1 (
  echo [ERRO] Comando javac falhou.
  exit /b 1
)
if not exist "%CLASS_MAIN%" (
  echo [ERRO] Arquivo esperado ausente: %CLASS_MAIN%
  exit /b 1
)
if not exist "%CLASS_RENDERER%" (
  echo [ERRO] Arquivo esperado ausente: %CLASS_RENDERER%
  exit /b 1
)
echo [DEBUG] Classes geradas com sucesso.

echo ============================================================
echo [3/9] d8
echo ============================================================
echo [DEBUG] Input classes: %CLASS_MAIN% e %CLASS_RENDERER%
echo [DEBUG] Output dex dir: %DEX%
if exist "%DEX%" rmdir /s /q "%DEX%"
mkdir "%DEX%"
d8 --output "%DEX%" "%CLASS_MAIN%" "%CLASS_RENDERER%"
if errorlevel 1 (
  echo [ERRO] Comando d8 falhou.
  exit /b 1
)
echo [DEBUG] Conteudo de %DEX%:
dir /a /s "%DEX%"
if not exist "%DEX%\classes.dex" (
  echo [ERRO] Arquivo esperado ausente: %DEX%\classes.dex
  exit /b 1
)

echo ============================================================
echo [4/9] aapt2 link
echo ============================================================
echo [DEBUG] android.jar: %ANDROID_JAR%
echo [DEBUG] Manifest: %MANIFEST%
echo [DEBUG] Saida base.apk: %UNSIGNED%
if not exist "%ANDROID_JAR%" (
  echo [ERRO] android.jar nao encontrado: %ANDROID_JAR%
  exit /b 1
)
if exist "%UNSIGNED%" del /q "%UNSIGNED%"
aapt2 link -I "%ANDROID_JAR%" --manifest "%MANIFEST%" -o "%UNSIGNED%"
if errorlevel 1 (
  echo [ERRO] Comando aapt2 link falhou.
  exit /b 1
)
if not exist "%UNSIGNED%" (
  echo [ERRO] Arquivo esperado ausente: %UNSIGNED%
  exit /b 1
)
for %%A in ("%UNSIGNED%") do echo [DEBUG] base.apk tamanho: %%~zA bytes

echo ============================================================
echo [5/9] jar uf (injecao)
echo ============================================================
echo [DEBUG] Preparando estrutura pack em: %PACK%
if exist "%PACK%" rmdir /s /q "%PACK%"
mkdir "%PACK%\lib\arm64-v8a"
copy /y "%DEX%\classes.dex" "%PACK%\classes.dex" >nul
if errorlevel 1 (
  echo [ERRO] Falha copiando classes.dex para pack.
  exit /b 1
)
copy /y "!LIB_NATIVE!" "%PACK%\lib\arm64-v8a\libnative-lib.so" >nul
if errorlevel 1 (
  echo [ERRO] Falha copiando libnative-lib.so para pack.
  echo [ERRO] Origem: !LIB_NATIVE!
  exit /b 1
)
echo [DEBUG] Estrutura pack:
dir /s "%PACK%"

copy /y "%UNSIGNED%" "%INJECT%" >nul
if errorlevel 1 (
  echo [ERRO] Falha criando inject.apk.
  exit /b 1
)
if not exist "%INJECT%" (
  echo [ERRO] inject.apk nao existe: %INJECT%
  exit /b 1
)
echo [DEBUG] inject.apk existe antes do jar: %INJECT%

pushd "%PACK%" >nul
jar uf "%INJECT%" classes.dex lib/arm64-v8a/libnative-lib.so
set "JAR_ERR=!ERRORLEVEL!"
popd >nul
if not "%JAR_ERR%"=="0" (
  echo [ERRO] Comando jar uf falhou com codigo %JAR_ERR%.
  exit /b 1
)

echo [DEBUG] jar tf %INJECT%:
jar tf "%INJECT%"
if errorlevel 1 (
  echo [ERRO] Comando jar tf falhou.
  exit /b 1
)
jar tf "%INJECT%" | findstr /x /c:"classes.dex" >nul
if errorlevel 1 (
  echo [ERRO] Entrada classes.dex nao encontrada no APK apos jar uf.
  exit /b 1
)
jar tf "%INJECT%" | findstr /x /c:"lib/arm64-v8a/libnative-lib.so" >nul
if errorlevel 1 (
  echo [ERRO] Entrada lib/arm64-v8a/libnative-lib.so nao encontrada no APK apos jar uf.
  exit /b 1
)
echo [DEBUG] Validacao de entradas do APK OK.

echo ============================================================
echo [6/9] zipalign
echo ============================================================
echo [DEBUG] Entrada zipalign: %INJECT%
echo [DEBUG] Saida zipalign: %ALIGNED%
if exist "%ALIGNED%" del /q "%ALIGNED%"
zipalign -P 16 -f 4 "%INJECT%" "%ALIGNED%"
if errorlevel 1 (
  echo [ERRO] Comando zipalign falhou.
  exit /b 1
)
if not exist "%ALIGNED%" (
  echo [ERRO] Arquivo esperado ausente: %ALIGNED%
  exit /b 1
)
echo [DEBUG] zipalign -c resultado:
zipalign -c -P 16 4 "%ALIGNED%"
if errorlevel 1 (
  echo [ERRO] Validacao zipalign -c falhou.
  exit /b 1
)

echo ============================================================
echo [7/9] apksigner sign
echo ============================================================
echo [DEBUG] Keystore: %KEYSTORE%
if not exist "%KEYSTORE%" (
  echo [INFO] debug.keystore nao existe. Gerando automaticamente...
  keytool -genkeypair -v -keystore "%KEYSTORE%" -alias androiddebugkey -storepass android -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
  if errorlevel 1 (
    echo [ERRO] Falha ao gerar debug.keystore.
    exit /b 1
  )
)
if exist "%SIGNED_TMP%" del /q "%SIGNED_TMP%"
apksigner sign --ks "%KEYSTORE%" --ks-key-alias androiddebugkey --ks-pass pass:android --key-pass pass:android --out "%SIGNED_TMP%" "%ALIGNED%"
if errorlevel 1 (
  echo [ERRO] Comando apksigner sign falhou.
  exit /b 1
)
if not exist "%SIGNED_TMP%" (
  echo [ERRO] Arquivo esperado ausente: %SIGNED_TMP%
  exit /b 1
)
for %%A in ("%SIGNED_TMP%") do echo [DEBUG] signed.apk tamanho: %%~zA bytes

echo ============================================================
echo [8/9] apksigner verify -v
echo ============================================================
apksigner verify -v "%SIGNED_TMP%"
if errorlevel 1 (
  echo [ERRO] apksigner verify falhou para: %SIGNED_TMP%
  exit /b 1
)

echo ============================================================
echo [9/9] Publicacao final

echo ============================================================
copy /y "%SIGNED_TMP%" "%FINAL%" >nul
if errorlevel 1 (
  echo [ERRO] Falha ao copiar signed.apk para final.
  echo [ERRO] Origem: %SIGNED_TMP%
  echo [ERRO] Destino: %FINAL%
  exit /b 1
)
if not exist "%FINAL%" (
  echo [ERRO] APK final nao encontrado: %FINAL%
  exit /b 1
)
for %%A in ("%FINAL%") do echo [SUCESSO] APK final: %FINAL% ^| tamanho: %%~zA bytes

exit /b 0
