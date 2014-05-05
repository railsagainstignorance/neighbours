(function (){
// This code was lifted from http://ocanvas.org/

function output (label, input) {
	var          out = document.getElementById("output"),
		input_string = "", i, number;

	if (typeof input === "object") {
		input_string += "{\n";
		for (i in input) {
			number = !isNaN(parseFloat(input[i])) ? true : false;
			input_string += "<span class=\"tab\">\t</span>" + i + ": " + (number ? "" : "\"") + input[i] + (number ? "" : "\"") + "\n";
		}
		input_string += "}\n";
	}
	out.innerHTML += (out.innerHTML === "" ? "" : "\n") + label + input_string;
}

var   c = document.querySelector("#canvas"),
	ctx = c.getContext("2d");

c.width  = window.innerWidth * 0.95; //500; //window.innerWidth;
c.height = window.innerHeight* 0.95; //500; //window.innerHeight;
c.addEventListener("touchmove", function (e) { e.preventDefault(); }, false);
	
var canvas = oCanvas.create({ canvas: "#canvas", background: "#222" });

// Center planet
var center = canvas.display.ellipse({
	x: canvas.width / 2, y: canvas.height / 2,
	radius: canvas.width / 20,
	fill: "#fff"
}).add();

// Prototype objects that will be used to instantiate the others
var satelliteProto = canvas.display.ellipse({ fill: "#eee" });
var pathProto = canvas.display.ellipse({ stroke: "1px #999" });

// Set up data
var satellites = [], depth = 3;
var satelliteColors = ["#107B99", "#5F92C0", "#c7509f"];
var pathColors = ["#666", "#107B99", "#5F92C0"];

// Create seven satellites and paths. Definition is further down.
for (var i = 0, l = 7; i < l; i++) {
	createSatellite({
		parent: center, depth: 1,
		distance: (i + 1) * canvas.width / 6,
		radius: canvas.width / 100,
		speed: 1
	});
}

// Set up a tick function that will move all satellites each frame
canvas.setLoop(function () {
	for (var i = 0, l = satellites.length; i < l; i++) {
		satellites[i].rotation += satellites[i].speed;
	}
});

// Definition for a satellite and its corresponding path
function createSatellite (options) {

	// Create the path that the satellite will follow
	var path = pathProto.clone({
		radius: options.distance,
		x: options.x || 0, y: options.y || 0,
		strokeColor: pathColors[options.depth - 1]
	});
	options.parent.addChild(path);

	// Create a new satellite
	var satellite = satelliteProto.clone({
		origin: {
			x: 0,
			y: options.distance * (Math.round(Math.random()) ? 1 : -1)
		},
		speed: Math.random() * (2 * Math.random() - 0.5) + 0.5,
		radius: options.radius,
		x: options.x || 0, y: options.y || 0,
		fill: satelliteColors[options.depth - 1],
		rotation: Math.random() * 360
	});
	options.parent.addChild(satellite);
	satellites.push(satellite);

	// Create another satellite that will circle around this satellite
	if (options.depth < depth) {
		createSatellite({
			parent: satellite, depth: options.depth + 1,
			distance: options.radius * 7,
			radius: options.radius / 1.5,
			x: satellite.origin.x * -1, y: satellite.origin.y * -1,
			speed: 10
		});
	}
}

// Set up play/pause control for the demo
var text = canvas.display.text({
	x: canvas.width / 2, y: 220,
	origin: { x: "center", y: "center" },
	fill: "#fff", size: 25, weight: "bold", text: "Play"
}).add();
canvas.bind("click tap", function () {
	text.text = canvas.timeline.running ? "Play" : "Pause"; canvas.redraw();
	canvas.timeline[canvas.timeline.running ? "stop" : "start"]();
});

})();