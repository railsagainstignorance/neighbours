(function (){

// obtain the geolocation from the browser
// http://www.w3schools.com/html/html5_geolocation.asp

var x = document.getElementById("geolocation-status");
function getLocation(){
	if (navigator.geolocation){
		navigator.geolocation.getCurrentPosition(showPosition, showError);
	}
	else{
		x.innerHTML = "Browser says: Geolocation is not supported.";
	}
}

function showPosition(position){
	x.innerHTML = '<P>Browser says: [lat, long]=[ ' + position.coords.latitude + ', ' + position.coords.longitude + ' ]</P>' + 
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