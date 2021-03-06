(function (){

// obtain the geolocation from the browser
// http://www.w3schools.com/html/html5_geolocation.asp

var x = document.getElementById("geolocation-status");

function getLocation(){
	if (typeof navigator == "undefined") {
		x.innerHTML = "Browser says: navigator is not defined.";
	} else if (! 'geolocation' in navigator ){
		x.innerHTML = "Browser says: navigator.geolocation is not supported.";
	} else if (! 'getCurrentPosition' in navigator.geolocation ){
		x.innerHTML = "Browser says: navigator.geolocation.getCurrentPosition is not supported.";
	} else {
		navigator.geolocation.getCurrentPosition(showPosition, showError, {timeout:3000});	
	}
}

function showPosition(position){
	var coords = position.coords
	x.innerHTML = '<P>Browser says: <UL>' + 
'<LI>[lat, long]=[ ' + coords.latitude + ', ' + coords.longitude + ' ]' + 
'<LI>accuracy=' + coords.accuracy + 
'<LI>altitude=' + coords.altitude + 
'<LI>altitudeAccuracy=' + coords.altitudeAccuracy + 
'<LI>heading=' + coords.heading + 
'<LI>speed=' + coords.speed + 
'</UL></P>' + 
'<div id="neighbour-form-browser-geolocation">' + 
'  <form action="/web/neighbours" method="get">' + 
'	<input type="hidden" name="latitude"  value="' + position.coords.latitude + '">' +
'	<input type="hidden" name="longitude" value="' + position.coords.longitude + '">' +
'	<input type="hidden" name="radius" value="100">' +
'   <input type="submit" value="Find My Geolocated Neighbours!">' +
'  </form>' +
'</div>'; 
}

function showError(error){
	switch(error.code){
		case error.PERMISSION_DENIED:
		x.innerHTML = "Browser says: User denied the request for Geolocation."
		break;
		case error.POSITION_UNAVAILABLE:
		x.innerHTML = "Browser says: Location information is unavailable."
		break;
		case error.TIMEOUT:
		x.innerHTML = "Browser says: The request to get user location timed out."
		break;
		case error.UNKNOWN_ERROR:
		x.innerHTML = "Browser says: An unknown error occurred."
		break;
	}
}

getLocation();

})();