require_relative 'spec_helper'

def assert_neighbours_within_radius( neighbours, radius, latitude, longitude)
	assert neighbours.count > 0, "expected neighbours.count to be > 0"
	from_coords = [latitude, longitude]
	neighbours.each do |n|
		nhbr_coords = [n['latitude'], n['longitude']]
		distance_in_miles = Geocoder::Calculations.distance_between( from_coords, nhbr_coords )
		assert( distance_in_miles <= radius, "distance_in_miles (#{distance_in_miles.to_s}) > radius(#{radius}); \nfrom_coords=#{from_coords.to_s}, \nnhbr_coords=#{nhbr_coords.to_s}; \nn=#{n.to_s}")
	end
	return true
end

def assert_last_response_ok_json_utf8( last_response )
	assert last_response.ok?, "response code not ok: last_response.status=#{last_response.status}"
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

def assert_response_fail( last_response )
	assert_last_response_ok_json_utf8(last_response)
	parsed_body = JSON.parse( last_response.body )
	parsed_body.must_be_kind_of(Hash)
	parsed_body.must_include('status')
	'fail'.must_equal parsed_body['status'], "expected status=fail, got #{parsed_body['status']}: body=#{parsed_body}"
	parsed_body.must_include('data')
	parsed_body['data'].must_be_kind_of(Hash)
	parsed_body['data'].must_include('message')
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
		assert_neighbours_within_radius( neighbours, radius, latitude, longitude)
		neighbours.count.must_equal num
		nhbr_fields = ['name', 'latitude', 'longitude', 'updated_at', 'distance']
		neighbours.each do |n|
			n.size.must_equal nhbr_fields.count
			nhbr_fields.each do |f|
				n.must_include f			
			end
		end

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
		assert_neighbours_within_radius( neighbours, nearby_radius, nearby_coords.first, nearby_coords.last)
		neighbours.count.must_equal 1

		# recheck the second instance at its original location
		get '/neighbours', 
			:radius    => nearby_radius,
			:latitude  => coords.last.first,
			:longitude => coords.last.last,
			:atoken    => atokens.last
		neighbours = assert_success_and_get_parsed_data_field( last_response, 'neighbours', Array )
		assert_neighbours_within_radius( neighbours, nearby_radius, coords.last.first, coords.last.last)
		neighbours.count.must_equal 1
	end

	it "should re-register an existing user" do
		latitude  = 0.0
		longitude = 0.0
		name      = 'Test re-register'
		email     = 'testreregister@madeupdomain.com'
		password  = 'testreregister'

		put '/register',
			:name      => name,
			:email     => email,
			:password  => password,
			:latitude  => latitude,
			:longitude => longitude

		atoken = assert_success_and_get_parsed_data_field( last_response, 'atoken', String )

		# verify can make a valid /neighbours request
		get '/neighbours', 
			:radius    => 0.0,
			:latitude  => latitude,
			:longitude => longitude,
			:atoken    => atoken
		neighbours = assert_success_and_get_parsed_data_field( last_response, 'neighbours', Array )
		neighbours.count.must_equal 0

		new_password = password + '2'
		put '/re-register',
			:name      => name,
			:email     => email,
			:password  => new_password,
			:latitude  => latitude,
			:longitude => longitude
		new_atoken = assert_success_and_get_parsed_data_field( last_response, 'atoken', String )

		# verify can make a valid /neighbours request with new atoken
		get '/neighbours', 
			:radius    => 0.0,
			:latitude  => latitude,
			:longitude => longitude,
			:atoken    => new_atoken
		neighbours = assert_success_and_get_parsed_data_field( last_response, 'neighbours', Array )
		neighbours.count.must_equal 0
		# verify cannot make a valid /neighbours request with old atoken
		get '/neighbours', 
			:radius    => 0.0,
			:latitude  => latitude,
			:longitude => longitude,
			:atoken    => atoken
		assert_response_fail( last_response )
	end
end