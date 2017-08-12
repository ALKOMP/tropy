--
-- This file is auto-generated by executing all current
-- migrations. Instead of editing this file, please create
-- migrations to incrementally modify the database, and
-- then regenerate this schema file.
--
-- To create a new empty migration, run:
--   node scripts/db migration -- project [name] [sql|js]
--
-- To re-generate this file, run:
--   node scripts/db migrate
--

-- Save the current migration number
PRAGMA user_version=1708121306;

-- Load sqlite3 .dump
PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE project (
  project_id  TEXT     NOT NULL PRIMARY KEY,
  name        TEXT     NOT NULL,
  created     NUMERIC  NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CHECK (project_id != ''),
  CHECK (name != '')

) WITHOUT ROWID;
CREATE TABLE access (
  uuid        TEXT     NOT NULL,
  version     TEXT     NOT NULL,
  path        TEXT     NOT NULL,
  opened      NUMERIC  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  closed      NUMERIC,
  CHECK (uuid != '' AND version != '' AND path != '')
);
CREATE TABLE subjects (
  id           INTEGER  PRIMARY KEY,
  template     TEXT     NOT NULL DEFAULT 'https://tropy.org/v1/templates/item',
  type         TEXT,
  created      NUMERIC  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  modified     NUMERIC  NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE images (
  id      INTEGER  PRIMARY KEY REFERENCES subjects ON DELETE CASCADE,
  width   INTEGER  NOT NULL DEFAULT 0,
  height  INTEGER  NOT NULL DEFAULT 0,
  angle   NUMERIC  NOT NULL DEFAULT 0,
  mirror  BOOLEAN  NOT NULL DEFAULT 0,

  CHECK (angle >= 0 AND angle <= 360),
  CHECK (width >= 0 AND height >= 0)

) WITHOUT ROWID;
CREATE TABLE photos (
  id           INTEGER  PRIMARY KEY REFERENCES images ON DELETE CASCADE,
  item_id      INTEGER  NOT NULL REFERENCES items ON DELETE CASCADE,
  position     INTEGER,
  path         TEXT     NOT NULL,
  protocol     TEXT     NOT NULL DEFAULT 'file',
  mimetype     TEXT     NOT NULL,
  checksum     TEXT     NOT NULL,
  orientation  INTEGER  NOT NULL DEFAULT 1,
  metadata     TEXT     NOT NULL DEFAULT '{}', size INTEGER NOT NULL DEFAULT 0,

  CHECK (orientation > 0 AND orientation < 9)
) WITHOUT ROWID;
CREATE TABLE items (
  id              INTEGER  PRIMARY KEY REFERENCES subjects ON DELETE CASCADE,
  cover_image_id  INTEGER  REFERENCES images ON DELETE SET NULL
) WITHOUT ROWID;
CREATE TABLE metadata (
  id          INTEGER  NOT NULL REFERENCES subjects ON DELETE CASCADE,
  property    TEXT     NOT NULL,
  value_id    INTEGER  NOT NULL REFERENCES metadata_values,
  language    TEXT,
  created     NUMERIC  NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CHECK (
    language IS NULL OR language != '' AND language = trim(lower(language))
  ),

  PRIMARY KEY (id, property)
) WITHOUT ROWID;
CREATE TABLE metadata_values (
  value_id   INTEGER  PRIMARY KEY,
  datatype   TEXT     NOT NULL,
  text                NOT NULL,
  data       TEXT,

  CHECK (datatype != ''),
  UNIQUE (datatype, text)
);
CREATE TABLE notes (
  note_id      INTEGER  PRIMARY KEY,
  id           INTEGER  REFERENCES subjects ON DELETE CASCADE,
  text         TEXT     NOT NULL,
  state        TEXT     NOT NULL,
  language     TEXT     NOT NULL DEFAULT 'en',
  created      NUMERIC  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  modified     NUMERIC  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted      NUMERIC,

  CHECK (
    language != '' AND language = trim(lower(language))
  ),
  CHECK (text != '')
);
CREATE TABLE lists (
  list_id         INTEGER  PRIMARY KEY,
  name            TEXT     NOT NULL COLLATE NOCASE,
  parent_list_id  INTEGER  DEFAULT 0 REFERENCES lists ON DELETE CASCADE,
  position        INTEGER,
  created         NUMERIC  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  modified        NUMERIC  NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CHECK (list_id != parent_list_id),
  CHECK (name != ''),

  UNIQUE (parent_list_id, name)
);
INSERT INTO "lists" VALUES(0,'ROOT',NULL,NULL,'2017-01-31 12:00:00','2017-01-31 12:00:00');
CREATE TABLE list_items (
  list_id  INTEGER  REFERENCES lists ON DELETE CASCADE,
  id       INTEGER  REFERENCES items ON DELETE CASCADE,
  position INTEGER,
  added    NUMERIC  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted  NUMERIC,

  PRIMARY KEY (list_id, id)
) WITHOUT ROWID;
CREATE TABLE tags (
  tag_id      INTEGER  PRIMARY KEY,
  name        TEXT     NOT NULL COLLATE NOCASE,
  color,
  created     NUMERIC  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  modified    NUMERIC  NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CHECK (name != ''),
  UNIQUE (name)
);
CREATE TABLE taggings (
  tag_id     INTEGER  NOT NULL REFERENCES tags ON DELETE CASCADE,
  id         INTEGER  NOT NULL REFERENCES subjects ON DELETE CASCADE,
  PRIMARY KEY (id, tag_id)
) WITHOUT ROWID;
CREATE TABLE trash (
  id          INTEGER  PRIMARY KEY REFERENCES subjects ON DELETE CASCADE,
  deleted     NUMERIC  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reason      TEXT     NOT NULL DEFAULT 'user',

  CHECK (reason IN ('user', 'auto', 'merge'))
) WITHOUT ROWID;
PRAGMA writable_schema=ON;
INSERT INTO sqlite_master(type,name,tbl_name,rootpage,sql)VALUES('table','fts_notes','fts_notes',0,'CREATE VIRTUAL TABLE fts_notes USING fts5(
  id UNINDEXED,
  text,
  language UNINDEXED,
  content = ''notes'',
  content_rowid = ''note_id'',
  tokenize = ''porter unicode61''
)');
CREATE TABLE 'fts_notes_data'(id INTEGER PRIMARY KEY, block BLOB);
INSERT INTO "fts_notes_data" VALUES(1,X'');
INSERT INTO "fts_notes_data" VALUES(10,X'00000000000000');
CREATE TABLE 'fts_notes_idx'(segid, term, pgno, PRIMARY KEY(segid, term)) WITHOUT ROWID;
CREATE TABLE 'fts_notes_docsize'(id INTEGER PRIMARY KEY, sz BLOB);
CREATE TABLE 'fts_notes_config'(k PRIMARY KEY, v) WITHOUT ROWID;
INSERT INTO "fts_notes_config" VALUES('version',4);
INSERT INTO sqlite_master(type,name,tbl_name,rootpage,sql)VALUES('table','fts_metadata','fts_metadata',0,'CREATE VIRTUAL TABLE fts_metadata USING fts5(
  datatype UNINDEXED,
  text,
  content = ''metadata_values'',
  content_rowid = ''value_id'',
  tokenize = ''porter unicode61''
)');
CREATE TABLE 'fts_metadata_data'(id INTEGER PRIMARY KEY, block BLOB);
INSERT INTO "fts_metadata_data" VALUES(1,X'');
INSERT INTO "fts_metadata_data" VALUES(10,X'00000000000000');
CREATE TABLE 'fts_metadata_idx'(segid, term, pgno, PRIMARY KEY(segid, term)) WITHOUT ROWID;
CREATE TABLE 'fts_metadata_docsize'(id INTEGER PRIMARY KEY, sz BLOB);
CREATE TABLE 'fts_metadata_config'(k PRIMARY KEY, v) WITHOUT ROWID;
INSERT INTO "fts_metadata_config" VALUES('version',4);
CREATE TABLE selections (
  id        INTEGER  PRIMARY KEY REFERENCES images ON DELETE CASCADE,
  photo_id  INTEGER  NOT NULL REFERENCES photos ON DELETE CASCADE,
  x         NUMERIC  NOT NULL DEFAULT 0,
  y         NUMERIC  NOT NULL DEFAULT 0,
  position  INTEGER

) WITHOUT ROWID;
CREATE TRIGGER insert_tags_trim_name
  AFTER INSERT ON tags
  BEGIN
    UPDATE tags SET name = trim(name)
      WHERE tag_id = NEW.tag_id;
  END;
CREATE TRIGGER update_tags_trim_name
  AFTER UPDATE OF name ON tags
  BEGIN
    UPDATE tags SET name = trim(name)
      WHERE tag_id = NEW.tag_id;
  END;
CREATE TRIGGER insert_lists_trim_name
  AFTER INSERT ON lists
  BEGIN
    UPDATE lists SET name = trim(name)
      WHERE list_id = NEW.list_id;
  END;
CREATE TRIGGER update_lists_trim_name
  AFTER UPDATE OF name ON lists
  BEGIN
    UPDATE lists SET name = trim(name)
      WHERE list_id = NEW.list_id;
  END;
CREATE TRIGGER update_lists_cycle_check
  BEFORE UPDATE OF parent_list_id ON lists
  FOR EACH ROW WHEN NEW.parent_list_id NOT NULL
  BEGIN
    SELECT CASE (
        WITH RECURSIVE
          ancestors(id) AS (
            SELECT parent_list_id
              FROM lists
              WHERE list_id = OLD.list_id
            UNION
            SELECT parent_list_id
              FROM lists, ancestors
              WHERE lists.list_id = ancestors.id
          )
          SELECT count(*) FROM ancestors WHERE id = OLD.list_id LIMIT 1
      )
      WHEN 1 THEN
        RAISE(ABORT, 'Lists may not contain cycles')
      END;
  END;
CREATE TRIGGER update_metadata_values_abort
  BEFORE UPDATE ON metadata_values
  BEGIN
    SELECT RAISE(ABORT, 'Metadata values should never be updated');
  END;
CREATE TRIGGER notes_ai_fts
  AFTER INSERT ON notes
  BEGIN
    INSERT INTO fts_notes (rowid, id, text, language)
      VALUES (NEW.note_id, NEW.id, NEW.text, NEW.language);
  END;
CREATE TRIGGER notes_ad_fts
  AFTER DELETE ON notes
  BEGIN
    INSERT INTO fts_notes (fts_notes, rowid, id, text, language)
      VALUES ('delete', OLD.note_id, OLD.id, OLD.text, OLD.language);
  END;
CREATE TRIGGER notes_au_fts
  AFTER UPDATE OF text ON notes
  BEGIN
    INSERT INTO fts_notes (fts_notes, rowid, id, text, language)
      VALUES ('delete', OLD.note_id, OLD.id, OLD.text, OLD.language);
    INSERT INTO fts_notes (rowid, id, text, language)
      VALUES (NEW.note_id, NEW.id, NEW.text, NEW.language);
  END;
CREATE TRIGGER metadata_values_ai_fts
  AFTER INSERT ON metadata_values
  FOR EACH ROW WHEN NEW.datatype NOT IN (
    'http://www.w3.org/2001/XMLSchema#boolean',
    'http://www.w3.org/2001/XMLSchema#hexBinary',
    'http://www.w3.org/2001/XMLSchema#base64Binary',
    'http://www.w3.org/1999/02/22-rdf-syntax-ns#HTML',
    'http://www.w3.org/1999/02/22-rdf-syntax-ns#langString',
    'http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral')
  BEGIN
    INSERT INTO fts_metadata (rowid, datatype, text)
      VALUES (NEW.value_id, NEW.datatype, NEW.text);
  END;
CREATE TRIGGER metadata_values_ad_fts
  AFTER DELETE ON metadata_values
  FOR EACH ROW WHEN OLD.datatype NOT IN (
    'http://www.w3.org/2001/XMLSchema#boolean',
    'http://www.w3.org/2001/XMLSchema#hexBinary',
    'http://www.w3.org/2001/XMLSchema#base64Binary',
    'http://www.w3.org/1999/02/22-rdf-syntax-ns#HTML',
    'http://www.w3.org/1999/02/22-rdf-syntax-ns#langString',
    'http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral')
  BEGIN
    INSERT INTO fts_metadata (fts_metadata, rowid, datatype, text)
      VALUES ('delete', OLD.value_id, OLD.datatype, OLD.text);
  END;
CREATE INDEX idx_photos_checksum ON photos (checksum);
PRAGMA writable_schema=OFF;
COMMIT;
PRAGMA foreign_keys=ON;