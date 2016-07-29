drop table if exists timedropdownlist;

Create table timedropdownlist (
PRIMARY KEY (UNIX_TIME),
UNIX_TIME int (10) not null,
READ_TIME varchar(16) NOT NULL)
ENGINE = InnoDB;

INSERT INTO timedropdownlist (UNIX_TIME, READ_TIME)
SELECT UNIX_START, from_unixtime(UNIX_START+28800, '%Y-%m-%d %H:%i') AS TS FROM MOVEMENT s WHERE hour(from_unixtime(UNIX_START, '%Y-%m-%d %H:%i')) % 1 = 0 GROUP BY TS ORDER BY TS;
INSERT INTO timedropdownlist (UNIX_TIME, READ_TIME)
VALUES(unix_timestamp('2015-08-21 00:00'),'2015-08-21 07:00');
delete from timedropdownlist where unix_time = 0000000000;

select * from timedropdownlist