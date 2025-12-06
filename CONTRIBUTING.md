# Contribuir a DFSpec

Gracias por tu interes en contribuir a DFSpec! Este documento proporciona guias para contribuir al proyecto.

## Codigo de Conducta

Este proyecto sigue un codigo de conducta. Al participar, se espera que mantengas este codigo.

## Como Contribuir

### Reportar Bugs

1. Verifica que el bug no haya sido reportado previamente
2. Abre un issue con:
   - Descripcion clara del problema
   - Pasos para reproducir
   - Comportamiento esperado vs actual
   - Version de Dart/Flutter
   - Sistema operativo

### Sugerir Features

1. Abre un issue con la etiqueta `enhancement`
2. Describe la feature y su caso de uso
3. Explica por que seria util para otros usuarios

### Pull Requests

1. Fork el repositorio
2. Crea una rama desde `main`:
   ```bash
   git checkout -b feature/mi-feature
   ```
3. Haz tus cambios siguiendo las guias de estilo
4. Asegurate de que los tests pasen:
   ```bash
   dart test
   dart analyze
   ```
5. Commit con mensaje descriptivo:
   ```bash
   git commit -m "feat: descripcion de la feature"
   ```
6. Push y abre un PR

## Guias de Estilo

### Codigo Dart

- Seguir [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Usar `very_good_analysis` para linting
- Ejecutar `dart format .` antes de commit

### Commits

Seguir [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` Nueva feature
- `fix:` Correccion de bug
- `docs:` Documentacion
- `test:` Tests
- `refactor:` Refactorizacion
- `chore:` Mantenimiento

### Tests

- Escribir tests para todo codigo nuevo
- Mantener cobertura >85%
- Usar patron AAA (Arrange-Act-Assert)
- Nombres de tests descriptivos en espanol

## Estructura del Proyecto

```
dfspec-ia/
├── .claude/commands/    # Slash commands (core)
├── lib/src/
│   ├── commands/        # CLI commands
│   ├── generators/      # Spec generators
│   ├── models/          # Data models
│   ├── templates/       # Templates
│   └── utils/           # Utilities
├── test/                # Tests
├── docs/                # Documentation
├── memory/              # Constitution
└── templates/           # User templates
```

## Desarrollo Local

```bash
# Clonar
git clone git@github.com:juansuarez-pragma/dfspec-ai.git
cd dfspec-ai

# Instalar dependencias
dart pub get

# Ejecutar tests
dart test

# Analisis estatico
dart analyze

# Ejecutar CLI localmente
dart run bin/dfspec.dart --help
```

## Preguntas?

Abre un issue con la etiqueta `question`.
