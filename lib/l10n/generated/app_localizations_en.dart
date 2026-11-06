// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonCreate => 'Create';

  @override
  String get appTitle => 'Honeyday';

  @override
  String get navHome => 'Home';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsDarkMode => 'Dark mode';

  @override
  String get settingsThemeSystem => 'Automatic (system)';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsAccentColor => 'Accent color';

  @override
  String get settingsAccentCustom => 'Custom';

  @override
  String get backupTitle => 'Editable backups';

  @override
  String get backupPrivacy =>
      'Includes all active agendas, page elements and handwriting. The file is not encrypted: keep it private. Deleted items and app settings are not included.';

  @override
  String get backupExport => 'Create backup';

  @override
  String get backupExportDescription =>
      'Save an editable copy of all your agendas';

  @override
  String get backupRestore => 'Import backup';

  @override
  String get backupRestoreSubtitle => 'Add agendas from a Honeyday backup file';

  @override
  String get backupWorking => 'Working…';

  @override
  String get backupReady => 'Backup file prepared.';

  @override
  String get backupError =>
      'The backup operation failed. Your existing agendas have not been replaced. Try again.';

  @override
  String get backupInvalid =>
      'This file is not a valid supported Honeyday backup, or exceeds the 50 MiB limit.';

  @override
  String get backupConfirmTitle => 'Import these agendas?';

  @override
  String backupConfirmDescription(
    int agendas,
    int pages,
    int elements,
    int strokes,
  ) {
    return 'Agendas: $agendas\nPages: $pages\nElements: $elements\nInk strokes: $strokes\n\nNew independent copies will be added. Existing agendas will not be changed. Importing the same file again creates additional copies.';
  }

  @override
  String get backupConfirm => 'Import copies';

  @override
  String backupRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count agendas.',
      one: 'Imported 1 agenda.',
    );
    return '$_temp0';
  }

  @override
  String get backupEmpty => 'This backup does not contain any agendas.';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLicenses => 'Licenses';

  @override
  String get settingsLicensesSubtitle => 'Review open source licenses';

  @override
  String get settingsAccentBeeHoney => 'Honey bee';

  @override
  String get settingsAccentLavender => 'Lavender';

  @override
  String get settingsAccentSage => 'Sage';

  @override
  String get settingsAccentRose => 'Rose';

  @override
  String get settingsAccentOcean => 'Ocean';

  @override
  String get settingsAccentBrick => 'Brick';

  @override
  String get settingsAccentGray => 'Gray';

  @override
  String get settingsAccentTeal => 'Teal';

  @override
  String get homeTitle => 'Honeyday';

  @override
  String get homeErrorLoading => 'Error loading agendas';

  @override
  String get homeEmptyTitle => 'No agendas';

  @override
  String get homeEmptyBody => 'Tap + to create one.';

  @override
  String get agendaRename => 'Rename agenda';

  @override
  String get agendaTitleRequired => 'Enter a title.';

  @override
  String get agendaRenameError =>
      'Could not rename the agenda. Your title is still here; try again.';

  @override
  String get agendaDeleteTitle => 'Delete agenda?';

  @override
  String agendaDeleteContent(Object title) {
    return '\"$title\" and all its associated pages will be deleted.';
  }

  @override
  String get agendaExitTitle => 'Leave without saving?';

  @override
  String get agendaExitContent =>
      'You have unsaved changes. What would you like to do?';

  @override
  String get agendaDiscard => 'Discard';

  @override
  String get agendaSave => 'Save';

  @override
  String agendaPagesError(Object error) {
    return 'Error loading pages: $error';
  }

  @override
  String get agendaSaveError => 'Could not save your changes. Try again.';

  @override
  String get agendaNoPages => 'No pages available.';

  @override
  String get agendaNewDefaultTitle => 'My Agenda 2026';

  @override
  String get agendaNewTitle => 'New Agenda';

  @override
  String get agendaNewHint => 'Title';

  @override
  String get agendaPageDesignLines => 'Lines';

  @override
  String get agendaPageDesignDots => 'Dots';

  @override
  String get agendaPageDesignBlank => 'Blank';

  @override
  String get agendaPageDesignGrid => 'Grid';

  @override
  String get agendaPageDeleteTitle => 'Delete page?';

  @override
  String agendaPageDeleteContent(Object index) {
    return 'Page $index will be deleted. This action cannot be undone.';
  }

  @override
  String agendaPageCount(Object count) {
    return 'Pages ($count)';
  }

  @override
  String get agendaPageDuplicate => 'Duplicate page';

  @override
  String get agendaPageDuplicated => 'Page duplicated after the original.';

  @override
  String get agendaPageAdd => 'Add page';

  @override
  String get agendaModeRead => 'Read mode';

  @override
  String get agendaModeEdit => 'Edit mode';

  @override
  String agendaPageBadge(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '$count page',
    );
    return '$_temp0';
  }

  @override
  String get agendaDeleteTooltip => 'Delete agenda';

  @override
  String get catalogFilterAll => 'All';

  @override
  String get catalogFilterShapes => 'Shapes';

  @override
  String get catalogFilterTemplates => 'Templates';

  @override
  String get catalogFilterDecoration => 'Decoration';

  @override
  String get catalogElementsHeader => 'Elements';

  @override
  String get onboardingStep1Title => 'Organize your life';

  @override
  String get onboardingStep1Desc =>
      'Create personalized agendas for every area of your life:\nfinances, habits, projects, and more.';

  @override
  String get onboardingStep2Title => 'Draw freely';

  @override
  String get onboardingStep2Desc =>
      'Write by hand, draw, highlight, and use ink tools\nwith pressure precision.';

  @override
  String get onboardingStep3Title => 'Customize everything';

  @override
  String get onboardingStep3Desc =>
      'Add templates, stickers, shapes, and elements\nto create the perfect agenda.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingNext => 'Next';

  @override
  String get catalogShapeRectangle => 'Rectangle';

  @override
  String get catalogShapeRectangleDesc =>
      'Card or container to structure sections';

  @override
  String get catalogShapeCircle => 'Circle';

  @override
  String get catalogShapeCircleDesc => 'Aesthetic circular or elliptical shape';

  @override
  String get catalogShapeDivider => 'Divider';

  @override
  String get catalogShapeDividerDesc => 'Aesthetic dividing line for the page';

  @override
  String get catalogShapePennant => 'Banner';

  @override
  String get catalogShapePennantDesc => 'Canva-style header ribbon';

  @override
  String get catalogShapeFrame => 'Frame';

  @override
  String get catalogShapeFrameDesc =>
      'Elegant perimeter frame adaptable to the full page';

  @override
  String get catalogShapeStar => 'Star';

  @override
  String get catalogShapeStarDesc => 'Decorative geometric star';

  @override
  String get catalogShapeLabel => 'Tag';

  @override
  String get catalogShapeLabelDesc => 'Elongated shape with rounded ends';

  @override
  String get catalogShapeStickyNote => 'Sticky note';

  @override
  String get catalogShapeStickyNoteDesc =>
      'Static paper note with pin and lines to write on';

  @override
  String get catalogShapeTape => 'Decorative tape';

  @override
  String get catalogShapeTapeDesc =>
      'Semi-transparent decorative strip with design';

  @override
  String get catalogTemplateWeeklyView => 'Weekly view';

  @override
  String get catalogTemplateWeeklyViewDesc =>
      '7-day structure for planning the week by hand';

  @override
  String get catalogTemplateChecklist => 'Checklist';

  @override
  String get catalogTemplateChecklistDesc =>
      'Aesthetic checkbox list for writing tasks';

  @override
  String get catalogTemplateHabits => 'Habits';

  @override
  String get catalogTemplateHabitsDesc =>
      'Weekly tracking matrix to color with the pencil';

  @override
  String get catalogTemplatePriorities => 'Priorities';

  @override
  String get catalogTemplatePrioritiesDesc =>
      'Highlighted structure for the 3 key priorities';

  @override
  String get catalogTemplateLinedNotes => 'Lined notes';

  @override
  String get catalogTemplateLinedNotesDesc =>
      'Notes area with lines for precise writing';

  @override
  String get catalogTemplateGridNotes => 'Grid notes';

  @override
  String get catalogTemplateGridNotesDesc =>
      'Notes area with graph or subtle grid paper';

  @override
  String get catalogStickerHeart => 'Heart';

  @override
  String get catalogStickerHeartDesc => 'Decorative heart icon';

  @override
  String get catalogStickerStar => 'Decorative star';

  @override
  String get catalogStickerStarDesc => 'Decorative sparkling star icon';

  @override
  String get catalogStickerCoffee => 'Coffee';

  @override
  String get catalogStickerCoffeeDesc => 'Rest or coffee icon';

  @override
  String get catalogStickerPin => 'Push pin';

  @override
  String get catalogStickerPinDesc => 'Decorative pin for notes and cards';

  @override
  String get catalogDayMon => 'MON';

  @override
  String get catalogDayTue => 'TUE';

  @override
  String get catalogDayWed => 'WED';

  @override
  String get catalogDayThu => 'THU';

  @override
  String get catalogDayFri => 'FRI';

  @override
  String get catalogDaySat => 'SAT';

  @override
  String get catalogDaySun => 'SUN';

  @override
  String get catalogBudgetTitle => 'Budget';

  @override
  String get catalogBudgetDefaultIncome => 'Main income';

  @override
  String get catalogBudgetDefaultExpense1 => 'Rent & Utilities';

  @override
  String get catalogBudgetDefaultExpense2 => 'Groceries & Food';

  @override
  String get catalogBudgetName => 'Budget Calculator';

  @override
  String get catalogBudgetNewExpense => 'New expense';

  @override
  String get catalogBudgetIncome => 'Income';

  @override
  String get catalogBudgetExpenses => 'Expenses';

  @override
  String get catalogBudgetBalance => 'Balance';

  @override
  String get catalogBudgetAddEntry => 'New entry';

  @override
  String get catalogHabitsTitle => 'Weekly Habits';

  @override
  String get catalogHabitsDefault1 => 'Drink 2L of water';

  @override
  String get catalogHabitsDefault2 => 'Read 20 minutes';

  @override
  String get catalogHabitsDefault3 => 'Daily exercise';

  @override
  String get catalogHabitsName => 'Grid with Days';

  @override
  String get catalogHabitsDayMon => 'M';

  @override
  String get catalogHabitsDayTue => 'T';

  @override
  String get catalogHabitsDayWed => 'W';

  @override
  String get catalogHabitsDayThu => 'T';

  @override
  String get catalogHabitsDayFri => 'F';

  @override
  String get catalogHabitsDaySat => 'S';

  @override
  String get catalogHabitsDaySun => 'S';

  @override
  String get catalogHabitsNew => 'New habit';

  @override
  String get catalogHabitsAdd => 'Add habit';

  @override
  String get catalogJournalToday => 'Today';

  @override
  String get catalogJournalDefaultDate => 'Friday, September 11';

  @override
  String get catalogJournalPriority1 => 'Complete key daily goals';

  @override
  String get catalogJournalPriority2 => 'Time for disconnecting and reading';

  @override
  String get catalogJournalPriority3 => 'Plan next week';

  @override
  String get catalogJournalDefaultNotes =>
      'Today\'s reflections and learnings...';

  @override
  String get catalogJournalName => 'Daily / Weekly Entry';

  @override
  String get catalogJournalPrioritiesHeader => 'Today\'s Priorities';

  @override
  String get catalogJournalNotesHeader => 'Notes & Reflection';

  @override
  String get catalogJournalNotesHint =>
      'Write your thoughts for the day here...';

  @override
  String get catalogJournalNoNotes => 'No notes for this day.';

  @override
  String get catalogColorHoney => 'Honey';

  @override
  String get catalogColorPink => 'Pink';

  @override
  String get catalogColorSage => 'Sage';

  @override
  String get catalogColorTransparent => 'Transparent';

  @override
  String get catalogTextboxDefaultContent =>
      'Important note!\nWrite your ideas or reminders here.';

  @override
  String get catalogTextboxName => 'Text Note';

  @override
  String get catalogTextboxHint => 'Write your note here...';

  @override
  String get catalogChecklistHeader => 'CHECKLIST';

  @override
  String get catalogHabitsHeader => 'WEEKLY HABITS';

  @override
  String get catalogPrioritiesHeader => 'PRIORITIES';

  @override
  String get paperStyleDots => 'Dots';

  @override
  String get paperStyleLines => 'Lines';

  @override
  String get paperStyleGrid => 'Grid';

  @override
  String get paperStyleBlank => 'Blank';

  @override
  String catalogErrorUnknownWidget(Object widgetType) {
    return 'Unrecognized widget: $widgetType';
  }

  @override
  String get canvasModularWidgetContainer => 'Modular Widget Container';

  @override
  String get exportPdfTooltip => 'Export to PDF';

  @override
  String get exportDialogTitle => 'Export to PDF';

  @override
  String get exportFormatLabel => 'Page size';

  @override
  String get exportFormatLetter => 'Letter';

  @override
  String get exportIncludeContentLabel => 'Include typed text';

  @override
  String exportPagesSummary(int count) {
    return '$count pages · 300 dpi';
  }

  @override
  String get exportStart => 'Export';

  @override
  String get exportProgressTitle => 'Exporting…';

  @override
  String exportProgressPage(int current, int total) {
    return 'Rendering page $current of $total';
  }

  @override
  String get exportPhaseCapturing => 'Rendering pages';

  @override
  String get exportPhaseCompressing => 'Compressing images…';

  @override
  String get exportPhaseWriting => 'Writing the PDF…';

  @override
  String get exportError => 'The export failed. Please try again.';

  @override
  String get exportErrorBackground =>
      'Honeyday could not render the pages because the window was in the background. Bring it to the front and try again.';

  @override
  String get agendaSaved => 'Saved';

  @override
  String get agendaSaving => 'Saving…';

  @override
  String get agendaRetrySave => 'Save failed. Retry';

  @override
  String get canvasInputContent => 'Content';

  @override
  String get canvasInputInk => 'Ink';
}
