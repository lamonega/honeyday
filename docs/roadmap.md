# Retomar Honeyday

## Dirección

Priorizar un **cuaderno/planner local y personalizable** que se pueda usar a
 diario con confianza. La base actual es un editor modular con tinta, no un
 gestor de tareas/calendario con recordatorios. No hace falta cambiar Riverpod,
 Drift ni GoRouter para completar esa experiencia.

## Entregas incorporadas

- [x] Pruebas de orden, fallos, reintentos y vaciado de editores en `SaveSession`.
- [x] [Backups editables](backups.md) con tinta, validación y restauración
  transaccional como copias independientes.
- [x] Renombrar agendas desde la portada, conservando el texto si falla el guardado.
- [x] Recordar la última página por identidad, incluso al cambiar su orden.
- [x] Duplicar páginas con elementos y tinta; guardar campos pendientes antes de copiar.
- [x] Probar la migración v1 → v2, reapertura, índices y claves foráneas.
- [x] Corregir el timeout de la prueba de respuesta de exportación.
- [x] Análisis sin incidencias y CI que rechaza también los avisos informativos.
- [x] Compilar el target JavaScript Web en CI, además de las pruebas en Windows.

## Próximos trabajos, en orden sugerido

### 1. Validación manual y primera distribución de prueba

Elegir una plataforma principal y una secundaria. La presencia de carpetas de
seis plataformas no significa que todos sus flujos estén certificados.

- [ ] Crear una agenda, escribir texto y tinta, cerrar normalmente y reabrir.
- [ ] Duplicar una página con un campo todavía enfocado; comprobar que la copia
  contiene la última edición y que editarla no cambia la original.
- [ ] Exportar/importar un backup desde la interfaz real y verificar los
  documentos guardados, no solo el mensaje de éxito.
- [ ] En escritorio: guardar, cancelar, seleccionar un archivo inválido y
  comprobar el comportamiento al sobrescribir un archivo existente.
- [ ] En Android/iOS: probar el selector y la hoja de compartir; en iPad, el popover.
- [ ] En Web: probar la descarga, el selector, la persistencia al recargar y las
  advertencias del navegador sobre almacenamiento privado/limpieza de datos.
- [ ] Probar teclado, mouse, touch y lápiz en los dispositivos que se vayan a soportar.
- [ ] Probar ir a segundo plano y cerrar la ventana. Las pruebas de desmontaje
  no equivalen a demostrar guardado ante un cierre forzado del proceso.

No crear un tag de release basándose únicamente en análisis y pruebas de widget.

### 2. Fuentes realmente offline

Actualmente `google_fonts` descarga fuentes en runtime y los golden existentes
utilizan su configuración de prueba. Empaquetar Fraunces y Plus Jakarta Sans con
sus licencias y variantes utilizadas. Verificar un primer arranque sin red,
la captura PDF y los cambios visuales. No regenerar golden sin revisar imágenes:
incorporar fuentes reales puede cambiar medidas, saltos de línea y portadas.

### 3. Exportación PDF de la agenda completa

El PDF actual exporta portada y elementos; **no incluye tinta manuscrita**.
El backup sí la conserva. Antes de cambiarlo:

- Definir opciones explícitas para agenda completa y plantilla reutilizable.
- Mantener una lectura consistente entre texto, geometría y tinta.
- Reutilizar el pintor de tinta existente y probar su orden de capas.
- Medir memoria con páginas cargadas: decodificar todos los puntos de toda una
  agenda simultáneamente puede anular las mejoras del pipeline de exportación.
- Probar resultados visuales, cancelación y respuesta de la interfaz en Web y nativo.

### 4. Uso diario y recuperación

- Búsqueda por título, seguida de búsqueda textual si hay una necesidad real.
- Un pequeño conjunto de plantillas de página completas, no más elementos sueltos.
- Papelera/restauración de agendas eliminadas, con una política clara para
  contenido eliminado y limpieza permanente.
- Considerar backup por agenda y backups mayores que 50 MiB solo con una
  estrategia de memoria y formato apropiada; no quitar el límite sin medir.

### 5. Mantenimiento guiado por pruebas

Separar gradualmente las responsabilidades de `agenda_viewer_page.dart`, que
sigue concentrando navegación, guardado, gestión de páginas y exportación.
Preservar las pruebas de identidad, contenido pendiente y reintentos al hacerlo.
Medir escrituras de tinta antes de reemplazar su sincronización de lista completa
por cambios incrementales.

## Fuera del siguiente hito

Posponer cuentas, sincronización cloud, colaboración e IA hasta validar uso real.
Timestamps y soft delete no resuelven por sí solos sincronización ni conflictos.
No hace falta una reescritura de arquitectura para continuar.
