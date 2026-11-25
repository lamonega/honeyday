# Verificación por plataforma

El objetivo de verificación son los flujos existentes, no incorporar
funcionalidad. Una compilación correcta no verifica la interacción nativa,
la persistencia ante cierres ni la distribución en una tienda.

## Comprobaciones reproducibles

Desde la raíz, con la versión de Flutter fijada en CI:

```sh
flutter pub get
dart analyze --fatal-infos
flutter test --concurrency=2
flutter build web --no-pub --no-wasm-dry-run --no-web-resources-cdn
node tool/test_web_persistence.mjs
```

El build Web incluye el renderer de Flutter en el propio origen. Servir todo
`build/web/` por HTTPS en producción o por HTTP en localhost para pruebas; no
abrir `index.html` directamente como un archivo. El renderer y las fuentes
locales no implican que el sitio pueda iniciarse sin conexión al servidor. Si el
hosting usa una subruta (por ejemplo `/honeyday/`), compilar con
`--base-href /honeyday/` y conservar juntos el worker, el módulo SQLite y los
assets.

Web requiere un navegador moderno con WebAssembly y almacenamiento de sitio.
En modo privado, el almacenamiento puede descartarse al cerrar la ventana aun
cuando la aplicación pueda abrirlo. Para datos importantes, conservar una
copia editable fuera del navegador.

La matriz nativa de CI compila Windows, Linux, macOS, iOS sin firma y Android con
clave de depuración. No publica ni firma paquetes de tienda. Un resultado de CI
solo se considera comprobado cuando la ejecución del commit es exitosa.

## Verificación realizada

- **Flutter 3.47.6 / Windows 10:** análisis sin incidencias, suite con 430
  pruebas aprobadas y dos benchmarks omitidos, y builds JavaScript Web y
  Windows x64 Release correctos. Se comprobó el arranque del ejecutable Windows;
  no se probaron desde esa ventana los diálogos nativos.
- **Chrome:** onboarding a 320×568, navegación accesible a 1100×800, creación,
  duplicación y recarga, edición del canvas, papelera y restauración. Se descargó
  e importó el archivo `.honeyday` desde el selector; se verificó un PDF Carta
  descargado de tres páginas. Con almacenamiento deshabilitado, Inicio muestra
  instrucciones y no ofrece crear una agenda.
- **Chrome y Edge:** la prueba de navegador confirma persistencia de
  transacciones al recargar, descarga PDF y el error cuando no hay almacenamiento
  durable. **Firefox:** onboarding, creación y reapertura de una agenda tras
  recargar.

## Qué comprobar antes de distribuir

| Plataforma | Pruebas en dispositivo o navegador, además de compilar |
| --- | --- |
| Web | Chrome, Edge, Firefox y Safari; pantalla estrecha y ancha, orientación de tablet, recarga y segundo plano. Probar el selector, denegación de almacenamiento y validar los archivos descargados. |
| Windows y Linux | Arranque desde el paquete, mouse y teclado, diálogos de guardar/abrir/cancelar/sobrescribir y volver a abrir la aplicación. |
| macOS | Los mismos recorridos de escritorio desde el paquete con sandbox; comprobar que un archivo elegido se pueda abrir y que se pueda guardar en la carpeta elegida. |
| Android | Pantallas pequeñas y grandes, teclado virtual, guardar mediante el selector, compartir y cancelar; segundo plano y reapertura. |
| iOS y iPadOS | Segundo plano y reapertura, teclado, navegación táctil, selector de archivos y hoja de compartir. En iPad, comprobar el anclaje del popover en vertical y horizontal. |

En cada plataforma: completar el primer inicio, crear una agenda, editar texto
y tinta y volver a abrirla; duplicar una página con un campo enfocado y verificar
que la copia es independiente. Exportar e importar un backup, abrir un PDF A4 y
Carta en un visor externo, y probar papelera, restauración y confirmación de
borrado definitivo. Para certificar la entrada con lápiz hace falta hardware:
un evento sintetizado no valida presión, rechazo de palma ni latencia.
