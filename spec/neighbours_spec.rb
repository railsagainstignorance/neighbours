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

def assert_success_and_get_parsed_data( last_response )
	assert_last_response_ok_json_utf8(last_response)
	parsed_body = JSON.parse( last_response.body )
	parsed_body.must_be_kind_of(Hash)
	parsed_body.must_include('status')
	'success'.must_equal parsed_body['status'], "expected status=success, got #{parsed_body['status']}: body=#{parsed_body}"
	parsed_body.must_include('data')
	parsed_body['data'].must_be_kind_of(Hash)
	return parsed_body['data']
end

def assert_success_and_get_parsed_data_field( last_response, field, type )
	parsed_data = assert_success_and_get_parsed_data( last_response )
	parsed_data.must_include( field )
	value = parsed_data[field]
	value.must_be_kind_of( type )
	return value
end

describe "Neighbours" do

	before do
		Neighbour.destroy
	end

	it "should return hello world in json and utf8 and jsend" do
		get '/'
		message = assert_success_and_get_parsed_data_field( last_response, 'message', String )
		message.must_equal 'Hello World'
	end

	it "should return the favicon.ico" do
		get '/favicon.ico'
		assert last_response.ok?, "response code not ok"
	end

	it "should add 3 random neighbours within radius 1" do
		longitude = 0.0
		latitude  = 0.0
		radius    = 1.0 # mile
		num       = 3

		# register a user in order to get an atoken
		put '/register',
			:name      => 'Chris',
			:email     => 'cgathercole@gmail.com',
			:password  => 'aBc',
			:latitude  => latitude,
			:longitude => longitude

		atoken = assert_success_and_get_parsed_data_field( last_response, 'atoken', String )

		# create the neighbours
		get '/add_random_neighbours', 
			:num       => num,
			:radius    => radius,
			:latitude  => latitude,
			:longitude => longitude,
			:atoken    => atoken
		
		num_added = assert_success_and_get_parsed_data_field( last_response, 'num_added', Integer )
		num_added.must_equal 3

		# retrieve all neighbours
		get '/neighbours',
			:atoken    => atoken
		neighbours = assert_success_and_get_parsed_data_field( last_response, 'neighbours', Array )
		assert_neighbours_within_radius( neighbours, radius, latitude, longitude)

		# retrieve local neighbours for a point which should have them
		get '/neighbours', 
			:radius    => radius,
			:latitude  => latitude,
			:longitude => longitude,
			:atoken    => atoken
		neighbours = assert_success_and_get_parsed_data_field( last_response, 'neighbours', Array )
		neighbours.count.must_equal num

		assert_neighbours_within_radius( neighbours, radius, latitude, longitude)

		# retrieve local neighbours for a point which should not have them
		far_away = 100
		get '/neighbours', 
			:radius    => radius,
			:latitude  => latitude + far_away,
			:longitude => longitude + far_away,
			:atoken    => atoken
		neighbours = assert_success_and_get_parsed_data_field( last_response, 'neighbours', Array )
		neighbours.count.must_equal 0
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

		atoken = assert_success_and_get_parsed_data_field( last_response, 'atoken', String )

		get '/neighbours', 
			:radius    => 0.0,
			:latitude  => latitude,
			:longitude => longitude,
			:atoken    => atoken

		neighbours = assert_success_and_get_parsed_data_field( last_response, 'neighbours', Array )
		neighbours.count.must_equal 0
	end

	it "should change own location when making neighbours request" do
		separation    = 100
		random_radius = 10
		initial_lat, initial_long = [10.0, 12.0]

		coords = []
		coords << Geocoder::Calculations.random_point_near([initial_lat, initial_long], random_radius )
		coords << Geocoder::Calculations.random_point_near([initial_lat + separation, initial_long], random_radius )

		atokens = []

		# register two instances
		(0..1).each do |i|
			put '/register',
				:name      => "Test_#{i}",
				:email     => "test_#{i}\@madeupdomain.com",
				:password  => "aBc#{i}",
				:latitude  => coords[i].first,
				:longitude => coords[i].last

			atokens << assert_success_and_get_parsed_data_field( last_response, 'atoken', String )
		end

		nearby_radius = 1

		# establish the instances are alone (at their original locations)
		(0..1).each do |i|
			get '/neighbours', 
				:radius    => nearby_radius,
				:latitude  => coords[i].first,
				:longitude => coords[i].last,
				:atoken    => atokens[i]
	
			neighbours = assert_success_and_get_parsed_data_field( last_response, 'neighbours', Array )
			neighbours.count.must_equal 0
		end

		# move first instance to near the second instance
		nearby_coords = Geocoder::Calculations.random_point_near( coords.last, nearby_radius )

		get '/neighbours', 
			:radius    => nearby_radius,
			:latitude  => nearby_coords.first,
			:longitude => nearby_coords.last,
			:atoken    => atokens.first
		neighbours = assert_success_and_get_parsed_data_field( last_response, 'neighbours', Array )
		neighbours.count.must_equal 1

		# recheck the second instance at its original location
		get '/neighbours', 
			:radius    => nearby_radius,
			:latitude  => coords.last.first,
			:longitude => coords.last.last,
			:atoken    => atokens.last
		neighbours = assert_success_and_get_parsed_data_field( last_response, 'neighbours', Array )
		neighbours.count.must_equal 1
	end

end