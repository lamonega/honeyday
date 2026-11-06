---
name: flutter-testing
description: Diseña o modifica pruebas unitarias, de repositorios, widgets y golden Flutter, incluidos casos visuales multiplataforma.
---

# Pruebas Flutter

1. Elige el nivel más pequeño que cubra el comportamiento: unitario para lógica, mapeos y repositorios; widget para interfaz e interacción; golden para regresiones visuales.
2. Organiza cada caso en preparación, acción y comprobación. Cubre estados de error y ciclo de vida cuando sean relevantes. Sigue los dobles y helpers existentes; no presupongas que Mocktail esté instalado.
3. Para golden, sigue las pruebas existentes con Alchemist y contempla las variantes Windows/CI. No actualices imágenes de referencia sin revisar el cambio visual y la plataforma.
4. Ejecuta las pruebas afectadas y la suite indicada en `AGENTS.md` cuando sea viable. Los benchmarks de exportación requieren ejecución explícita según README.

## Referencias

Para la pirámide y herramientas de pruebas, lee [testing.md](references/testing.md).
- Para el ejemplo completo de Mocktail y AAA, lee [unit-tests.md](references/unit-tests.md).
- Para el ejemplo completo de Alchemist, lee [golden-tests.md](references/golden-tests.md).
