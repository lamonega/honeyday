# Papelera de agendas

Desde el icono **Papelera** de Inicio se pueden consultar las agendas eliminadas,
restaurarlas o eliminarlas definitivamente. La ruta Web es `#/trash`.

## Mover a la papelera

La acción de la portada ahora indica **Mover agenda a la papelera**. Su diálogo
explica que se puede recuperar; cancelar no cambia datos. Solo se marca la agenda
como eliminada, sin modificar sus páginas, elementos ni tinta. Desaparece de
Inicio y de las exportaciones PDF/backups de agendas activas.

No hay vencimiento ni limpieza automática. Las agendas borradas con versiones
anteriores también aparecen si sus registros siguen en esta base local. La
lista se ordena por última modificación; no se presenta ese campo como una fecha
de borrado exacta.

## Restaurar

Restaurar conserva el identificador de la agenda y todos los de sus páginas,
elementos y trazos, junto con título, portada, geometría y contenido. Se actualiza
la fecha de modificación de la agenda y vuelve a Inicio. El marcador de lectura
existente sigue apuntando a las mismas identidades.

**No se restauran los hijos eliminados antes de enviar la agenda a la papelera.**
No se cambia el indicador de eliminación de ninguna página, elemento ni trazo.
Así, restaurar una agenda no recupera accidentalmente contenido que ya se había
quitado por separado.

Los backups siguen incluyendo solo agendas y contenido activos. Para respaldar
una agenda de la papelera, **restaurarla primero y después crear el backup**.
La restauración de un backup sigue siendo otro proceso: importa copias con UUID
nuevos; no reemplaza los datos de esta papelera.

## Eliminar definitivamente

Es una acción distinta, disponible solo en la papelera y con una confirmación
que avisa del alcance y de que no hay deshacer. El repositorio vuelve a comprobar
dentro de una transacción que la agenda siga eliminada: si otra operación la
restauró mientras estaba abierto el diálogo, se rechaza el borrado.

La transacción elimina trazos, elementos, páginas y, por último, la agenda.
Incluye filas de hijos ya eliminados y contenido de páginas borradas. Las claves
foráneas permanecen activadas y no hay borrados parciales si falla una sentencia.
Las demás agendas no se modifican. Un identificador que ya no existe es una
operación inocua, de modo que se puede reintentar tras un resultado ambiguo.

**Esto no es un borrado forense seguro** de SQLite, sus archivos auxiliares,
la memoria ni el almacenamiento del dispositivo. Tampoco elimina PDF o backups
exportados, descargas, copias externas ni cachés del sistema. No hay sincronización
cloud ni propagación de borrados entre dispositivos.

## Errores y controles de interfaz

Los diálogos esperan a que termine el guardado. Durante la operación se bloquean
confirmación repetida, cancelar y volver. Si falla, el diálogo permanece abierto
con un mensaje y permite reintentar o cancelar; no se muestra un éxito anticipado.
Se comprueba el montaje al terminar una operación asíncrona.

La lista distingue carga, error recuperable y papelera vacía. La política, la
lista y los textos largos se pueden desplazar; se prueban una ventana estrecha
y texto ampliado. La pantalla también permite volver a Inicio cuando se abre
su URL directamente sin historial de navegación.

## Pruebas

```bash
flutter test test/features/agendas/data/repositories/agenda_trash_test.dart
flutter test test/features/agendas/presentation/pages/agenda_trash_page_test.dart
```

Los casos incluyen identidad y contenido completos, tombstones de hijos,
notificaciones, orden, backups, borrado aislado, rechazo de una agenda activa,
rollback simulado, reintentos y reapertura de SQLite en disco. Las pruebas de
interfaz recorren Inicio → papelera → restauración, cancelación y confirmación
del borrado definitivo, errores, envíos repetidos, desmontaje, enlace directo
y accesibilidad de layout con texto ampliado.

Se comprobó también la aplicación Web compilada en Chrome headless sobre
Windows, con datos de prueba aislados: crear una agenda y dibujar, moverla a la
papelera, recargar, restaurar, comprobar visualmente el mismo trazo, cancelar un
borrado definitivo y finalmente confirmarlo y recargar. Se activaron las acciones
mediante sus nodos de semántica. La URL `#/trash` se conserva al recargar y los
estados de papelera/contenido permanecieron correctos. Esto no certifica todos
los navegadores, dispositivos ni combinaciones de asistencia, puntero y touch.

No cambia el esquema SQLite: se utiliza `isDeleted`, ya existente. No se añade
una papelera para páginas o elementos individuales ni una acción masiva de vaciado.
