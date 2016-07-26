import mysql.connector
import sys
from collections import defaultdict
from geopy.geocoders import Nominatim

cnx = mysql.connector.connect(host="localhost",
                      user="root", password="VFR4cde3",
                              database='test')
cur = cnx.cursor()

insert = "INSERT INTO coordinates(LOCATION, COORD) VALUES('%s','%s');"

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
        loc = geopy(loca)
        prep = insert%(loca,loc)
        cur.execute(prep)
        cnx.commit()
            
with open('locations.txt') as f:
    for line in f:
        temp = line.rstrip('\n')
        temp = temp.rstrip('\r')
        temp = temp.rstrip('\'')
        temp = temp.lstrip('\'')
        
        getLatLon(temp)