---
name: flutter-widgets
description: Crea o refactoriza widgets de presentación Flutter y componentes reutilizables, con atención a responsabilidades, callbacks y rendimiento.
---

# Widgets de presentación

1. Separa la pantalla que conecta estado, navegación y feedback de los componentes reutilizables que reciben datos y callbacks tipados.
2. Prefiere constructores e instancias `const` cuando sea posible. Extrae widgets cuando mejore legibilidad, reutilización o permita optimizaciones medibles; no presupongas que todo helper de construcción produce problemas de rendimiento.
3. Evita introducir lógica de negocio o I/O en componentes de presentación. Conserva los patrones existentes cuando la extracción no aporte valor.
4. Comprueba visualización, interacciones y accesibilidad; añade pruebas de widget o golden cuando corresponda.

## Referencias

Para los ejemplos completos de composición, `const`, callbacks y lista de revisión, lee [widgets.md](references/widgets.md).
