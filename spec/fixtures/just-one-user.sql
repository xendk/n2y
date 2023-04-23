PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE micrate_db_version (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                version_id INTEGER NOT NULL,
                is_applied INTEGER NOT NULL,
                tstamp TIMESTAMP
            );
INSERT INTO micrate_db_version VALUES(1,20230421215116,1,'2023-04-23 12:42:23.352');
CREATE TABLE users (
  mail VARCHAR(255) NOT NULL PRIMARY KEY
);
INSERT INTO users VALUES('existing-user@gmail.com');
DELETE FROM sqlite_sequence;
INSERT INTO sqlite_sequence VALUES('micrate_db_version',1);
COMMIT;
