/// Platform wiring for the compression worker pool.
///
/// What: supplies the worker count, whether compression can leave the UI
/// isolate, and how one worker is built.
/// Why: the pool itself must stay free of `dart:io` so it compiles for the
/// web, where there are no isolates at all.
library;

export 'pdf_worker_factory_io.dart'
    if (dart.library.js_interop) 'pdf_worker_factory_web.dart';
