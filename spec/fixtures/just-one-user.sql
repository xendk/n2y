PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE micrate_db_version (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                version_id INTEGER NOT NULL,
                is_applied INTEGER NOT NULL,
                tstamp TIMESTAMP
            );
INSERT INTO micrate_db_version VALUES(1,20230421215116,1,'2023-04-23 12:42:23.352');
INSERT INTO micrate_db_version VALUES(2,20230603225655,1,'2023-06-04 21:07:25.739');
INSERT INTO micrate_db_version VALUES(3,20230603230449,1,'2023-06-04 21:07:25.743');
INSERT INTO micrate_db_version VALUES(4,20230621194335,1,'2023-06-29 21:14:49.492');
INSERT INTO micrate_db_version VALUES(5,20230629224154,1,'2023-06-29 21:14:49.493');
INSERT INTO micrate_db_version VALUES(6,20230712000051,1,'2023-07-11 22:02:41.232');
INSERT INTO micrate_db_version VALUES(7,20230719001346,1,'2023-07-18 22:19:46.841');
INSERT INTO micrate_db_version VALUES(8,20230719212605,1,'2023-07-19 19:30:52.804');
CREATE TABLE users (
  mail VARCHAR(255) NOT NULL PRIMARY KEY
, nordigen_requisition_id varchar(255), ynab_refresh_token varchar(255), mapping TEXT NOT NULL DEFAULT '', last_sync_time INT NOT NULL DEFAULT 0, id_seed TEXT NOT NULL DEFAULT "");
INSERT INTO users VALUES('existing-user@gmail.com',NULL,NULL,'',0,'');
CREATE TABLE log (
    timestamp INT NOT NULL,
    mail VARCHAR(255) NOT NULL,
    severity VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    data TEXT NOT NULL
);
DELETE FROM sqlite_sequence;
INSERT INTO sqlite_sequence VALUES('micrate_db_version',8);
COMMIT;
