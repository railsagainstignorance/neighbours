require_relative 'spec_helper'

def assert_neighbours_within_radius( neighbours, radius, latitude, longitude)
		neighbours.each do |n|
		distance_in_miles = Geocoder::Calculations.distance_between( [n['latitude'], n['longitude']], [latitude, longitude] )
		assert( distance_in_miles <= radius, "distance_in_miles (#{distance_in_miles.to_s}) > radius(#{radius}); n.latitude=#{n['latitude']}, n.longitude=#{n['longitude']}, latitude=#{latitude}, longitude=#{longitude}; n=#{n.to_s}")
	end
	return true
end

def assert_last_response_ok_json_utf8( last_response )
	assert last_response.ok?, "response code not ok"
	last_response.content_type.must_equal 'application/json;charset=utf-8'
end

describe "Neighbours" do

	before do
		Neighbour.destroy
	end

	it "should return hello world in json and utf8" do
		get '/'
		assert_last_response_ok_json_utf8(last_response)
		intended = "Hello World".to_json
		intended.must_equal last_response.body
	end

	it "should return the favicon.ico" do
		get '/favicon.ico'
		assert last_response.ok?, "response code not ok"
	end

	it "should return no neighbours" do
		get '/neighbours'
		assert_last_response_ok_json_utf8(last_response)
		last_response.body.must_equal [].to_json
	end

	it "should add 3 random neighbours within radius 1" do
		longitude = 0.0
		latitude  = 0.0
		radius    = 1.0 # mile
		num       = 3

		# create the neighbours
		get '/add_random_neighbours', 
			:num       => num,
			:radius    => radius,
			:latitude  => latitude,
			:longitude => longitude

		assert_last_response_ok_json_utf8(last_response)

		last_response.body.must_equal num.to_json

		# retrieve all neighbours
		get '/neighbours'
		assert_last_response_ok_json_utf8(last_response)
		neighbours = JSON.parse( last_response.body )
		neighbours.count.must_equal num

		assert_neighbours_within_radius( neighbours, radius, latitude, longitude)

		# retrieve local neighbours for a point which should have them
		get '/neighbours', 
			:radius    => radius,
			:latitude  => latitude,
			:longitude => longitude
		assert_last_response_ok_json_utf8(last_response)
		neighbours = JSON.parse( last_response.body )
		neighbours.count.must_equal num

		assert_neighbours_within_radius( neighbours, radius, latitude, longitude)

		# retrieve local neighbours for a point which should not have them
		far_away = 100
		get '/neighbours', 
			:radius    => radius,
			:latitude  => latitude + far_away,
			:longitude => longitude + far_away

		assert_last_response_ok_json_utf8(last_response)
		neighbours = JSON.parse( last_response.body )
		0.must_equal neighbours.count, "should be no such neighbours, but found #{neighbours.count}"
	end

	it "should register a new user" do
		latitude  = 0.0
		longitude = 0.0

		put '/register',
			:name      => 'Chris',
			:email     => 'cgathercole@gmail.com',
			:password  => 'aBc',
			:latitude  => latitude,
			:longitude => longitude

		assert_last_response_ok_json_utf8(last_response)
		parsed_body = JSON.parse( last_response.body )
		parsed_body.must_be_kind_of(Hash)
		parsed_body.must_include('status')
		parsed_body['status'].must_equal 'success'
		parsed_body.must_include('data')
		parsed_body['data'].must_be_kind_of(Hash)
		parsed_body['data'].must_include('atoken')
		parsed_body['data']['atoken'].must_be_kind_of(String)

		get '/neighbours', 
			:radius    => 0.0,
			:latitude  => latitude,
			:longitude => longitude
		assert_last_response_ok_json_utf8(last_response)
		neighbours = JSON.parse( last_response.body )
		neighbours.count.must_equal 1
	end

end