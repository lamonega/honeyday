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
- [x] [Fuentes empaquetadas](fonts.md): variantes utilizadas, licencias,
  checksums, precarga y descargas en runtime desactivadas. Revisar y actualizar
  únicamente los golden de portadas afectados por las métricas de Fraunces.
- [x] Empaquetar también Roboto de respaldo: Chrome reveló que el motor Web lo
  descargaba antes de `main()`. Comprobar el arranque con dominios de fuentes
  bloqueados y caché HTTP desactivada, sin modificar más golden.
- [x] [PDF con tinta](pdf-export.md), lectura consistente, geometría decodificada
  por página y opciones independientes de texto/tinta para plantillas.
- [x] Pruebas de capas, resaltador, recorte y contenido del archivo PDF final;
  golden nuevos de agenda completa frente a plantilla y benchmark de memoria.
- [x] [Persistencia Web](web-persistence.md): reproducir y corregir la pérdida
  transaccional de IndexedDB de Drift 2.35.0, actualizar dependencia/worker y
  añadir regresión con recarga real de Chrome y control negativo.

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

Fraunces y Plus Jakarta Sans ya se distribuyen como assets, con precarga y sin
fetching de `google_fonts`. Roboto también se declara en el manifiesto del motor
para eliminar su descarga inicial en Web. Las pruebas comprueban integridad, licencias,
renderizado real y captura PDF. Se revisaron las referencias Windows y CI:
solo cambiaron los títulos de las portadas. Ver [alcance y mantenimiento](fonts.md).

Queda validar un primer arranque **nativo** sin red en dispositivos reales.
En Web, empaquetar fuentes no garantiza que toda la aplicación esté disponible
sin conexión: también intervienen el hosting, el renderer y la caché del navegador.

### 3. Exportación PDF de la agenda completa

El PDF ya incluye portada, elementos y tinta guardada por defecto. Para una
plantilla, desactivar texto y tinta en el diálogo; también se pueden elegir de
forma independiente. El PDF no sustituye al backup editable.

La instantánea captura las filas de tinta en la misma transacción que páginas
y elementos, pero solo decodifica los puntos de la página que se está preparando.
Las pruebas cubren capas, transparencia, recorte, datos borrados, cambios
posteriores en la base y el contenido comprimido del archivo final.

Pendiente en plataformas reales:

- [ ] Revisar A4/Carta, portada y fidelidad de tinta/texto en un visor PDF externo.
- [ ] Exportar con un campo enfocado y recién editado; comprobar texto y trazo final.
- [ ] Cancelar una agenda grande y repetir la exportación sin dejar archivos temporales.
- [ ] Medir memoria y respuesta con páginas de mucha tinta en Web y dispositivos
  de poca RAM. Los JSON capturados siguen en memoria; no se promete memoria
  constante para una biblioteca arbitrariamente grande.

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
