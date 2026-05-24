@echo off
setlocal EnableExtensions EnableDelayedExpansion

where cmd >nul 2>nul || (
  echo [ERRO] Este script deve ser executado no cmd.exe.
  exit /b 1
)

for %%V in (ANDROID_SDK_ROOT ANDROID_HOME ANDROID_NDK_HOME JAVA_HOME) do (
  if "!%%V!"=="" (
    echo [ERRO] Variavel %%V nao definida.
    exit /b 1
  )
)

set "ROOT=%~dp0"
pushd "%ROOT%" >nul

set /a MAX=0
for /d %%D in (PROJ*) do (
  set "NAME=%%~nD"
  set "NUM=!NAME:~4!"
  for /f "delims=0123456789" %%X in ("!NUM!") do set "NUM_INVALID=%%X"
  if not defined NUM_INVALID if not "!NUM!"=="" (
    if !NUM! GTR !MAX! set /a MAX=!NUM!
  )
  set "NUM_INVALID="
)

set /a NEXT=MAX+1
set "PROJ=PROJ!NEXT!"
set "PKG=com.programadorzero.proj!NEXT!"
set "PKG_PATH=com\programadorzero\proj!NEXT!"

if exist "%PROJ%" (
  echo [ERRO] Pasta %PROJ% ja existe. Abortando.
  popd >nul
  exit /b 1
)

echo [INFO] Criando %PROJ% com package %PKG%

mkdir "%PROJ%\app\src\main\cpp" || goto :fail
mkdir "%PROJ%\app\src\main\java\%PKG_PATH%" || goto :fail
mkdir "%PROJ%\app\src\main\res\values" || goto :fail
mkdir "%PROJ%\app\build" || goto :fail
mkdir "%PROJ%\app\out" || goto :fail

call :write_manifest "%PROJ%\app\AndroidManifest.xml" "%PKG%" || goto :fail
call :write_strings "%PROJ%\app\src\main\res\values\strings.xml" "%PROJ%" || goto :fail
call :write_activity "%PROJ%\app\src\main\java\%PKG_PATH%\MainActivity.java" "%PKG%" || goto :fail
call :write_cmake "%PROJ%\app\src\main\cpp\CMakeLists.txt" || goto :fail
call :write_engine_h "%PROJ%\app\src\main\cpp\engine.h" || goto :fail
call :write_engine_cpp "%PROJ%\app\src\main\cpp\engine.cpp" || goto :fail
call :write_renderer_h "%PROJ%\app\src\main\cpp\renderer.h" || goto :fail
call :write_renderer_cpp "%PROJ%\app\src\main\cpp\renderer.cpp" || goto :fail
call :write_main_cpp "%PROJ%\app\src\main\cpp\main.cpp" "%PKG%" || goto :fail
call :write_build "%PROJ%\build.bat" "%PROJ%" "%PKG%" || goto :fail
call :write_install "%PROJ%\install.bat" "%PROJ%" || goto :fail
call :write_logcat "%PROJ%\logcat.bat" || goto :fail
call :write_readme "%PROJ%\README.txt" "%PROJ%" "%PKG%" || goto :fail

echo [INFO] %PROJ% criado com sucesso.
popd >nul
exit /b 0

:fail
echo [ERRO] Falha ao criar o projeto.
popd >nul
exit /b 1

:write_manifest
>"%~1" (
  echo ^<?xml version="1.0" encoding="utf-8"?^>
  echo ^<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="%~2"^>
  echo   ^<uses-sdk android:minSdkVersion="26" android:targetSdkVersion="35" /^>
  echo   ^<uses-feature android:glEsVersion="0x00030000" android:required="true" /^>
  echo   ^<application android:label="@string/app_name" android:hasCode="true"^>
  echo     ^<activity android:name=".MainActivity" android:exported="true"^>
  echo       ^<intent-filter^>
  echo         ^<action android:name="android.intent.action.MAIN" /^>
  echo         ^<category android:name="android.intent.category.LAUNCHER" /^>
  echo       ^</intent-filter^>
  echo     ^</activity^>
  echo   ^</application^>
  echo ^</manifest^>
)
exit /b 0

:write_strings
>"%~1" (
  echo ^<?xml version="1.0" encoding="utf-8"?^>
  echo ^<resources^>
  echo     ^<string name="app_name"^>%~2^</string^>
  echo ^</resources^>
)
exit /b 0

:write_activity
>"%~1" (
  echo package %~2;
  echo.
  echo import android.app.Activity;
  echo import android.opengl.GLSurfaceView;
  echo import android.os.Bundle;
  echo.
  echo public class MainActivity extends Activity {
  echo     static { System.loadLibrary("native-lib"); }
  echo.
  echo     @Override
  echo     protected void onCreate(Bundle savedInstanceState) {
  echo         super.onCreate(savedInstanceState);
  echo         GLSurfaceView view = new GLSurfaceView(this);
  echo         view.setEGLContextClientVersion(3);
  echo         view.setRenderer(new NativeRenderer());
  echo         setContentView(view);
  echo     }
  echo.
  echo     private static class NativeRenderer implements GLSurfaceView.Renderer {
  echo         public native void nativeOnSurfaceCreated();
  echo         public native void nativeOnSurfaceChanged(int width, int height);
  echo         public native void nativeOnDrawFrame();
  echo.
  echo         @Override public void onSurfaceCreated(javax.microedition.khronos.opengles.GL10 gl, javax.microedition.khronos.egl.EGLConfig config) { nativeOnSurfaceCreated(); }
  echo         @Override public void onSurfaceChanged(javax.microedition.khronos.opengles.GL10 gl, int width, int height) { nativeOnSurfaceChanged(width, height); }
  echo         @Override public void onDrawFrame(javax.microedition.khronos.opengles.GL10 gl) { nativeOnDrawFrame(); }
  echo     }
  echo }
)
exit /b 0

:write_cmake
>"%~1" (
  echo cmake_minimum_required(VERSION 3.22.1)
  echo project(native_proj)
  echo add_library(native-lib SHARED main.cpp engine.cpp renderer.cpp)
  echo target_include_directories(native-lib PRIVATE .)
  echo find_library(log-lib log)
  echo find_library(android-lib android)
  echo find_library(egl-lib EGL)
  echo find_library(gles-lib GLESv3)
  echo target_link_libraries(native-lib ^${log-lib} ^${android-lib} ^${egl-lib} ^${gles-lib})
)
exit /b 0

:write_engine_h
>"%~1" (
  echo #pragma once
  echo namespace engine { void on_surface_created(); void on_surface_changed(int w, int h); void on_draw_frame(); }
)
exit /b 0
:write_engine_cpp
>"%~1" (
  echo #include "engine.h"
  echo #include "renderer.h"
  echo namespace engine { void on_surface_created(){renderer::init();} void on_surface_changed(int w,int h){renderer::resize(w,h);} void on_draw_frame(){renderer::draw();} }
)
exit /b 0
:write_renderer_h
>"%~1" (
  echo #pragma once
  echo namespace renderer { void init(); void resize(int w, int h); void draw(); }
)
exit /b 0
:write_renderer_cpp
>"%~1" (
  echo #include "renderer.h"
  echo #include ^<GLES3/gl3.h^>
  echo namespace renderer {
  echo static float r=0.08f,g=0.11f,b=0.18f;
  echo void init(){ glClearColor(r,g,b,1.0f); }
  echo void resize(int w,int h){ glViewport(0,0,w,h); }
  echo void draw(){ glClear(GL_COLOR_BUFFER_BIT); }
  echo }
)
exit /b 0
:write_main_cpp
>"%~1" (
  echo #include ^<jni.h^>
  echo #include "engine.h"
  echo extern "C" JNIEXPORT void JNICALL Java_com_programadorzero_proj%NEXT%_MainActivity_00024NativeRenderer_nativeOnSurfaceCreated(JNIEnv*, jobject){engine::on_surface_created();}
  echo extern "C" JNIEXPORT void JNICALL Java_com_programadorzero_proj%NEXT%_MainActivity_00024NativeRenderer_nativeOnSurfaceChanged(JNIEnv*, jobject, jint w, jint h){engine::on_surface_changed((int)w,(int)h);}
  echo extern "C" JNIEXPORT void JNICALL Java_com_programadorzero_proj%NEXT%_MainActivity_00024NativeRenderer_nativeOnDrawFrame(JNIEnv*, jobject){engine::on_draw_frame();}
)
exit /b 0
:write_build
>"%~1" (
  echo @echo off
  echo setlocal EnableExtensions EnableDelayedExpansion
  echo for %%V in (ANDROID_HOME ANDROID_NDK_HOME JAVA_HOME) do ^( if "!%%V!"=="" ^( echo [ERRO] Variavel %%V nao definida. ^& exit /b 1 ^) ^)
  echo set "PROJ=%~2"
  echo set "PKG=%~3"
  echo set "ROOT=%%~dp0"
  echo set "APP=%%ROOT%%app"
  echo set "SRC=%%APP%%\src\main"
  echo set "CPP=%%SRC%%\cpp"
  echo set "JAVA=%%SRC%%\java"
  echo set "BUILD=%%APP%%\build"
  echo set "OUT=%%APP%%\out"
  echo set "APK_BASE=%%OUT%%\base.apk"
  echo set "APK_ALIGN=%%OUT%%\aligned.apk"
  echo set "APK_SIGNED=%%ROOT%%%%PROJ%%_Final.apk"
  echo if not exist "%%BUILD%%" mkdir "%%BUILD%%"
  echo if not exist "%%OUT%%" mkdir "%%OUT%%"
  echo echo [1/9] CMake + Ninja
  echo cmake -S "%%CPP%%" -B "%%BUILD%%\cmake" -G Ninja -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-26 -DCMAKE_TOOLCHAIN_FILE="%%ANDROID_NDK_HOME%%\build\cmake\android.toolchain.cmake" -DANDROID_STL=c++_static || exit /b 1
  echo cmake --build "%%BUILD%%\cmake" || exit /b 1
  echo echo [2/9] javac
  echo if exist "%%BUILD%%\classes" rmdir /s /q "%%BUILD%%\classes"
  echo mkdir "%%BUILD%%\classes"
  echo javac -source 8 -target 8 -d "%%BUILD%%\classes" -classpath "%%ANDROID_HOME%%\platforms\android-35\android.jar" "%%JAVA%%\com\programadorzero\%~2\MainActivity.java" || exit /b 1
)
exit /b 0
:write_install
>"%~1" echo @echo off&&echo adb install -r "%~2_Final.apk"
exit /b 0
:write_logcat
>"%~1" echo @echo off&&echo adb logcat ^| findstr programadorzero
exit /b 0
:write_readme
>"%~1" (
 echo %~2 - bootstrap Android C++ OpenGL ES
 echo.
 echo Package: %~3
 echo.
 echo Use build.bat para gerar APK assinado.
 echo Use install.bat para instalar no dispositivo.
 echo Use logcat.bat para filtrar logs.
)
exit /b 0
