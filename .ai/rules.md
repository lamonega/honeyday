# Honeyday - Reglas de Arquitectura y Desarrollo para Agentes de IA

Este documento establece los estándares de ingeniería y diseño para el desarrollo de Honeyday en Flutter. Cualquier agente o desarrollador que modifique o extienda este proyecto debe seguir estas directrices sin excepción.

---

## 1. Soporte Multiplataforma (Cross-Platform)

Honeyday está diseñado para ejecutarse en **6 plataformas**: Android, iOS, Windows, macOS, Linux y Web.

* **Abstracción de I/O y Red:**
  * **NUNCA** importar directamente `dart:io` en capas de UI o lógica compartida (falla en Web).
  * Usar abstracciones multiplataforma: `path_provider`, `shared_preferences`, `dio`.
* **Diseño Responsivo y Adaptativo:**
  * Usar breakpoints Material 3 estándar:
    * **Compact** (< 600 dp): Teléfonos (NavigationBars, layouts en columna).
    * **Medium** (600 - 840 dp): Tablets y pantallas pequeñas (NavigationRail).
    * **Expanded** (> 840 dp): Desktop y Web (NavigationRail / Permanent Drawer, layouts multi-columna).
  * Emplear `LayoutBuilder` y `MediaQuery.sizeOf(context)` en lugar de `MediaQuery.of(context)` para evitar reconstrucciones innecesarias.
* **Interacciones Desktop y Web:**
  * Soportar cursores de mouse (`MouseRegion`), hover effects, scroll suave con rueda del mouse y atajos de teclado (`Shortcuts` / `Actions`).
* **Navegación Web y Deep Linking:**
  * Toda la navegación debe gestionarse mediante `go_router` declarativo, asegurando soporte para la barra de URLs del navegador, botón "Atrás" y redirección basada en estado.

---

## 2. Arquitectura del Proyecto (Feature-First)

El proyecto sigue una estructura orientada a features (**Feature-First**) con separación de responsabilidades:

```text
lib/
├── app/                  # Configuración global de la app (router, tema, providers globales)
│   ├── app.dart
│   ├── router.dart
│   └── theme.dart
├── core/                 # Utilidades compartidas, constantes, extensiones y clientes de red
│   ├── constants/
│   ├── network/
│   └── utils/
└── features/             # Módulos funcionales de la aplicación
    └── [feature_name]/
        ├── data/         # Fuentes de datos (API/Local) y repositorios
        ├── domain/       # Modelos de negocio inmutables y reglas de dominio
        └── presentation/ # Widgets, páginas y controladores de estado (Riverpod)
```

---

## 3. Manejo de Estado (Riverpod)

* Usar **`flutter_riverpod`** como el estándar de gestión de estado e inyección de dependencias.
* Separar la vista de la lógica: los widgets no deben contener lógica de negocio ni llamadas directas a APIs.
* Controlar estados asíncronos mediante `AsyncValue` (`when`, `whenData`, `maybeWhen`), asegurando feedback visual para estados de **Carga**, **Error** y **Datos**.
* Mantener los providers con el scope mínimo necesario (`autoDispose` cuando la pantalla se destruye).

---

## 4. Estándares de Código y Linter (very_good_analysis)

* El proyecto implementa las reglas estrictas de **`very_good_analysis`**.
* **Constructores `const`:** Usar `const` siempre que un widget o valor sea constante para optimizar la recolección de basura y renderizado.
* **Inmutabilidad:** Todas las clases de modelos y estados deben ser inmutables (`final` en todas las propiedades).
* **Manejo de Errores y Logs:** Prohibido el uso de `print()`. Utilizar `debugPrint()` o un servicio centralizado de logging.
* **Formato y Limpieza:**
  * Ejecutar siempre `dart analyze` y verificar 0 issues antes de completar una tarea.
  * Formatear el código con `dart format .`.

---

## 5. Estrategia de Testing para Agentes de IA

* **Tests Unitarios y de Repositorio:** Probar lógica de negocio pura y transformaciones de datos (`flutter_test`).
* **Golden / Snapshot Tests:** Usar **`alchemist`** para verificar visualmente que los widgets se renderizan correctamente sin requerir interfaz gráfica abierta.
* **Verificación de Regresiones:** Ningún PR o commit debe realizarse si `dart analyze` o `flutter test` fallan.
