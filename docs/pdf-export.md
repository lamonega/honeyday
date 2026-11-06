# Exportación PDF

Desde el visor de una agenda se exportan la portada y todas sus páginas activas,
en su orden guardado, a A4 o Carta. El resultado contiene imágenes rasterizadas
de las páginas: no es texto seleccionable ni un documento que se pueda volver
a importar para editar. Para conservar datos editables, usar un [backup](backups.md).

## Agenda completa y plantilla

Las opciones predeterminadas incluyen **texto escrito y tinta manuscrita**.
Los dos controles son independientes:

| Texto | Tinta | Resultado |
|---|---|---|
| Sí | Sí | Agenda con contenido y escritura guardados |
| Sí | No | Elementos con sus datos, sin trazos |
| No | Sí | Elementos restablecidos y escritura manuscrita |
| No | No | Plantilla reutilizable, sin los datos de elementos conocidos ni tinta |

La portada mantiene el título y el estilo de la agenda en todos los casos. Al
excluir texto, se restablece la configuración completa de los tipos conocidos
a los valores iniciales del catálogo, conservando posición, tamaño y rotación.
Los tipos desconocidos mantienen su configuración y usan el renderizado de
respaldo existente: esta opción no es un anonimizador universal. Revisar el PDF
antes de compartirlo si contiene información privada.

El visor vacía editores y espera la cola de guardado antes de exportar. El botón
de ocultar tinta para leer una página no modifica los datos: para omitirla en el
PDF hay que desactivar la opción correspondiente en el diálogo.

## Fidelidad y lectura consistente

La instantánea lee agenda, páginas, elementos y filas de tinta dentro de una
misma transacción SQLite. Excluye contenido eliminado y no vuelve a consultar
la base cuando llega el momento de dibujar una página. Los cambios posteriores
no alteran esa instantánea.

`StaticPageView` pinta papel, elementos en su orden y tinta por encima, como el
visor. La tinta utiliza el mismo `InkPainter` (pluma y resaltador con su opacidad)
y queda recortada a los límites de la página; no incluye el cursor/borrador ni
un trazo todavía activo. La captura utiliza las [fuentes empaquetadas](fonts.md)
y espera cualquier carga de fuente pendiente antes de rasterizar.

## Memoria y límites

Las filas capturadas conservan su JSON original. Cada página expone un iterable
que lo convierte en `InkStroke` solo al preparar esa página; no se acumulan las
listas de puntos de todas las páginas en la instantánea. Excluir tinta evita
incluso la consulta de sus filas. La captura anterior puede seguir montada hasta
que se sustituye por la siguiente, y el GC no libera memoria instantáneamente.

Esto evita la expansión anticipada de toda la agenda, **no** hace constante la
memoria total: los JSON y elementos de la instantánea siguen en RAM, una página
con muchos puntos puede ser costosa, la pintura se ejecuta en el isolate de UI,
y el PDF Web se reúne en memoria. La compresión conserva su cola acotada y el
escritor nativo sigue enviando bytes a un archivo temporal.

### Muestra reproducible

```bash
flutter test test/benchmark/ink_snapshot_memory_test.dart --run-skipped --concurrency=1 --dart-define=honeyday.inkSnapshotMode=lazy
flutter test test/benchmark/ink_snapshot_memory_test.dart --run-skipped --concurrency=1 --dart-define=honeyday.inkSnapshotMode=eager
flutter test test/benchmark/ink_snapshot_memory_test.dart --run-skipped --concurrency=1 --dart-define=honeyday.inkSnapshotMode=template
```

Cada modo se ejecuta en un proceso nuevo. La muestra usa el repositorio real y
SQLite en memoria, 20 páginas × 20 trazos × 250 puntos (100.000 puntos), sin
rasterizar ni comprimir páginas:

| Modo | Puntos recorridos | Geometría referenciada en la muestra | Tiempo observado |
|---|---:|---:|---:|
| Por página (`lazy`) | 100.000 | 5.000 puntos de la página actual | 313 ms |
| Precarga simulada (`eager`) | 100.000 | 100.000 puntos de todas las páginas | 408 ms |
| Plantilla (`template`) | 0 | 0 | 25 ms |

Son observaciones locales en Windows, no límites ni objetivos de rendimiento.
El benchmark imprime además RSS inicial y máximo muestreado. En esta ejecución
los RSS iniciales variaron de 75 a 172 MiB entre procesos, por lo que **no** se
infiere una reducción porcentual de RAM de esos valores. RSS incluye el motor,
SQLite, temporales del decoder, memoria reservada por el GC y decisiones del SO;
el muestreo también puede perder picos. Perfilar agendas reales en dispositivos
objetivo sigue pendiente.

## Verificación automática y pendiente manual

```bash
flutter test test/features/agendas/data/repositories/agenda_snapshot_ink_test.dart
flutter test test/features/export
flutter test test/golden
```

Las pruebas cubren orden y filtrado, estabilidad de la instantánea tras reemplazar
filas, decodificación por página y omisión de tinta, opciones del diálogo y scroll
con texto ampliado. Las capturas comprueban píxeles de pluma, mezcla del resaltador
y recorte. La integración crea un PDF con la base, captura, worker y escritor
reales y descomprime su imagen para comprobar el trazo, tanto incluido como
excluido. Los golden Windows/CI comparan agenda y plantilla.

Aún hay que revisar los PDF en un visor externo, imprimir A4/Carta y comprobar
cancelación, hojas de compartir, descargas y memoria con agendas grandes en las
plataformas objetivo. Las pruebas de escritorio no certifican esos recorridos
nativos ni dispositivos de poca RAM.
