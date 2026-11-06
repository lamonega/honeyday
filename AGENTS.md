# Instrucciones para agentes

## Proyecto y estructura

Honeyday es una agenda y diario multiplataforma en Flutter, con Riverpod, GoRouter y persistencia local Drift. Revisa el código existente antes de cambiar sus patrones.

- `lib/app/`: aplicación, navegación y tema.
- `lib/core/`: infraestructura y componentes compartidos.
- `lib/features/`: funcionalidades, habitualmente organizadas en dominio, datos y presentación.
- `test/`: pruebas; `assets/`: recursos; `pubspec.yaml`: dependencias.

## Comandos

Desde la raíz, según README y CI:

- Instala dependencias: `flutter pub get`.
- Genera código Drift cuando corresponda: `dart run build_runner build --delete-conflicting-outputs` (puede sobrescribir archivos generados).
- Ejecuta la aplicación: `flutter run`.
- Analiza: `dart analyze --fatal-infos` (CI también rechaza avisos informativos).
- Ejecuta pruebas: `flutter test`.
- Compila Web (JavaScript, como CI): `flutter build web --no-pub --no-wasm-dry-run` después de instalar dependencias.
- Formatea los archivos modificados: `dart format <rutas>`. Evita reformatear archivos ajenos al cambio.

La generación Drift no equivale a compilar la aplicación. No hay builds nativos de release verificados en CI.

CI usa Flutter 3.47.5: análisis y pruebas en Windows, build JavaScript Web en Linux. Los golden tienen variantes para Windows y CI; no actualices sus imágenes sin revisión visual. Los benchmarks de exportación están excluidos de la ejecución normal; consulta README para ejecutarlos explícitamente.

En entornos con recursos limitados, ejecuta análisis, pruebas y build de forma secuencial. `flutter test --concurrency=2` reduce la presión de recursos.

## Estado funcional y continuidad

- `docs/backups.md`: formato, alcance y privacidad de los backups editables; importar crea copias sin reemplazar datos existentes.
- `docs/roadmap.md`: entregas incorporadas, límites conocidos y próximos trabajos. PDF todavía no incluye tinta; backup sí.
- Antes de una release, verifica manualmente los diálogos de archivos, compartir, lápiz y cierre en las plataformas objetivo.

## Convenciones y límites

- Sigue `analysis_options.yaml` y las convenciones locales; mantén los cambios acotados y comprensibles. Usa nombres Dart idiomáticos, funciones pequeñas, retornos tempranos y `const` cuando corresponda.
- Separa responsabilidades y evita acoplar la UI a detalles de persistencia. Respeta las excepciones y patrones existentes antes de introducir una abstracción.
- No edites manualmente archivos generados; revisa el efecto de regenerarlos. No incluyas secretos ni credenciales en cambios.
- No reescribas ni elimines cambios ajenos; pide confirmación antes de operaciones destructivas o cambios de alcance no solicitados.

## Skills disponibles

- [Arquitectura y repositorios](.agents/skills/flutter-architecture/SKILL.md): cambios en capas, contratos, DTOs y persistencia.
- [Estado Riverpod](.agents/skills/riverpod-state/SKILL.md): proveedores, estado asíncrono y ciclo de vida.
- [Widgets Flutter](.agents/skills/flutter-widgets/SKILL.md): componentes de presentación reutilizables.
- [Navegación adaptable](.agents/skills/flutter-navigation/SKILL.md): rutas GoRouter y adaptación de navegación.
- [Pruebas Flutter](.agents/skills/flutter-testing/SKILL.md): pruebas unitarias, widgets y golden.
- [Estilo y análisis Dart](.agents/skills/dart-craftsmanship/SKILL.md): estilo, diseño y análisis estático.
