-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
CREATE TABLE users (
  mail VARCHAR(255) NOT NULL PRIMARY KEY
);

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back
DROP TABLE users;
