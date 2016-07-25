import mysql.connector
import sys
from collections import defaultdict
from geopy.geocoders import Nominatim

cnx = mysql.connector.connect(host="localhost",
                      user="root", password="VFR4cde3",
                              database='test')
cur = cnx.cursor()

sqlStatement = "INSERT INTO STARHUB(S_ID, UNIX_TIME, SESSION, LOCATION) VALUES('%s',%s,%s,'%s');"
precheck = "SELECT * FROM STARHUB WHERE S_ID = %s AND UNIX_TIME = %s;"
query = ("SELECT COORD FROM coordinates WHERE LOCATION = '%s';")
insert = "INSERT INTO coordinates(LOCATION, COORD) VALUES('%s','%s');"

countRead = 0
countAdded = 0
locationWeHave = []

def geopy(location):
    geolocator = Nominatim()
    location = geolocator.geocode('%s Singapore'%(location),timeout=30)
    if(location is None):
        return('%s,%s'%(0,0))
    else:
        lat = location.latitude
        lon = location.longitude
        return('%s,%s'%(lat,lon))

def getLatLon(loca):
    if(False):
        #loca in locationWeHave):
        return
    else:
        prep = query%loca
        cur.execute(prep)
        rowCount = 0;
        for COORD in cur:
            rowCount = rowCount + 1
            locationWeHave.append(loca)
        if(rowCount == 1):
            return
        else:
            loc = geopy(loca)
            prep = insert%(loca,loc)
            cur.execute(prep)
            cnx.commit()

alreadyhave = True

with open('DATA_FOR_RPMASTER.txt') as f:
    for line in f:
        countRead = countRead + 1
        if(countRead % 1000 == 0):
            print("read: " + str(countRead))           
        temp = line.rstrip('\n').split(',')
        if(alreadyhave):
            cur.execute(precheck,[temp[0],temp[1]])
            rowcount = 0;
            for r in cur:
                rowcount = rowcount + 1;
            if(rowcount > 0):
                countAdded = countAdded + 1
                if(countAdded % 1000 == 0):
                    print('Line added %s'%(countAdded))   
                continue
            else:
                alreadyhave = False
        temp[3] = temp[3].replace("'","\\'")
        getLatLon(temp[3])
        try:
            cur.execute(sqlStatement%tuple(temp))
            cnx.commit()
            countAdded = countAdded + 1
            if(countAdded % 1000 == 0):
                print('Line added %s'%(countAdded))
        except IOError:
            cnx.rollback()
            print(sys.exc_info()[0])
cur.close()
cnx.close()
print("total lines read: " + str(countRead) + " Total lines added: " + str(countAdded))
