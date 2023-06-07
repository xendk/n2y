-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
ALTER TABLE users ADD COLUMN ynab_refresh_token varchar(255);

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back
ALTER TABLE usersDROP COLUMN ynab_refresh_token;
