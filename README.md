# ANDROID - Plataforma Android Nativa sem Android Studio

Este repositório implementa uma base **incremental, educacional e reutilizável** para desenvolvimento Android usando:
- C++ (NDK)
- JNI mínimo
- OpenGL ES
- Empacotamento manual de APK
- Scripts `.bat` para Windows `cmd.exe`

> Sem Android Studio, sem Gradle, sem Kotlin, com Java apenas como bootstrap mínimo.

## Estrutura

- `init_project.bat`: gerador inteligente de novos projetos `PROJX`
- `libs/imgui`: reservado para Dear ImGui (PROJ2+)
- `libs/templates`: reservado para templates reutilizáveis
- `PROJ1/`: primeiro projeto de validação da toolchain
- `Androide/`: pasta de trabalho solicitada para próximos trabalhos

## Objetivo do PROJ1

Validar o pipeline completo:
1. C++ + NDK compila
2. Java mínimo compila
3. Geração de DEX com `d8`
4. APK base com `aapt2`
5. Injeção de `classes.dex` e `libnative-lib.so`
6. `zipalign`
7. Assinatura com `apksigner`
8. Instalação com `adb`
9. Execução OpenGL ES com limpeza de tela em cor sólida

## Pré-requisitos (Windows)

Variáveis de ambiente:
- `ANDROID_SDK_ROOT`
- `ANDROID_HOME`
- `ANDROID_NDK_HOME`
- `JAVA_HOME`

Ferramentas no `PATH`:
- `cmake`, `ninja`, `adb`, `aapt2`, `d8`, `zipalign`, `apksigner`, `keytool`, `javac`, `jar`

## Tutorial rápido de uso

### 1) Build do PROJ1
No `cmd.exe` dentro de `D:\ANDROID\PROJ1`:

```bat
build.bat
```

Saída esperada: `PROJ1_Final.apk` na raiz de `PROJ1`.

### 2) Instalação no celular
Com ADB conectado ao Samsung A17:

```bat
install.bat
```

### 3) Logs

```bat
logcat.bat
```

### 4) Resultado visual esperado
Ao abrir o app no telefone, a tela deve abrir com contexto OpenGL ES e mostrar uma cor sólida.

## Criando novos projetos incrementalmente

Na raiz `D:\ANDROID`:

```bat
init_project.bat
```

O script detecta o maior `PROJn` existente e cria `PROJ(n+1)` sem sobrescrever projetos anteriores, incluindo package incremental (`com.programadorzero.projN`) e estrutura inicial.

## Fluxo recomendado

1. Criar projeto com `init_project.bat`
2. Entrar no novo projeto
3. Rodar `build.bat`
4. Rodar `install.bat`
5. Validar execução no celular
6. Acompanhar `logcat.bat`
7. Iterar

## Próxima etapa (PROJ2)

Após validar PROJ1, evoluir para integração de Dear ImGui em C++ mantendo Java mínimo.
