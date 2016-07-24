DROP TABLE if exists STARHUB;

CREATE TABLE IF NOT EXISTS `STARHUB` (
    PRIMARY KEY (`S_ID`,`UNIX_TIME`),
    `S_ID` VARCHAR(32) NOT NULL,
    `UNIX_TIME` INT(10) NOT NULL,
    `SESSION` INT(1) NOT NULL,
    `LOCATION` VARCHAR(50) NOT NULL
)  ENGINE=InnoDB;

SELECT * FROM STARHUB LIMIT 1000000;