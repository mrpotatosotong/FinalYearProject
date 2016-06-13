#import geocoder
#g = geocoder.google('Singapore')
#g.latlng
from geopy.geocoders import Nominatim

geolocator = Nominatim()
location = geolocator.geocode("Victoria SG")
print(location.latitude, location.longitude)