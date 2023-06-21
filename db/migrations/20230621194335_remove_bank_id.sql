-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
ALTER TABLE users DROP COLUMN nordigen_bank_id;

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back
ALTER TABLE users ADD COLUMN nordigen_bank_id varchar(255);
