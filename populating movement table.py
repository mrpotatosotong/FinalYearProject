import mysql.connector

cnx = mysql.connector.connect(user='root', host = '127.0.0.1', password = 'VFR4cde3'
                             , database = 'test')
cur = cnx.cursor()

sqlStep1 = "SELECT S_ID, LOCATION, UNIX_TIMESTAMP('2015-08-20 %(start)d:00:00') FROM starhub WHERE UNIX_TIME BETWEEN UNIX_TIMESTAMP('2015-08-20 %(start)d:00:00') AND UNIX_TIMESTAMP('2015-08-20 %(start)d:30:00') GROUP BY S_ID;"
#sqlStep2 = "SELECT LOCATION, UNIX_TIME FROM starhub WHERE UNIX_TIME = UNIX_TIMESTAMP('2015-08-20 %(endtime)d:00:00') AND S_ID = '%(s_id)s' AND LOCATION != '%(location)s';"
sqlStep2 = "SELECT LOCATION, UNIX_TIMESTAMP('2015-08-20 %(endtime)d:00:00') FROM starhub WHERE UNIX_TIME BETWEEN UNIX_TIMESTAMP('2015-08-20 %(endtime)d:00:00') AND UNIX_TIMESTAMP('2015-08-20 %(endtime)d:30:00') AND S_ID = '%(s_id)s' AND LOCATION != '%(location)s';"
sqlInsertMovement = "INSERT INTO `test`.`movement`(`UNIX_START`,`UNIX_END`,`START_LOCATION`,`DEST_LOCATION`,`COUNT`) VALUES(%(unixstart)d,%(unixend)d,'%(start)s','%(dest)s',1);"
sqlUpdateCount = "UPDATE `test`.`movement` SET `COUNT` = `COUNT` + 1 WHERE `UNIX_START` = %(unixstart)d AND `UNIX_END` = %(unixend)d AND `START_LOCATION` = '%(start)s' AND `DEST_LOCATION` = '%(dest)s';"
sqlSelectMovement = "SELECT COUNT(*) AS c FROM movement WHERE UNIX_START = %(unixstart)d AND UNIX_END = %(unixend)d AND `START_LOCATION` = '%(start)s' AND `DEST_LOCATION` = '%(dest)s';"

runninghourInt = 0

def prep(sql, parameter):
    p = sql%parameter
    return p

def escape(string):
    return string.replace("'","\\'")

totalMovement = 0

while(runninghourInt <= 22):
        
    runninghourEndInt=runninghourInt + 1

    print("Started Step 1: Selecting " + str(runninghourInt))
    dataSql1={
        'start':runninghourInt
        }
    cur.execute(sqlStep1%dataSql1)
    step1data = cur.fetchall()
    print("data obtained, adding movements")
    numSID = 0
    numMovement = 0
    numUpdate = 0
    for(S_ID, LOCATION, UNIX_TIME) in step1data:
        numSID = numSID + 1
        unixstart = int(UNIX_TIME)
        startlocation = LOCATION
        for i in range(runninghourEndInt, 24):
            dataSql2 = {
                'endtime': i,
                's_id': S_ID,
                'location': escape(startlocation),
            }
            cur.execute(prep(sqlStep2,dataSql2))
            step2data = cur.fetchall()
            step2location = ""
            unixend = 0
            thereOrNot = False
            for(LOCATION, UNIX_TIME) in step2data:
                thereOrNot = True
                unixend = int(UNIX_TIME)
                step2location = LOCATION
                break
            if(thereOrNot == False):           
                continue
            dataSelectMovement = {
                'unixstart': unixstart,
                'unixend': unixend,
                'start': escape(startlocation),
                'dest': escape(step2location)
                }
            cur.execute(prep(sqlSelectMovement,dataSelectMovement))
            step3data = cur.fetchall()
            alrHaveMovement = False
            for(c) in step3data:
                if(c[0] > 0):
                    alrHaveMovement = True
                break
            if(alrHaveMovement):
                cur.execute(prep(sqlUpdateCount, dataSelectMovement))
                cnx.commit()
                numUpdate = numUpdate + 1
            else:
                cur.execute(prep(sqlInsertMovement, dataSelectMovement))
                cnx.commit()
                numMovement = numMovement + 1
    runninghourInt = runninghourInt + 1

cur.close()
cnx.close()
print("COMPLETE. Total movement is " + str(totalMovement))
