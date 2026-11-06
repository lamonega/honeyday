# Editable backups

Honeyday's **Settings → Editable backups** section can export and import all
active agendas. Unlike PDF export, a backup includes editable elements **and
handwritten ink**, so it can be used to move a library to another installation.

## Create a backup

1. Leave the agenda viewer normally, allowing pending edits to finish saving.
2. Open Settings and choose **Create backup**.
3. Save the `.honeyday` file using the desktop save dialog, browser download,
   or the Android/iOS share sheet (for example, Save to Files).
4. Keep an additional copy somewhere other than the device running Honeyday.

A successful handoff to a browser/share sheet does not prove that another app
has stored the file. Check your destination, particularly on mobile.

## Import a backup

1. Choose **Import backup** and select a `.honeyday` or `.json` file.
2. Honeyday validates the entire document and shows the agenda, page, element
   and ink-stroke counts before making any changes.
3. Confirm **Import copies**.

Import is **additive**, never a replacement: every agenda, page, element and
stroke receives a new identifier. Existing agendas are not edited or deleted.
Importing the same file twice creates two independent sets of copies. All
inserts share a transaction; a failed import leaves none of its new rows behind.

## Included and excluded data

Included:

- Active agendas, titles, cover styles and creation/modification dates.
- Active pages in their saved order, including their paper styles.
- Element geometry, rotation, types, timestamps and original configuration JSON.
- Ink brushes, colors, widths, timestamps, pressure and original point JSON.
- Unknown widget types and configuration fields (preserved, not converted).

Excluded:

- Soft-deleted agendas, pages, elements and their descendants.
- Appearance preferences, onboarding state and other app settings.
- Undo/redo history and pending changes not yet written to the database.

Backups are **plain, unencrypted JSON**. They may contain private diary entries
or financial information. Treat them as private documents. Honeyday does not
upload them, encrypt them, schedule automatic backups, or synchronize devices.

## Format and compatibility

The independent backup format is not a raw SQLite database dump. Its version
is separate from the Drift schema version. No database migration is required
for this feature.

The root contains:

- `format`: `"honeyday-backup"`.
- `version`: integer `1`.
- `exportedAt`: UTC ISO-8601 timestamp.
- `agendas`: entries with `agenda` metadata and a `pages` array.

Each page entry contains `page` metadata, `elements` and `strokes`. Dates are
UTC ISO-8601 strings, not Drift's default JSON timestamp units. Element
`configJson` and stroke `pointsJson` remain JSON strings to preserve their exact
contents. IDs and parent references are validated on input, then regenerated
on import. Page counts are derived from the included pages.

Files larger than **50 MiB** are rejected before decoding. The picker checks
file length before reading it where the platform supports that information.
Unsupported versions, malformed UTF-8/JSON, duplicate IDs/page numbers, broken
parent references, deleted rows, non-finite geometry, non-positive dimensions,
invalid configuration objects and malformed ink data are rejected rather than
partially recovered or silently discarded. Keep the original file if an import
fails; a future importer may support a newer version.

## Verification

```sh
flutter test test/features/backup
flutter test test/features/agendas/presentation/controllers/save_session_test.dart
```

Repository tests use two independent in-memory SQLite databases and exercise
round trips, repeated imports, deleted data, malformed inputs and rollback after
an injected database failure. Presentation tests replace file dialogs and the
repository to cover confirmation, cancellation, busy state, retries and unmount.
Native dialogs/share sheets and actual browser downloads still need manual
platform checks; widget tests do not exercise operating-system file UI.
