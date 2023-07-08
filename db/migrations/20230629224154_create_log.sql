-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
CREATE TABLE log (
    timestamp INT NOT NULL,
    mail VARCHAR(255) NOT NULL,
    severity VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    data TEXT NOT NULL
);

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back
DROP TABLE log;
