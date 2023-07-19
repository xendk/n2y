-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
ALTER TABLE users ADD COLUMN last_sync_time INT NOT NULL DEFAULT 0;

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back
ALTER TABLE users DROP COLUMN last_sync_time;
