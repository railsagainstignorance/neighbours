require_relative 'spec_helper'

describe "Neighbours" do

	it "should return hello world in json and utf8" do
		get '/'
		assert last_response.ok?, "response code not ok"
		last_response.content_type.must_equal 'application/json;charset=utf-8'
		intended = "Hello World".to_json
		intended.must_equal last_response.body
	end

	it "should add 5 random neighbours" do
		get '/add_5_random_neighbours'
		assert last_response.ok?, "response code not ok: #{last_response.to_json}"
		last_response.content_type.must_equal 'application/json;charset=utf-8'

	end

	it "should return the favicon.ico" do
		get '/favicon.ico'
		assert last_response.ok?, "response code not ok"
	end

	it "should add 3 random neighbours within radius of 100m" do
		get '/add_random_neighbours', 
			:num => 3,
			:radius => 100, # metres
			:latitude => 0,
			:longitude => 0
		assert last_response.ok?, "response code not ok"
		last_response.content_type.must_equal 'application/json;charset=utf-8'

		last_response.body.must_equal 3.to_json
	end
end