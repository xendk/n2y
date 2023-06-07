-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
ALTER TABLE users ADD COLUMN nordigen_requisition_id varchar(255);
ALTER TABLE users ADD COLUMN nordigen_bank_id varchar(255);

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back
ALTER TABLE users DROP COLUMN nordigen_requisition_id;
ALTER TABLE users DROP COLUMN nordigen_bank_id;
