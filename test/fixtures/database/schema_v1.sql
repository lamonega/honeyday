-- Historical v1 layout: before the four v2 read indexes were introduced.
-- Keep this fixture independent of the current generated schema. Timestamps
-- are SQLite/Drift epoch seconds, not JavaScript epoch milliseconds.
CREATE TABLE agendas (
  id TEXT NOT NULL PRIMARY KEY,
  title TEXT NOT NULL,
  cover_style TEXT NOT NULL DEFAULT 'honey',
  page_count INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  is_deleted INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted IN (0, 1))
);
CREATE TABLE pages (
  id TEXT NOT NULL PRIMARY KEY,
  agenda_id TEXT NOT NULL REFERENCES agendas(id),
  page_number INTEGER NOT NULL,
  background_style TEXT NOT NULL DEFAULT 'dotted',
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  is_deleted INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted IN (0, 1))
);
CREATE TABLE canvas_elements (
  id TEXT NOT NULL PRIMARY KEY,
  page_id TEXT NOT NULL REFERENCES pages(id),
  widget_type TEXT NOT NULL,
  pos_x REAL NOT NULL DEFAULT 0,
  pos_y REAL NOT NULL DEFAULT 0,
  width REAL NOT NULL DEFAULT 220,
  height REAL NOT NULL DEFAULT 180,
  rotation REAL NOT NULL DEFAULT 0,
  config_json TEXT NOT NULL DEFAULT '{}',
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  is_deleted INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted IN (0, 1))
);
CREATE TABLE strokes (
  id TEXT NOT NULL PRIMARY KEY,
  page_id TEXT NOT NULL REFERENCES pages(id),
  brush_type TEXT NOT NULL DEFAULT 'pen',
  color_hex TEXT NOT NULL DEFAULT '#1E293B',
  stroke_width REAL NOT NULL DEFAULT 3,
  points_json TEXT NOT NULL DEFAULT '[]',
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  is_deleted INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted IN (0, 1))
);
INSERT INTO agendas (id, title, cover_style, created_at, updated_at)
VALUES ('agenda-v1', 'Diario anterior 🐝', 'lavender', 1735689600, 1735776000);
INSERT INTO pages (id, agenda_id, page_number, background_style, created_at, updated_at)
VALUES ('page-v1', 'agenda-v1', 1, 'grid', 1735689600, 1735776000);
INSERT INTO canvas_elements (id, page_id, widget_type, pos_x, pos_y, width, height, rotation, config_json, created_at, updated_at)
VALUES ('element-v1', 'page-v1', 'text_box', 12.5, 24, 200, 100, 0.25, '{"text":"Do not lose me"}', 1735689600, 1735776000);
INSERT INTO strokes (id, page_id, brush_type, color_hex, stroke_width, points_json, created_at, updated_at)
VALUES ('stroke-v1', 'page-v1', 'highlighter', '#80FFD977', 9, '[{"x":1.2,"y":3.4,"p":0.6}]', 1735689600, 1735776000);
INSERT INTO agendas (id, title, is_deleted, created_at, updated_at)
VALUES ('deleted-v1', 'Deleted agenda', 1, 1735689600, 1735776000);
INSERT INTO pages (id, agenda_id, page_number, is_deleted, created_at, updated_at)
VALUES ('deleted-page-v1', 'deleted-v1', 1, 1, 1735689600, 1735776000);
PRAGMA user_version = 1;
