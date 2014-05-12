var sut = require("../../public/js/radar"); // sut = system under test
 should = require("should");

describe("radar will say 'hello world' when you invoke the hw function", function(){
	it("fn RADAR.hw will just say hello world", function(){
		sut.RADAR.hw().should.equal("hello world");
	});
});

describe("radar will say process a list of neighbours.", function(){
	var neighbours_response = {
			status: "success",
			data: {
				neighbours: [
					{
					name: "chr7",
					latitude: 51.9165131,
					longitude: -0.6790021,
					updated_at: "2014-05-09T17:46:22+00:00",
					distance: 0.8119075187103253
					},
					{
					name: "chr8",
					latitude: 51.9165135,
					longitude: -0.6790022,
					updated_at: "2014-05-09T17:46:22+00:00",
					distance: 0.8119075187103253
					}
				],
				me: {
					name: "chr9",
					latitude: 51.919684,
					longitude: -0.6606569999999999,
					updated_at: "2014-05-12T20:54:41+00:00"
					}
				}
			};
	
	var my_coords = {
		 latitude: neighbours_response.data.me.latitude, 
		longitude: neighbours_response.data.me.longitude
	};

	var neighbours_array = neighbours_response.data.neighbours;

	it("fn RADAR.convertNeighboursToPolar will return an empty array if given an empty array", function(){
		sut.RADAR.convertNeighboursToPolarRelativeToMe(my_coords, []).should.be.an.instanceOf(Array);
	});

	it("fn RADAR.convertNeighboursToPolar will return the same size array as the one it is given", function(){
		sut.RADAR.convertNeighboursToPolarRelativeToMe(my_coords, neighbours_array).length.should.equal(neighbours_array.length);
	});
});
