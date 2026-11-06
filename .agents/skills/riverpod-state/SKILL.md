---
name: riverpod-state
description: Implementa o revisa proveedores Riverpod, notifiers, operaciones asíncronas y limpieza del ciclo de vida en Flutter.
---

# Estado Riverpod y ciclo de vida

1. Sigue los proveedores existentes y elige el tipo apropiado: `Notifier` para estado síncrono, `AsyncNotifier` para operaciones asíncronas y proveedores derivados o de flujo cuando corresponda. Representa carga, datos y errores de forma explícita y evita mutar el estado compartido.
2. Usa `ref.watch` para dependencias reactivas en `build` o proveedores, `ref.read` en callbacks y `ref.listen` para efectos secundarios. Usa `select` si una reconstrucción amplia es problemática.
3. Tras un `await`, comprueba `context.mounted` antes de volver a usar el contexto. Antes de actualizar un notifier después de una espera, comprueba que siga activo con la API compatible con la versión instalada; comprueba tanto la ruta de éxito como la de error. Una comprobación solo antes del `await` no protege la actualización posterior.
4. Cancela suscripciones y temporizadores con `ref.onDispose`; libera controladores en `dispose`. Prueba cancelaciones, errores y desmontaje durante operaciones asíncronas.


## Referencias

- Para tipos de proveedores, flujo de estado, `watch`, `read`, `listen` y ejemplos completos, lee [state-management.md](references/state-management.md).
- Para ejemplos completos de `mounted`, cancelación y limpieza, lee [async-lifecycle.md](references/async-lifecycle.md).
