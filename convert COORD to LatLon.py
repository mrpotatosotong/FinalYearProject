import mysql.connector

sqlSel = "SELECT LOCATION,substring(COORD, 1, instr(COORD,',')-1) as aLONG, substring(COORD, instr(COORD,',')+1) as aLA FROM COORDINATES;"
sqlUpd = "UPDATE COORDINATES SET LONGITUDE = %(LONG)s, LATITUDE = %(LAT)s WHERE LOCATION = '%(LOC)s';"
cnx = mysql.connector.connect(user='root', host = '127.0.0.1', password = 'VFR4cde3'
                             , database = 'test')
cur = cnx.cursor()

def prep(sql, parameter):
    p = sql%parameter
    return p

def escape(string):
    return string.replace("'","\\'")

cur.execute(sqlSel)
data = cur.fetchall()
for(LOCATION,aLONG,aLA) in data:
    print(LOCATION + str(aLONG) + str(aLA))
    prepData = {
        'LONG': '%.7f'%(float(aLONG)),
        'LAT': '%.7f'%(float(aLA)),
        'LOC':escape(LOCATION),
        }
    cur.execute(prep(sqlUpd,prepData))
    cnx.commit()