require_relative 'spec_helper'

describe "Neighbours" do

	before do
		Neighbour.destroy
	end

	it "should return hello world in json and utf8" do
		get '/'
		assert last_response.ok?, "response code not ok"
		last_response.content_type.must_equal 'application/json;charset=utf-8'
		intended = "Hello World".to_json
		intended.must_equal last_response.body
	end

	#it "should add 5 random neighbours" do
	#	get '/add_5_random_neighbours'
	#	assert last_response.ok?, "response code not ok: #{last_response.to_json}"
	#	last_response.content_type.must_equal 'application/json;charset=utf-8'
    # 
	#end

	it "should return the favicon.ico" do
		get '/favicon.ico'
		assert last_response.ok?, "response code not ok"
	end

	it "should return no neighbours" do
		get '/neighbours'
		assert last_response.ok?, "response code not ok"
		last_response.content_type.must_equal 'application/json;charset=utf-8'
		last_response.body.must_equal [].to_json
	end

	it "should add 3 random neighbours" do
		longitude = 0
		latitude  = 0
		radius    = 1 # km
		num       = 3

		get '/add_random_neighbours', 
			:num       => num,
			:radius    => radius,
			:latitude  => latitude,
			:longitude => longitude

		assert last_response.ok?, "response code not ok"
		last_response.content_type.must_equal 'application/json;charset=utf-8'

		last_response.body.must_equal num.to_json

		get '/neighbours'
		assert last_response.ok?, "response code not ok"
		last_response.content_type.must_equal 'application/json;charset=utf-8'
		neighbours = JSON.parse( last_response.body )
		neighbours.count.must_equal num

		#Geocoder::Calculations.distance_between([47.858205,2.294359], [40.748433,-73.985655]).must_equal 3619.77359999382

		neighbours.each do |n|
			distance_in_miles = Geocoder::Calculations.distance_between(
				[n['latitude'], n['longitude']],
				[latitude,   longitude  ]
				)
			assert distance_in_miles <= radius, "distance_in_miles (#{distance_in_miles.to_s}) > radius(#{radius}); 
			n.latitude=#{n['latitude']}, n.longitude=#{n['longitude']}, latitude=#{latitude}, longitude=#{longitude};
			n=#{pp n}"
		end
	end

end