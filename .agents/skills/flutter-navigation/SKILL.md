---
name: flutter-navigation
description: Modifica rutas GoRouter, ramas de navegación o diseño adaptable de la barra y el rail en Flutter.
---

# Navegación adaptable

1. Revisa `lib/app/router.dart` y `lib/app/app_shell.dart` antes de cambiar rutas. Mantén el shell con ramas persistentes cuando corresponda y separa decisiones de negocio de la navegación.
2. Centraliza la definición de rutas y evita dispersar cadenas nuevas innecesariamente. Conserva parámetros y navegación existente.
3. Utiliza los breakpoints y componentes existentes del proyecto; actualmente el shell decide entre barra y rail mediante `kBreakpointMobile`. Prefiere `MediaQuery.sizeOf` cuando solo se necesite el tamaño.
4. Comprueba navegación entre ramas, retorno al inicio de rama, rutas con parámetros y tamaños de pantalla afectados.

## Referencias

Para el ejemplo completo de shell GoRouter, diseño adaptable y tabla de breakpoints genéricos, lee [navigation.md](references/navigation.md).
