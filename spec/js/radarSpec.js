var sut = require("../../public/js/radar"); // sut = system under test
 should = require("should");

describe("radar will say 'hello world' when you invoke the hw function", function(){
	it("fn hw will just say hello world", function(){
		sut.hw().should.equal("hello world");
	});
});
