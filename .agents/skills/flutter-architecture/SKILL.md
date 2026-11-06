---
name: flutter-architecture
description: Diseña o modifica capas de una funcionalidad Flutter, contratos de repositorio, DTOs, mapeos y persistencia; úsala al cambiar dominio o datos.
---

# Arquitectura y repositorios

1. Examina la funcionalidad existente bajo `lib/features/`: el dominio modela conceptos y contratos, datos implementa persistencia y presentación muestra estado y recibe eventos. Mantén las dependencias lo más dirigidas posible hacia el dominio, sin asumir que todas las funcionalidades ya cumplen una arquitectura estricta.
2. Para un contrato nuevo, considera una interfaz en `domain/repositories/`, con entidades o tipos simples en sus métodos. Evita filtrar detalles del cliente o la base de datos a ese contrato.
3. Ubica implementaciones y DTOs en datos, siguiendo los directorios existentes. Convierte explícitamente entre DTO y entidad; mantén la serialización en datos cuando sea viable. Inyecta dependencias sustituibles cuando aporte valor.
4. Mantén las entidades inmutables cuando sea viable y evita I/O directo en widgets. Comprueba contratos, mapeos, gestión de errores y pruebas de repositorio.


## Referencias

- Para el diagrama general, índice de temas y enlaces externos, lee [overview.md](references/overview.md).
- Para capas, estructura propuesta y lista de comprobación completas, lee [architecture.md](references/architecture.md).
- Para contratos, DTOs, mapeos y ejemplo completo de repositorio, lee [repositories.md](references/repositories.md).
