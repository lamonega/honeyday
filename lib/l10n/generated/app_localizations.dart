import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('es'),
    Locale('en'),
  ];

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Create button
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get commonCreate;

  /// App title / brand name
  ///
  /// In en, this message translates to:
  /// **'Honeyday'**
  String get appTitle;

  /// Bottom navigation label for home
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation label for settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// AppBar title for settings page
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Section header for general settings
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// Switch title for dark mode toggle
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get settingsDarkMode;

  /// Automatic (system)
  ///
  /// In en, this message translates to:
  /// **'Automatic (system)'**
  String get settingsThemeSystem;

  /// On
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get settingsThemeOn;

  /// Off
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsThemeOff;

  /// List tile title AND dialog title for accent color
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get settingsAccentColor;

  /// Subtitle when a custom accent color is selected
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get settingsAccentCustom;

  /// Section header for about settings
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// List tile title for app version
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// List tile title for open source licenses
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get settingsLicenses;

  /// Subtitle for licenses list tile
  ///
  /// In en, this message translates to:
  /// **'Review open source licenses'**
  String get settingsLicensesSubtitle;

  /// Honey bee
  ///
  /// In en, this message translates to:
  /// **'Honey bee'**
  String get settingsAccentBeeHoney;

  /// Accent color preset name
  ///
  /// In en, this message translates to:
  /// **'Lavender'**
  String get settingsAccentLavender;

  /// Accent color preset name
  ///
  /// In en, this message translates to:
  /// **'Sage'**
  String get settingsAccentSage;

  /// Accent color preset name
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get settingsAccentRose;

  /// Accent color preset name
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get settingsAccentOcean;

  /// Accent color preset name
  ///
  /// In en, this message translates to:
  /// **'Brick'**
  String get settingsAccentBrick;

  /// Accent color preset name
  ///
  /// In en, this message translates to:
  /// **'Gray'**
  String get settingsAccentGray;

  /// Accent color preset name
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get settingsAccentTeal;

  /// AppBar title on the home page
  ///
  /// In en, this message translates to:
  /// **'Honeyday'**
  String get homeTitle;

  /// Error loading agendas
  ///
  /// In en, this message translates to:
  /// **'Error loading agendas'**
  String get homeErrorLoading;

  /// Empty state heading
  ///
  /// In en, this message translates to:
  /// **'No agendas'**
  String get homeEmptyTitle;

  /// Empty state body text
  ///
  /// In en, this message translates to:
  /// **'Tap + to create one.'**
  String get homeEmptyBody;

  /// Delete agenda?
  ///
  /// In en, this message translates to:
  /// **'Delete agenda?'**
  String get agendaDeleteTitle;

  /// "{title}" and all its associated pages will be deleted.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" and all its associated pages will be deleted.'**
  String agendaDeleteContent(Object title);

  /// Leave without saving?
  ///
  /// In en, this message translates to:
  /// **'Leave without saving?'**
  String get agendaExitTitle;

  /// You have unsaved changes. What would you like to do?
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. What would you like to do?'**
  String get agendaExitContent;

  /// Discard
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get agendaDiscard;

  /// Save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get agendaSave;

  /// Error loading pages: {error}
  ///
  /// In en, this message translates to:
  /// **'Error loading pages: {error}'**
  String agendaPagesError(Object error);

  /// No pages available.
  ///
  /// In en, this message translates to:
  /// **'No pages available.'**
  String get agendaNoPages;

  /// My Agenda 2026
  ///
  /// In en, this message translates to:
  /// **'My Agenda 2026'**
  String get agendaNewDefaultTitle;

  /// New Agenda
  ///
  /// In en, this message translates to:
  /// **'New Agenda'**
  String get agendaNewTitle;

  /// Title
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get agendaNewHint;

  /// Lines
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get agendaPageDesignLines;

  /// Dots
  ///
  /// In en, this message translates to:
  /// **'Dots'**
  String get agendaPageDesignDots;

  /// Blank
  ///
  /// In en, this message translates to:
  /// **'Blank'**
  String get agendaPageDesignBlank;

  /// Grid
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get agendaPageDesignGrid;

  /// Delete page?
  ///
  /// In en, this message translates to:
  /// **'Delete page?'**
  String get agendaPageDeleteTitle;

  /// Page {index} will be deleted. This action cannot be undone.
  ///
  /// In en, this message translates to:
  /// **'Page {index} will be deleted. This action cannot be undone.'**
  String agendaPageDeleteContent(Object index);

  /// Pages ({count})
  ///
  /// In en, this message translates to:
  /// **'Pages ({count})'**
  String agendaPageCount(Object count);

  /// Add page
  ///
  /// In en, this message translates to:
  /// **'Add page'**
  String get agendaPageAdd;

  /// Read mode
  ///
  /// In en, this message translates to:
  /// **'Read mode'**
  String get agendaModeRead;

  /// Edit mode
  ///
  /// In en, this message translates to:
  /// **'Edit mode'**
  String get agendaModeEdit;

  /// {count, plural, =1{# page} other{# pages}}
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{# page} other{# pages}}'**
  String agendaPageBadge(num count);

  /// Delete agenda
  ///
  /// In en, this message translates to:
  /// **'Delete agenda'**
  String get agendaDeleteTooltip;

  /// Filter chip to show all items
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get catalogFilterAll;

  /// Filter chip for shapes category
  ///
  /// In en, this message translates to:
  /// **'Shapes'**
  String get catalogFilterShapes;

  /// Filter chip for templates category
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get catalogFilterTemplates;

  /// Filter chip for decoration category
  ///
  /// In en, this message translates to:
  /// **'Decoration'**
  String get catalogFilterDecoration;

  /// Section header for elements list
  ///
  /// In en, this message translates to:
  /// **'Elements'**
  String get catalogElementsHeader;

  /// Filter chip for agenda category in resource catalog sidebar
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get catalogFilterAgenda;

  /// Filter chip for stickers category in resource catalog sidebar
  ///
  /// In en, this message translates to:
  /// **'Stickers'**
  String get catalogFilterStickers;

  /// Onboarding step 1 title
  ///
  /// In en, this message translates to:
  /// **'Organize your life'**
  String get onboardingStep1Title;

  /// Create personalized agendas for every area of your life:\nfinances, habits, projects, and more.
  ///
  /// In en, this message translates to:
  /// **'Create personalized agendas for every area of your life:\\nfinances, habits, projects, and more.'**
  String get onboardingStep1Desc;

  /// Onboarding step 2 title
  ///
  /// In en, this message translates to:
  /// **'Draw freely'**
  String get onboardingStep2Title;

  /// Write by hand, draw, highlight, and use ink tools\nwith pressure precision.
  ///
  /// In en, this message translates to:
  /// **'Write by hand, draw, highlight, and use ink tools\\nwith pressure precision.'**
  String get onboardingStep2Desc;

  /// Onboarding step 3 title
  ///
  /// In en, this message translates to:
  /// **'Customize everything'**
  String get onboardingStep3Title;

  /// Add templates, stickers, shapes, and elements\nto create the perfect agenda.
  ///
  /// In en, this message translates to:
  /// **'Add templates, stickers, shapes, and elements\\nto create the perfect agenda.'**
  String get onboardingStep3Desc;

  /// Skip button on onboarding
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// Get started button on the last onboarding page
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingStart;

  /// Next button on non-last onboarding pages
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// Rectangle
  ///
  /// In en, this message translates to:
  /// **'Rectangle'**
  String get catalogShapeRectangle;

  /// Card or container to structure sections
  ///
  /// In en, this message translates to:
  /// **'Card or container to structure sections'**
  String get catalogShapeRectangleDesc;

  /// Circle
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get catalogShapeCircle;

  /// Aesthetic circular or elliptical shape
  ///
  /// In en, this message translates to:
  /// **'Aesthetic circular or elliptical shape'**
  String get catalogShapeCircleDesc;

  /// Divider
  ///
  /// In en, this message translates to:
  /// **'Divider'**
  String get catalogShapeDivider;

  /// Aesthetic dividing line for the page
  ///
  /// In en, this message translates to:
  /// **'Aesthetic dividing line for the page'**
  String get catalogShapeDividerDesc;

  /// Banner
  ///
  /// In en, this message translates to:
  /// **'Banner'**
  String get catalogShapePennant;

  /// Canva-style header ribbon
  ///
  /// In en, this message translates to:
  /// **'Canva-style header ribbon'**
  String get catalogShapePennantDesc;

  /// Frame
  ///
  /// In en, this message translates to:
  /// **'Frame'**
  String get catalogShapeFrame;

  /// Elegant perimeter frame adaptable to the full page
  ///
  /// In en, this message translates to:
  /// **'Elegant perimeter frame adaptable to the full page'**
  String get catalogShapeFrameDesc;

  /// Star
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get catalogShapeStar;

  /// Decorative geometric star
  ///
  /// In en, this message translates to:
  /// **'Decorative geometric star'**
  String get catalogShapeStarDesc;

  /// Tag
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get catalogShapeLabel;

  /// Elongated shape with rounded ends
  ///
  /// In en, this message translates to:
  /// **'Elongated shape with rounded ends'**
  String get catalogShapeLabelDesc;

  /// Sticky note
  ///
  /// In en, this message translates to:
  /// **'Sticky note'**
  String get catalogShapeStickyNote;

  /// Static paper note with pin and lines to write on
  ///
  /// In en, this message translates to:
  /// **'Static paper note with pin and lines to write on'**
  String get catalogShapeStickyNoteDesc;

  /// Decorative tape
  ///
  /// In en, this message translates to:
  /// **'Decorative tape'**
  String get catalogShapeTape;

  /// Semi-transparent decorative strip with design
  ///
  /// In en, this message translates to:
  /// **'Semi-transparent decorative strip with design'**
  String get catalogShapeTapeDesc;

  /// Weekly view
  ///
  /// In en, this message translates to:
  /// **'Weekly view'**
  String get catalogTemplateWeeklyView;

  /// 7-day structure for planning the week by hand
  ///
  /// In en, this message translates to:
  /// **'7-day structure for planning the week by hand'**
  String get catalogTemplateWeeklyViewDesc;

  /// Checklist
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get catalogTemplateChecklist;

  /// Aesthetic checkbox list for writing tasks
  ///
  /// In en, this message translates to:
  /// **'Aesthetic checkbox list for writing tasks'**
  String get catalogTemplateChecklistDesc;

  /// CHECKLIST
  ///
  /// In en, this message translates to:
  /// **'CHECKLIST'**
  String get catalogTemplateChecklistHeader;

  /// Habits
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get catalogTemplateHabits;

  /// Weekly tracking matrix to color with the pencil
  ///
  /// In en, this message translates to:
  /// **'Weekly tracking matrix to color with the pencil'**
  String get catalogTemplateHabitsDesc;

  /// WEEKLY HABITS
  ///
  /// In en, this message translates to:
  /// **'WEEKLY HABITS'**
  String get catalogTemplateHabitsHeader;

  /// Priorities
  ///
  /// In en, this message translates to:
  /// **'Priorities'**
  String get catalogTemplatePriorities;

  /// Highlighted structure for the 3 key priorities
  ///
  /// In en, this message translates to:
  /// **'Highlighted structure for the 3 key priorities'**
  String get catalogTemplatePrioritiesDesc;

  /// PRIORITIES
  ///
  /// In en, this message translates to:
  /// **'PRIORITIES'**
  String get catalogTemplatePrioritiesHeader;

  /// Lined notes
  ///
  /// In en, this message translates to:
  /// **'Lined notes'**
  String get catalogTemplateLinedNotes;

  /// Notes area with lines for precise writing
  ///
  /// In en, this message translates to:
  /// **'Notes area with lines for precise writing'**
  String get catalogTemplateLinedNotesDesc;

  /// Grid notes
  ///
  /// In en, this message translates to:
  /// **'Grid notes'**
  String get catalogTemplateGridNotes;

  /// Notes area with graph or subtle grid paper
  ///
  /// In en, this message translates to:
  /// **'Notes area with graph or subtle grid paper'**
  String get catalogTemplateGridNotesDesc;

  /// Heart
  ///
  /// In en, this message translates to:
  /// **'Heart'**
  String get catalogStickerHeart;

  /// Decorative heart icon
  ///
  /// In en, this message translates to:
  /// **'Decorative heart icon'**
  String get catalogStickerHeartDesc;

  /// Decorative star
  ///
  /// In en, this message translates to:
  /// **'Decorative star'**
  String get catalogStickerStar;

  /// Decorative sparkling star icon
  ///
  /// In en, this message translates to:
  /// **'Decorative sparkling star icon'**
  String get catalogStickerStarDesc;

  /// Coffee
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get catalogStickerCoffee;

  /// Rest or coffee icon
  ///
  /// In en, this message translates to:
  /// **'Rest or coffee icon'**
  String get catalogStickerCoffeeDesc;

  /// Push pin
  ///
  /// In en, this message translates to:
  /// **'Push pin'**
  String get catalogStickerPin;

  /// Decorative pin for notes and cards
  ///
  /// In en, this message translates to:
  /// **'Decorative pin for notes and cards'**
  String get catalogStickerPinDesc;

  /// MON
  ///
  /// In en, this message translates to:
  /// **'MON'**
  String get catalogDayMon;

  /// TUE
  ///
  /// In en, this message translates to:
  /// **'TUE'**
  String get catalogDayTue;

  /// WED
  ///
  /// In en, this message translates to:
  /// **'WED'**
  String get catalogDayWed;

  /// THU
  ///
  /// In en, this message translates to:
  /// **'THU'**
  String get catalogDayThu;

  /// FRI
  ///
  /// In en, this message translates to:
  /// **'FRI'**
  String get catalogDayFri;

  /// SAT
  ///
  /// In en, this message translates to:
  /// **'SAT'**
  String get catalogDaySat;

  /// SUN
  ///
  /// In en, this message translates to:
  /// **'SUN'**
  String get catalogDaySun;

  /// Budget
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get catalogBudgetTitle;

  /// Main income
  ///
  /// In en, this message translates to:
  /// **'Main income'**
  String get catalogBudgetDefaultIncome;

  /// Rent & Utilities
  ///
  /// In en, this message translates to:
  /// **'Rent & Utilities'**
  String get catalogBudgetDefaultExpense1;

  /// Groceries & Food
  ///
  /// In en, this message translates to:
  /// **'Groceries & Food'**
  String get catalogBudgetDefaultExpense2;

  /// Budget Calculator
  ///
  /// In en, this message translates to:
  /// **'Budget Calculator'**
  String get catalogBudgetName;

  /// New expense
  ///
  /// In en, this message translates to:
  /// **'New expense'**
  String get catalogBudgetNewExpense;

  /// Income
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get catalogBudgetIncome;

  /// Expenses
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get catalogBudgetExpenses;

  /// Balance
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get catalogBudgetBalance;

  /// New entry
  ///
  /// In en, this message translates to:
  /// **'New entry'**
  String get catalogBudgetAddEntry;

  /// Weekly Habits
  ///
  /// In en, this message translates to:
  /// **'Weekly Habits'**
  String get catalogHabitsTitle;

  /// Drink 2L of water
  ///
  /// In en, this message translates to:
  /// **'Drink 2L of water'**
  String get catalogHabitsDefault1;

  /// Read 20 minutes
  ///
  /// In en, this message translates to:
  /// **'Read 20 minutes'**
  String get catalogHabitsDefault2;

  /// Daily exercise
  ///
  /// In en, this message translates to:
  /// **'Daily exercise'**
  String get catalogHabitsDefault3;

  /// Grid with Days
  ///
  /// In en, this message translates to:
  /// **'Grid with Days'**
  String get catalogHabitsName;

  /// M
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get catalogHabitsDayMon;

  /// T
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get catalogHabitsDayTue;

  /// W
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get catalogHabitsDayWed;

  /// T
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get catalogHabitsDayThu;

  /// F
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get catalogHabitsDayFri;

  /// S
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get catalogHabitsDaySat;

  /// S
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get catalogHabitsDaySun;

  /// New habit
  ///
  /// In en, this message translates to:
  /// **'New habit'**
  String get catalogHabitsNew;

  /// Add habit
  ///
  /// In en, this message translates to:
  /// **'Add habit'**
  String get catalogHabitsAdd;

  /// Today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get catalogJournalToday;

  /// Friday, September 11
  ///
  /// In en, this message translates to:
  /// **'Friday, September 11'**
  String get catalogJournalDefaultDate;

  /// Complete key daily goals
  ///
  /// In en, this message translates to:
  /// **'Complete key daily goals'**
  String get catalogJournalPriority1;

  /// Time for disconnecting and reading
  ///
  /// In en, this message translates to:
  /// **'Time for disconnecting and reading'**
  String get catalogJournalPriority2;

  /// Plan next week
  ///
  /// In en, this message translates to:
  /// **'Plan next week'**
  String get catalogJournalPriority3;

  /// Today''s reflections and learnings...
  ///
  /// In en, this message translates to:
  /// **'Today\'\'s reflections and learnings...'**
  String get catalogJournalDefaultNotes;

  /// Daily / Weekly Entry
  ///
  /// In en, this message translates to:
  /// **'Daily / Weekly Entry'**
  String get catalogJournalName;

  /// Today''s Priorities
  ///
  /// In en, this message translates to:
  /// **'Today\'\'s Priorities'**
  String get catalogJournalPrioritiesHeader;

  /// Notes & Reflection
  ///
  /// In en, this message translates to:
  /// **'Notes & Reflection'**
  String get catalogJournalNotesHeader;

  /// Write your thoughts for the day here...
  ///
  /// In en, this message translates to:
  /// **'Write your thoughts for the day here...'**
  String get catalogJournalNotesHint;

  /// No notes for this day.
  ///
  /// In en, this message translates to:
  /// **'No notes for this day.'**
  String get catalogJournalNoNotes;

  /// Honey
  ///
  /// In en, this message translates to:
  /// **'Honey'**
  String get catalogColorHoney;

  /// Pink
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get catalogColorPink;

  /// Sage
  ///
  /// In en, this message translates to:
  /// **'Sage'**
  String get catalogColorSage;

  /// Transparent
  ///
  /// In en, this message translates to:
  /// **'Transparent'**
  String get catalogColorTransparent;

  /// Note...
  ///
  /// In en, this message translates to:
  /// **'Note...'**
  String get catalogTextboxDefault;

  /// Important note!\nWrite your ideas or reminders here.
  ///
  /// In en, this message translates to:
  /// **'Important note!\\nWrite your ideas or reminders here.'**
  String get catalogTextboxDefaultContent;

  /// Text Note
  ///
  /// In en, this message translates to:
  /// **'Text Note'**
  String get catalogTextboxName;

  /// Write your note here...
  ///
  /// In en, this message translates to:
  /// **'Write your note here...'**
  String get catalogTextboxHint;

  /// Header for the checklist template
  ///
  /// In en, this message translates to:
  /// **'CHECKLIST'**
  String get catalogChecklistHeader;

  /// Header for the habit tracker template
  ///
  /// In en, this message translates to:
  /// **'WEEKLY HABITS'**
  String get catalogHabitsHeader;

  /// Header for the priorities template
  ///
  /// In en, this message translates to:
  /// **'PRIORITIES'**
  String get catalogPrioritiesHeader;

  /// Dots
  ///
  /// In en, this message translates to:
  /// **'Dots'**
  String get paperStyleDots;

  /// Lines
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get paperStyleLines;

  /// Grid
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get paperStyleGrid;

  /// Blank
  ///
  /// In en, this message translates to:
  /// **'Blank'**
  String get paperStyleBlank;

  /// Unrecognized widget: {widgetType}
  ///
  /// In en, this message translates to:
  /// **'Unrecognized widget: {widgetType}'**
  String catalogErrorUnknownWidget(Object widgetType);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
