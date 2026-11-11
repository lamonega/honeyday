# Persistencia Web y worker Drift

## Fallo corregido

Drift **2.35.0** podía completar una transacción en memoria sin enviar sus cambios
a IndexedDB. Una agenda recién creada se veía correctamente, pero desaparecía
al recargar si ninguna escritura posterior fuera de transacción había forzado
el vaciado. También afectaba a escrituras mediante `RETURNING`.

Se reprodujo con Chrome en un origen de prueba sin cabeceras de aislamiento,
usando `WasmStorageImplementation.sharedIndexedDb`. La creación de agendas,
duplicación de páginas, restauración de backups y reemplazo de tinta usan
transacciones, por lo que no era suficiente verificar solo repositorios nativos.

El arreglo está en [Drift 2.35.1, incidencia #3864](https://github.com/simolus3/drift/blob/drift-2.35.3/drift/CHANGELOG.md#2351).
El proyecto exige al menos **2.35.3** (también incorpora el arreglo de savepoints
OPFS de 2.35.2); el lockfile usado para esta corrección resuelve Drift **2.35.4**
y `drift_dev` **2.35.3**. No cambian el esquema SQLite ni sus nombres de archivos.

**Si tienes una versión anterior abierta con datos importantes, crea un backup
antes de recargar o actualizar.** El parche evita pérdidas futuras, pero no puede
recuperar escrituras que ya se perdieron. Exporta los datos, cierra las pestañas
antiguas y abre la versión actualizada: un SharedWorker ya iniciado puede seguir
ejecutando el código anterior mientras tenga clientes conectados.

## Mantener el worker sincronizado

Actualizar solo `pubspec.lock` no arregla un worker ya compilado. Tras cambiar
Drift o el SDK, regenerar el archivo estático que se entrega al navegador:

```bash
flutter pub get
dart run tool/build_drift_worker.dart
```

`tool/drift_worker.dart` es la fuente mínima, basada en el entry point público
`WasmDatabase.workerMainForOpen()`. No editar manualmente el JavaScript generado.
El helper ejecuta `dart compile js -O4 --no-source-maps` en
`.dart_tool/drift_worker/` y copia únicamente el JavaScript a `web/`. El archivo
`.js.deps` contiene rutas de la máquina: **ignorarlo en Git no impide que Flutter
lo copie al build**. Por eso se genera fuera de `web/` y el helper elimina también
los `.deps` heredados de esa carpeta y de `build/web/`. CI rechaza un artefacto
Web con archivos `.deps`. No se necesitan source maps para distribuir el worker.

Esto es **distinto** de generar `app_database.g.dart` con `build_runner`. No hace
falta una migración de esquema para este parche. `web/sqlite3.wasm` no cambió:
se verificó su compatibilidad con el worker regenerado.

CI recompila el worker con Flutter/Dart fijados y rechaza una diferencia con el
JavaScript versionado. Después compila Web y ejecuta la prueba de navegador.
Distribuir la aplicación, el worker y los assets conjuntamente e invalidar las
cachés apropiadas del hosting; no asumir que reemplazar solo `main.dart.js`
actualiza todos los archivos de una instalación.

## Regresión en un navegador real

Requiere **Node 22+**, Chrome/Chromium y Dart en PATH. No usa paquetes npm:

```bash
node tool/test_web_persistence.mjs
```

Se pueden indicar `CHROME_EXECUTABLE` y `DART_EXECUTABLE` si las herramientas no
están en las ubicaciones habituales. En Windows, el script intenta resolver el
`dart.exe` subyacente a `dart.bat` de Flutter.

El driver:

1. Compila `test/web/database_persistence.dart` y copia el worker **distribuido**
   y `sqlite3.wasm` a `build/web-persistence/`.
2. Sirve un origen localhost sin COOP/COEP, para probar IndexedDB y no OPFS.
3. Arranca Chrome headless con un perfil temporal aislado; no accede a datos
   reales de Honeyday ni al perfil habitual del navegador.
4. Crea dos bases de prueba: una con escrituras transaccionales y rollback de
   un savepoint, otra con `INSERT ... RETURNING`.
5. Recarga **sin** llamar a `database.close()`, porque el cierre limpio también
   vaciaba el worker defectuoso y ocultaría el fallo.
6. Comprueba los datos durables tras recargar, cierra conexiones y elimina el
   perfil temporal. La prueba tiene límites de tiempo y falla si no utiliza
   el backend `sharedIndexedDb` esperado.

Se comprobó el control negativo con el worker anterior: la prueba falla con
`Persisted values: []; expected: [committed, after savepoint]`. Con el worker
actual pasa. Para repetir ese diagnóstico se puede usar `DRIFT_WORKER_PATH`
apuntando a otro JavaScript, sin modificar el worker del proyecto.

Además se repitió el recorrido de la aplicación compilada: crear una agenda
con su página, volver a Inicio y recargar. Con el worker anterior la portada
se perdía; con el nuevo seguía disponible. También se dibujó un trazo, se recargó
el visor y se comprobó su persistencia y su inclusión/exclusión en los PDF
realmente descargados; véase [la verificación PDF](pdf-export.md).

## Límites

Esta regresión no certifica todos los navegadores, OPFS, concurrencia entre
múltiples pestañas, almacenamiento privado, cuotas ni recuperación ante un cierre
forzado del sistema. No demuestra que el hosting funcione sin red. Mantener
backups externos y completar las comprobaciones de dispositivos del roadmap.
