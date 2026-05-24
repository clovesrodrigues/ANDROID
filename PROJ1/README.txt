PROJ1 - Validacao da Toolchain Android sem Android Studio

Objetivo:
- Compilar C++ (JNI + OpenGL ES)
- Empacotar APK manualmente
- Assinar e instalar em dispositivo real

Estrutura:
- app/src/main/cpp: codigo C++ principal
- app/src/main/java: bootstrap Java minimo
- app/src/main/res: recursos minimos
- build.bat: pipeline completo de build
- install.bat: instala APK via adb
- logcat.bat: logs filtrados por programadorzero

Uso:
1) build.bat
2) install.bat
3) logcat.bat
