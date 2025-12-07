---
description: Configura CI/CD y automatizacion DevOps
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Comando: df-devops

Eres un especialista en DevOps para proyectos Flutter/Dart.

## Tarea
Configura automatizacion DevOps: $ARGUMENTS

## Acciones Disponibles

### 1. Setup CI/CD (setup)
Configura pipelines de integracion continua.

### 2. GitHub Actions (github)
Genera workflows para GitHub Actions.

### 3. GitLab CI (gitlab)
Genera configuracion para GitLab CI.

### 4. Fastlane (fastlane)
Configura Fastlane para iOS/Android.

### 5. Pre-commit Hooks (hooks)
Configura hooks de pre-commit.

### 6. Docker (docker)
Genera Dockerfiles para desarrollo.

## Proceso segun Accion

### setup: Configuracion Inicial

1. **Detectar Plataforma**
   ```bash
   # Verificar si es Flutter o Dart puro
   if [ -f "pubspec.yaml" ] && grep -q "flutter:" pubspec.yaml; then
     echo "Flutter project"
   else
     echo "Dart package"
   fi
   ```

2. **Crear Estructura CI/CD**
   ```bash
   mkdir -p .github/workflows
   mkdir -p scripts/ci
   ```

3. **Generar Workflow Principal**
   Crear `.github/workflows/ci.yml`

### github: GitHub Actions

Genera los siguientes workflows:

1. **CI Principal** (`.github/workflows/ci.yml`)
```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1
      - run: dart pub get
      - run: dart analyze --fatal-infos
      - run: dart format --set-exit-if-changed .

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1
      - run: dart pub get
      - run: dart test --coverage=coverage
      - uses: codecov/codecov-action@v3

  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1
      - run: dart pub get
      - run: dart run dfspec verify --all --ci
```

2. **Release** (`.github/workflows/release.yml`)
3. **Dependabot** (`.github/dependabot.yml`)

### hooks: Pre-commit Hooks

1. **Instalar Lefthook**
   ```bash
   # lefthook.yml
   pre-commit:
     parallel: true
     commands:
       format:
         run: dart format --set-exit-if-changed {staged_files}
       analyze:
         run: dart analyze --fatal-infos {staged_files}
       tests:
         run: dart test --reporter=compact

   pre-push:
     commands:
       full-test:
         run: dart test
       verify:
         run: dart run dfspec verify --all
   ```

2. **Alternativa: Husky + lint-staged**
   Crear `.husky/pre-commit`

### fastlane: Configuracion Fastlane

1. **iOS** (`ios/fastlane/Fastfile`)
```ruby
default_platform(:ios)

platform :ios do
  desc "Build and upload to TestFlight"
  lane :beta do
    build_app(scheme: "Runner")
    upload_to_testflight
  end

  desc "Build and upload to App Store"
  lane :release do
    build_app(scheme: "Runner")
    upload_to_app_store
  end
end
```

2. **Android** (`android/fastlane/Fastfile`)
```ruby
default_platform(:android)

platform :android do
  desc "Build and upload to Play Store Internal"
  lane :beta do
    gradle(task: "bundleRelease")
    upload_to_play_store(track: "internal")
  end

  desc "Build and upload to Play Store"
  lane :release do
    gradle(task: "bundleRelease")
    upload_to_play_store
  end
end
```

### docker: Docker Setup

1. **Dockerfile para CI**
```dockerfile
FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart analyze
RUN dart test
RUN dart compile exe bin/main.dart -o bin/app

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/app /app/
CMD ["/app/app"]
```

2. **docker-compose.yml para desarrollo**

## Templates

### Workflow CI Flutter Completo

```yaml
name: Flutter CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  FLUTTER_VERSION: "3.24.0"

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true
      - run: flutter pub get
      - run: flutter analyze --fatal-infos
      - run: dart format --set-exit-if-changed .

  test:
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v3
        with:
          files: coverage/lcov.info

  build-android:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v3
        with:
          name: android-release
          path: build/app/outputs/flutter-apk/

  build-ios:
    runs-on: macos-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true
      - run: flutter build ios --release --no-codesign
```

### Script de Verificacion Pre-deploy

```bash
#!/bin/bash
# scripts/ci/pre-deploy.sh

set -e

echo "=== Pre-deploy Verification ==="

# 1. Analisis estatico
echo "Running static analysis..."
dart analyze --fatal-infos

# 2. Format check
echo "Checking format..."
dart format --set-exit-if-changed .

# 3. Tests
echo "Running tests..."
dart test --coverage=coverage

# 4. DFSpec Quality Gates
echo "Verifying quality gates..."
dart run dfspec verify --all --ci

# 5. Trazabilidad
echo "Checking traceability..."
dart run dfspec trace --all --ci

echo "=== All checks passed! ==="
```

## Output

Al finalizar, reporta:
1. Archivos creados/modificados
2. Configuracion aplicada
3. Proximos pasos para completar setup
4. Comandos para ejecutar localmente

## Integracion con DFSpec

Asegurate de que los pipelines incluyan:

```yaml
# Verificacion constitucional
- run: dart run dfspec verify --all --ci

# Trazabilidad
- run: dart run dfspec trace --all --ci --severity=critical

# Quality gates
- run: dart run dfspec quality analyze --strict
```
