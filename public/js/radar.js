var RADAR = (function () {
	
	var hw = function(){
		return "hello world";
	};

// - create JS-driven display
// 	  + locate div element // not in this file
//    + expose current lat/long etc
//    + request neighbours via API
//    + calc dist,bearing to each (from current lat/long)
//    + scale radius=log(dist), size=bigger when closer
//    + plot on canvas (in location specified by arg)
//    + auto-update if moves

	//var radarDisplayCanvasElement = document.getElementById("radar-display");
	//var radarDisplayErrorElement  = document.getElementById("radar-display-error");
	
	var getUsersGeolocation,
		convertGeolocationErrorToText,
		convertNeighboursToPolarRelativeToMe,
		distanceKmAndBearingGreatCircle,
		merge2ndInto1st, 
		generateCanvas,
		pullItAllTogether
		;

	getUsersGeolocation = function(foundPosition, foundError){
		var code = null;
		var response;

		if (typeof navigator == "undefined") {
			code = 'NAVIGATOR_NOT_DEFINED';
		} else if (! 'geolocation' in navigator ){
			code = 'NAVIGATOR_GEOLOCATION_NOT_SUPPORTED';
		} else if (! 'getCurrentPosition' in navigator.geolocation ){
			code = 'NAVIGATOR_GEOLOCATION_GETCURRENTPOSITION_NOT_SUPPORTED';
		} else {
			navigator.geolocation.getCurrentPosition(foundPosition, foundError, {timeout:3000});	
		}

		if (code == null) {
			code = 'OK';
		} 

		return { code: code };
	}

	convertGeolocationErrorToText = function(error){
		var text = null;
		switch(error.code){
			case error.PERMISSION_DENIED:
			text = "Browser says: User denied the request for Geolocation."
			break;
			case error.POSITION_UNAVAILABLE:
			text = "Browser says: Location information is unavailable."
			break;
			case error.TIMEOUT:
			text = "Browser says: The request to get user location timed out."
			break;
			case error.UNKNOWN_ERROR:
			text = "Browser says: An unknown error occurred."
			break;
			case 'NAVIGATOR_NOT_DEFINED':
			text = 'Browser says: navigator is not defined.'
			break;
			case 'NAVIGATOR_GEOLOCATION_NOT_SUPPORTED':
			text = 'Browser says: navigator.geolocation is not supported.'
			break;
			case 'NAVIGATOR_GEOLOCATION_GETCURRENTPOSITION_NOT_SUPPORTED':
			text = 'Browser says: navigator.geolocation.getCurrentPosition is not supported.'
			break; 
			case 'OK':
			text = 'Actually, it was fine'
			break; 
			default:
			text = "unknown error: " + error.code
			break;
		}

		return text;
	}

// /neighbours response
// 
// {
// status: "success",
// data: {
// 	neighbours: [
// 		{
// 		name: "chr8",
// 		latitude: 51.9165135,
// 		longitude: -0.6790022,
// 		updated_at: "2014-05-09T17:46:22+00:00",
// 		distance: 0.8119075187103253
// 		}
// 	],
// 	me: {
// 		name: "chr9",
// 		latitude: 51.919684,
// 		longitude: -0.6606569999999999,
// 		updated_at: "2014-05-12T20:54:41+00:00"
// 		}
// 	}
// }
// neighbours_array = response.neighbours
// my_coords = {latitude: me.latitude, longitude: me.longitude}


// caclulations lifted from https://software.intel.com/en-us/blogs/2012/11/30/calculating-a-bearing-between-points-in-location-aware-apps

	distanceKmAndBearingGreatCircle = function(lat1, long1, lat2, long2) {
		var degToRad= Math.PI / 180;
	    var phi1= lat1 * degToRad;
	    var phi2= lat2 * degToRad;
	    var lam1= long1 * degToRad;
	    var lam2= long2 * degToRad;

	    var distance = 6371.01 * Math.acos( Math.sin(phi1) * Math.sin(phi2) + Math.cos(phi1) * Math.cos(phi2) * Math.cos(lam2 - lam1) );
	    var bearing_degrees = Math.atan2(
	    	Math.sin(lam2-lam1) * Math.cos(phi2),
	        Math.cos(phi1)*Math.sin(phi2) - Math.sin(phi1)*Math.cos(phi2)*Math.cos(lam2-lam1)
	        ) * 180/Math.PI;
	    var bearing_initial = (bearing_degrees + 360) % 360;

	    return {
	    	  radiusInKm: distance,
	    	bearingInDeg: bearing_initial
	    }
	}

	merge2ndInto1st = function(a, b) {
		for (var prop in b) {
			if (prop in a) { continue; }
			a[prop] = b[prop];
		}

		return a;
	}
	
	convertNeighboursToPolarRelativeToMe = function(my_coords, neighbours_array){
		var d_and_b;
		var neighbours_with_polar = neighbours_array.map( function(n) {
			// construct hash of elements from n and the added polar coords relative to me
			d_and_b = distanceKmAndBearingGreatCircle(
				my_coords.latitude, 
				my_coords.longitude,
				n.latitude,
				n.longitude
				);

			return merge2ndInto1st(d_and_b, n)
		} );

		return neighbours_with_polar;
	}

	//-------------------------------------------
	// mostly lifted from satellite.js

	generateCanvas = function(canvas_selector, neighbours_with_polar){
		var   
			c, 
			canvas,
			centre;

		c = document.querySelector("#canvas");

		c.width  = window.innerWidth * 0.95; //500; //window.innerWidth;
		c.height = window.innerHeight* 0.95; //500; //window.innerHeight;
	
		canvas = oCanvas.create({ canvas: "#canvas", background: "#222" });

		// Centre object. Me!
		var centre = canvas.display.ellipse({
			     x: canvas.width / 2, 
			     y: canvas.height / 2,
			radius: canvas.width / 20,
			  fill: "#fff"
		}).add();

		// loop over each neighbour, calculate hyperbolic radius
	}

	//-------------------------------------------

	pullItAllTogether = function(){
		var foundError = function(error){
			var code_as_text = convertGeolocationErrorToText( error );
			alert("pullItAllTogether.foundError=" + code_as_text );
		}

		var foundPosition = function(position){
			var coords = position.coords;
			alert('pullItAllTogether.foundError: ' + 
				'[lat, long]=[ ' + coords.latitude + ', ' + coords.longitude + ' ]'
				);
		}

		var getUsersGeolocation_response = getUsersGeolocation(foundPosition, foundError);
		if (getUsersGeolocation_response.code != 'OK') {
			alert("getUsersGeolocation_response=" + getUsersGeolocation_response);
		}
	}

	//-------------------------------------------

	return {
		                                  hw: hw,
		                 getUsersGeolocation: getUsersGeolocation,
		       convertGeolocationErrorToText: convertGeolocationErrorToText,
		convertNeighboursToPolarRelativeToMe: convertNeighboursToPolarRelativeToMe, 
		     distanceKmAndBearingGreatCircle: distanceKmAndBearingGreatCircle, 
		     				 merge2ndInto1st: merge2ndInto1st, 
		     			   pullItAllTogether: pullItAllTogether
	};

}());

if (typeof exports != 'undefined') {
	exports.RADAR = RADAR;
} else{
	RADAR.pullItAllTogether();
};
