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
		convertNeighboursToPolarRelativeToMe
		;

	getUsersGeolocation = function(foundPosition, foundError){
		var code = null;
		if (typeof navigator == "undefined") {
			code = 'NAVIGATOR_NOT_DEFINED';
		} else if (! 'geolocation' in navigator ){
			code = 'NAVIGATOR_GEOLOCATION_NOT_SUPPORTED';
		} else if (! 'getCurrentPosition' in navigator.geolocation ){
			code = 'NAVIGATOR_GEOLOCATION_GETCURRENTPOSITION_NOT_SUPPORTED';
		} else {
			navigator.geolocation.getCurrentPosition(foundPosition, foundError, {timeout:3000});	
		}

		if (code != null) {
			foundError( {code: code} );
		}
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
			case error.NAVIGATOR_NOT_DEFINED:
			text = 'Browser says: navigator is not defined.'
			break;
			case error.NAVIGATOR_GEOLOCATION_NOT_SUPPORTED:
			text = 'Browser says: navigator.geolocation is not supported.'
			break;
			case error.NAVIGATOR_GEOLOCATION_GETCURRENTPOSITION_NOT_SUPPORTED:
			text = 'Browser says: navigator.geolocation.getCurrentPosition is not supported.'
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

	convertNeighboursToPolarRelativeToMe = function(my_coords, neighbours_array){
		return neighbours_array
	}

	//-------------------------------------------

	return {
		                                  hw: hw,
		                 getUsersGeolocation: getUsersGeolocation,
		       convertGeolocationErrorToText: convertGeolocationErrorToText,
		convertNeighboursToPolarRelativeToMe: convertNeighboursToPolarRelativeToMe
	};

}());

exports.RADAR = RADAR;
