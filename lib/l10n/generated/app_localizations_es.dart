// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonCreate => 'Crear';

  @override
  String get appTitle => 'Honeyday';

  @override
  String get navHome => 'Inicio';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsDarkMode => 'Modo oscuro';

  @override
  String get settingsThemeSystem => 'Automático (sistema)';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsAccentColor => 'Color de acento';

  @override
  String get settingsAccentCustom => 'Personalizado';

  @override
  String get backupTitle => 'Copias de seguridad editables';

  @override
  String get backupPrivacy =>
      'Incluye todas las agendas activas, elementos de página y escritura a mano. El archivo no está cifrado: guardalo en un lugar privado. No incluye elementos eliminados ni ajustes de la aplicación.';

  @override
  String get backupExport => 'Crear copia de seguridad';

  @override
  String get backupExportDescription =>
      'Guardar una copia editable de todas tus agendas';

  @override
  String get backupRestore => 'Importar copia de seguridad';

  @override
  String get backupRestoreSubtitle =>
      'Agregar agendas desde un archivo de Honeyday';

  @override
  String get backupWorking => 'Procesando…';

  @override
  String get backupReady => 'Archivo de copia de seguridad preparado.';

  @override
  String get backupError =>
      'La operación falló. No se reemplazaron tus agendas existentes. Intentá de nuevo.';

  @override
  String get backupInvalid =>
      'El archivo no es una copia de Honeyday válida y compatible, o supera el límite de 50 MiB.';

  @override
  String get backupConfirmTitle => '¿Importar estas agendas?';

  @override
  String backupConfirmDescription(
    int agendas,
    int pages,
    int elements,
    int strokes,
  ) {
    return 'Agendas: $agendas\nPáginas: $pages\nElementos: $elements\nTrazos de tinta: $strokes\n\nSe agregarán copias independientes. Tus agendas existentes no se modificarán. Si importás el mismo archivo otra vez, se crearán copias adicionales.';
  }

  @override
  String get backupConfirm => 'Importar copias';

  @override
  String backupRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se importaron $count agendas.',
      one: 'Se importó 1 agenda.',
    );
    return '$_temp0';
  }

  @override
  String get backupEmpty => 'Esta copia de seguridad no contiene agendas.';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsVersion => 'Versión';

  @override
  String get settingsLicenses => 'Licencias';

  @override
  String get settingsLicensesSubtitle => 'Revisar licencias de código abierto';

  @override
  String get settingsAccentBeeHoney => 'Abeja miel';

  @override
  String get settingsAccentLavender => 'Lavanda';

  @override
  String get settingsAccentSage => 'Salvia';

  @override
  String get settingsAccentRose => 'Rosa';

  @override
  String get settingsAccentOcean => 'Océano';

  @override
  String get settingsAccentBrick => 'Ladrillo';

  @override
  String get settingsAccentGray => 'Gris';

  @override
  String get settingsAccentTeal => 'Teal';

  @override
  String get homeTitle => 'Honeyday';

  @override
  String get homeErrorLoading => 'Error al cargar agendas';

  @override
  String get homeEmptyTitle => 'Sin agendas';

  @override
  String get homeEmptyBody => 'Toca + para crear una.';

  @override
  String get agendaRename => 'Renombrar agenda';

  @override
  String get agendaTitleRequired => 'Ingresá un título.';

  @override
  String get agendaRenameError =>
      'No se pudo renombrar la agenda. Conservamos tu título; intentá de nuevo.';

  @override
  String get agendaDeleteTitle => '¿Eliminar agenda?';

  @override
  String agendaDeleteContent(Object title) {
    return 'Se eliminará \"$title\" y todas sus páginas asociadas.';
  }

  @override
  String get agendaExitTitle => '¿Salir sin guardar?';

  @override
  String get agendaExitContent =>
      'Tenés cambios sin guardar. ¿Qué querés hacer?';

  @override
  String get agendaDiscard => 'Descartar';

  @override
  String get agendaSave => 'Guardar';

  @override
  String agendaPagesError(Object error) {
    return 'Error al cargar páginas: $error';
  }

  @override
  String get agendaSaveError =>
      'No se pudieron guardar los cambios. Intentá de nuevo.';

  @override
  String get agendaNoPages => 'No hay páginas disponibles.';

  @override
  String get agendaNewDefaultTitle => 'Mi Agenda 2026';

  @override
  String get agendaNewTitle => 'Nueva Agenda';

  @override
  String get agendaNewHint => 'Título';

  @override
  String get agendaPageDesignLines => 'Líneas';

  @override
  String get agendaPageDesignDots => 'Puntos';

  @override
  String get agendaPageDesignBlank => 'En blanco';

  @override
  String get agendaPageDesignGrid => 'Cuadrícula';

  @override
  String get agendaPageDeleteTitle => '¿Eliminar página?';

  @override
  String agendaPageDeleteContent(Object index) {
    return 'Se eliminará la página $index. Esta acción no se puede deshacer.';
  }

  @override
  String agendaPageCount(Object count) {
    return 'Páginas ($count)';
  }

  @override
  String get agendaPageDuplicate => 'Duplicar página';

  @override
  String get agendaPageDuplicated =>
      'Se duplicó la página después de la original.';

  @override
  String get agendaPageAdd => 'Añadir página';

  @override
  String get agendaModeRead => 'Modo lectura';

  @override
  String get agendaModeEdit => 'Modo edición';

  @override
  String agendaPageBadge(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count págs.',
      one: '$count pág.',
    );
    return '$_temp0';
  }

  @override
  String get agendaDeleteTooltip => 'Eliminar agenda';

  @override
  String get catalogFilterAll => 'Todas';

  @override
  String get catalogFilterShapes => 'Formas';

  @override
  String get catalogFilterTemplates => 'Plantillas';

  @override
  String get catalogFilterDecoration => 'Decoración';

  @override
  String get catalogElementsHeader => 'Elementos';

  @override
  String get onboardingStep1Title => 'Organiza tu vida';

  @override
  String get onboardingStep1Desc =>
      'Crea agendas personalizadas para cada área de tu vida:\nfinanzas, hábitos, proyectos y más.';

  @override
  String get onboardingStep2Title => 'Dibuja libremente';

  @override
  String get onboardingStep2Desc =>
      'Escribe a mano, dibuja, resalta y usa herramientas\nde tinta con precisión de presión.';

  @override
  String get onboardingStep3Title => 'Personaliza todo';

  @override
  String get onboardingStep3Desc =>
      'Agrega plantillas, stickers, formas y elementos\npara crear la agenda perfecta.';

  @override
  String get onboardingSkip => 'Saltar';

  @override
  String get onboardingStart => 'Comenzar';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get catalogShapeRectangle => 'Rectángulo';

  @override
  String get catalogShapeRectangleDesc =>
      'Tarjeta o contenedor para estructurar secciones';

  @override
  String get catalogShapeCircle => 'Círculo';

  @override
  String get catalogShapeCircleDesc => 'Forma circular o elíptica estética';

  @override
  String get catalogShapeDivider => 'Divisor';

  @override
  String get catalogShapeDividerDesc =>
      'Línea separadora estética para la página';

  @override
  String get catalogShapePennant => 'Banderín';

  @override
  String get catalogShapePennantDesc => 'Cinta de encabezado estilo Canva';

  @override
  String get catalogShapeFrame => 'Marco';

  @override
  String get catalogShapeFrameDesc =>
      'Marco perimetral elegante adaptable a toda la página';

  @override
  String get catalogShapeStar => 'Estrella';

  @override
  String get catalogShapeStarDesc => 'Estrella geométrica decorativa';

  @override
  String get catalogShapeLabel => 'Etiqueta';

  @override
  String get catalogShapeLabelDesc => 'Forma alargada con extremos redondeados';

  @override
  String get catalogShapeStickyNote => 'Nota adhesiva';

  @override
  String get catalogShapeStickyNoteDesc =>
      'Nota de papel estática con chincheta y líneas para escribir';

  @override
  String get catalogShapeTape => 'Cinta decorativa';

  @override
  String get catalogShapeTapeDesc =>
      'Tira decorativa semitransparente con diseño';

  @override
  String get catalogTemplateWeeklyView => 'Vista semanal';

  @override
  String get catalogTemplateWeeklyViewDesc =>
      'Estructura de 7 días para planificar la semana a mano';

  @override
  String get catalogTemplateChecklist => 'Checklist';

  @override
  String get catalogTemplateChecklistDesc =>
      'Lista con casillas de verificación estéticas para escribir tareas';

  @override
  String get catalogTemplateHabits => 'Hábitos';

  @override
  String get catalogTemplateHabitsDesc =>
      'Matriz de seguimiento semanal para colorear con el lápiz';

  @override
  String get catalogTemplatePriorities => 'Prioridades';

  @override
  String get catalogTemplatePrioritiesDesc =>
      'Estructura destacada para las 3 prioridades clave';

  @override
  String get catalogTemplateLinedNotes => 'Notas rayadas';

  @override
  String get catalogTemplateLinedNotesDesc =>
      'Área de notas con renglones para escribir con precisión';

  @override
  String get catalogTemplateGridNotes => 'Notas cuadriculadas';

  @override
  String get catalogTemplateGridNotesDesc =>
      'Área de notas con papel milimetrado o cuadrícula sutil';

  @override
  String get catalogStickerHeart => 'Corazón';

  @override
  String get catalogStickerHeartDesc => 'Icono decorativo de corazón';

  @override
  String get catalogStickerStar => 'Estrella decorativa';

  @override
  String get catalogStickerStarDesc => 'Icono decorativo de estrella brillante';

  @override
  String get catalogStickerCoffee => 'Café';

  @override
  String get catalogStickerCoffeeDesc => 'Icono de descanso o café';

  @override
  String get catalogStickerPin => 'Chincheta';

  @override
  String get catalogStickerPinDesc =>
      'Chincheta decorativa para notas y tarjetas';

  @override
  String get catalogDayMon => 'LUN';

  @override
  String get catalogDayTue => 'MAR';

  @override
  String get catalogDayWed => 'MIÉ';

  @override
  String get catalogDayThu => 'JUE';

  @override
  String get catalogDayFri => 'VIE';

  @override
  String get catalogDaySat => 'SÁB';

  @override
  String get catalogDaySun => 'DOM';

  @override
  String get catalogBudgetTitle => 'Presupuesto';

  @override
  String get catalogBudgetDefaultIncome => 'Ingreso Principal';

  @override
  String get catalogBudgetDefaultExpense1 => 'Alquiler y Servicios';

  @override
  String get catalogBudgetDefaultExpense2 => 'Supermercado y Alimentos';

  @override
  String get catalogBudgetName => 'Calculadora de Presupuesto';

  @override
  String get catalogBudgetNewExpense => 'Gasto nuevo';

  @override
  String get catalogBudgetIncome => 'Ingresos';

  @override
  String get catalogBudgetExpenses => 'Gastos';

  @override
  String get catalogBudgetBalance => 'Balance';

  @override
  String get catalogBudgetAddEntry => 'Nueva entrada';

  @override
  String get catalogHabitsTitle => 'Hábitos Semanales';

  @override
  String get catalogHabitsDefault1 => 'Beber 2L de agua';

  @override
  String get catalogHabitsDefault2 => 'Leer 20 minutos';

  @override
  String get catalogHabitsDefault3 => 'Ejercicio diario';

  @override
  String get catalogHabitsName => 'Cuadrícula con Días';

  @override
  String get catalogHabitsDayMon => 'L';

  @override
  String get catalogHabitsDayTue => 'M';

  @override
  String get catalogHabitsDayWed => 'M';

  @override
  String get catalogHabitsDayThu => 'J';

  @override
  String get catalogHabitsDayFri => 'V';

  @override
  String get catalogHabitsDaySat => 'S';

  @override
  String get catalogHabitsDaySun => 'D';

  @override
  String get catalogHabitsNew => 'Nuevo hábito';

  @override
  String get catalogHabitsAdd => 'Añadir hábito';

  @override
  String get catalogJournalToday => 'Hoy';

  @override
  String get catalogJournalDefaultDate => 'Viernes, 11 de Septiembre';

  @override
  String get catalogJournalPriority1 => 'Completar objetivos clave del día';

  @override
  String get catalogJournalPriority2 => 'Momento de desconexión y lectura';

  @override
  String get catalogJournalPriority3 => 'Planificar la semana próxima';

  @override
  String get catalogJournalDefaultNotes =>
      'Reflexiones y aprendizajes de hoy...';

  @override
  String get catalogJournalName => 'Entrada Diaria / Semanal';

  @override
  String get catalogJournalPrioritiesHeader => 'Prioridades del Día';

  @override
  String get catalogJournalNotesHeader => 'Notas & Reflexión';

  @override
  String get catalogJournalNotesHint =>
      'Escribe aquí tus pensamientos del día...';

  @override
  String get catalogJournalNoNotes => 'Sin notas para este día.';

  @override
  String get catalogColorHoney => 'Miel';

  @override
  String get catalogColorPink => 'Rosa';

  @override
  String get catalogColorSage => 'Salvia';

  @override
  String get catalogColorTransparent => 'Transparente';

  @override
  String get catalogTextboxDefaultContent =>
      '¡Nota importante!\nEscribe aquí tus ideas o recordatorios.';

  @override
  String get catalogTextboxName => 'Nota de Texto';

  @override
  String get catalogTextboxHint => 'Escribe tu nota aquí...';

  @override
  String get catalogChecklistHeader => 'CHECKLIST';

  @override
  String get catalogHabitsHeader => 'HÁBITOS DE LA SEMANA';

  @override
  String get catalogPrioritiesHeader => 'PRIORIDADES';

  @override
  String get paperStyleDots => 'Puntos';

  @override
  String get paperStyleLines => 'Rayas';

  @override
  String get paperStyleGrid => 'Cuadrícula';

  @override
  String get paperStyleBlank => 'Blanca';

  @override
  String catalogErrorUnknownWidget(Object widgetType) {
    return 'Widget no reconocido: $widgetType';
  }

  @override
  String get canvasModularWidgetContainer => 'Contenedor de widget modular';

  @override
  String get exportPdfTooltip => 'Exportar a PDF';

  @override
  String get exportDialogTitle => 'Exportar a PDF';

  @override
  String get exportFormatLabel => 'Tamaño de página';

  @override
  String get exportFormatLetter => 'Carta';

  @override
  String get exportIncludeContentLabel => 'Incluir texto escrito';

  @override
  String exportPagesSummary(int count) {
    return '$count páginas · 300 dpi';
  }

  @override
  String get exportStart => 'Exportar';

  @override
  String get exportProgressTitle => 'Exportando…';

  @override
  String exportProgressPage(int current, int total) {
    return 'Renderizando página $current de $total';
  }

  @override
  String get exportPhaseCapturing => 'Renderizando las páginas';

  @override
  String get exportPhaseCompressing => 'Comprimiendo las imágenes…';

  @override
  String get exportPhaseWriting => 'Escribiendo el PDF…';

  @override
  String get exportError => 'La exportación falló. Intenta de nuevo.';

  @override
  String get exportErrorBackground =>
      'Honeyday no pudo renderizar las páginas porque la ventana estaba en segundo plano. Traé Honeyday al frente e intentá de nuevo.';

  @override
  String get agendaSaved => 'Guardado';

  @override
  String get agendaSaving => 'Guardando…';

  @override
  String get agendaRetrySave => 'Error al guardar. Reintentar';

  @override
  String get canvasInputContent => 'Contenido';

  @override
  String get canvasInputInk => 'Tinta';
}
