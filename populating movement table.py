import mysql.connector

cnx = mysql.connector.connect(user='root', host = '127.0.0.1', password = 'VFR4cde3'
                             , database = 'test')
cur = cnx.cursor()

sqlStep1 = "SELECT S_ID, LOCATION, UNIX_TIME FROM starhub WHERE UNIX_TIME = UNIX_TIMESTAMP('2015-08-20 09:00:00');"
sqlStep2 = "SELECT LOCATION, UNIX_TIME FROM starhub WHERE UNIX_TIME = UNIX_TIMESTAMP('2015-08-20 10:00:00') AND S_ID = %(s_id)s AND LOCATION != %(location)s;"
sqlInsertMovement = "INSERT INTO `test`.`movement`(`UNIX_PAIR`,`START_LOCATION`,`DEST_LOCATION`,`COUNT`) VALUES(%(unixpair)s,%(start)s,%(dest)s,1);"
sqlUpdateCount = "UPDATE `test`.`movement` SET `COUNT` = `COUNT` + 1 WHERE `UNIX_PAIR` = %(unixpair)s AND `START_LOCATION` = %(start)s AND `DEST_LOCATION` = %(dest);;"
sqlSelectMovement = "SELECT COUNT(*) AS c FROM movement WHERE `UNIX_PAIR` = %(unixpair)s AND `START_LOCATION` = %(start)s AND `DEST_LOCATION` = %(dest)s;"


print("Started Step 1: Selecting 9am")
cur.execute(sqlStep1)
step1data = cur.fetchall()
print("9am data obtained")
for(S_ID, LOCATION, UNIX_TIME) in step1data:
    print(S_ID + LOCATION + str(UNIX_TIME))
    unixpair = str(UNIX_TIME)
    print(unixpair)
    dataSql2 = {
        's_id': S_ID,
        'location': LOCATION,
    }
    print("Selecting 10am")
    cur.execute(sqlStep2, dataSql2)
    step2data = cur.fetchall()
    step2location = ""
    thereOrNot = 0
    for(LOCATION, UNIX_TIME) in step2data:
        thereOrNot = 1
        unixpair = unixpair + "," + str(UNIX_TIME)
        step2location = LOCATION
        break
    if(thereOrNot == 0):
        continue
    dataSelectMovement = {
        'unixpair': unixpair,
        'start': dataSql2['location'],
        'dest': step2location,
        }
    cur.execute(sqlSelectMovement,dataSelectMovement)
    step3data = cur.fetchall()
    alrHaveMovement = False
    for(c) in step3data:
        if(int(c[0]) > 0):
            alrHaveMovement = True
        break
    if(alrHaveMovement):
        cur.execute(sqlUpdateCount, dataSelectMovement)
        cnx.commit()
    else:
        cur.execute(sqlInsertMovement, dataSelectMovement)
        cnx.commit()

cur.close()
cnx.close()
print("COMPLETE")