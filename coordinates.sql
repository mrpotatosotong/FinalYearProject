CREATE TABLE IF NOT EXISTS `coordinates` (
    PRIMARY KEY (`LOCATION`),
    `LOCATION` VARCHAR(50) NOT NULL,
    `COORD` VARCHAR(21) NOT NULL,
`LONGITUDE` DECIMAL(10,7) NULL,
`LATITUDE` DECIMAL(10,7) NULL
)  ENGINE=InnoDB;

SELECT * FROM coordinates;
SELECT * FROM coordinates WHERE COORD = '0,0';