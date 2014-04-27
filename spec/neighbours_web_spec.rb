require_relative 'spec_helper'
require_relative 'neighbours_spec'

describe "NeighboursViaWeb" do

	before do
		Neighbour.destroy
	end

	it "should server some documentation at /doc" do
		get '/doc'
		assert last_response.ok?, "response code not ok: last_response.status=#{last_response.status}"
		page = Nokogiri::HTML( last_response.body )
	
		# very basic check to see if the page contains an entry for the /register route
		page.css('h2#put-register')[0].wont_be_nil
		'PUT /register'.must_equal page.css('h2#put-register')[0].text
	end

	it "should serve a /web/register route" do
		get '/web/register'
		assert last_response.ok?, "response code not ok: last_response.status=#{last_response.status}"
	end

	it "should serve the /web/neighbours page if given suitable params" do
		# obtain a valid atoken via the API
		# pass it to the /web/neighbours page

		# register a user via the api in order to get an atoken
		put '/register',
			:name      => 'Test',
			:email     => 'Test@madeupdomain.com',
			:password  => 'aBc',
			:latitude  => 0.0,
			:longitude => 0.0

		atoken = assert_success_and_get_parsed_data_field( last_response, 'atoken', String )

		get '/web/neighbours',
			:latitude  => 0.0,
			:longitude => 0.0,
			:radius    => 1.0,
			:atoken    => atoken

		assert last_response.ok?, "response code not ok: last_response.status=#{last_response.status}"
		page = Nokogiri::HTML( last_response.body )
	
		# very basic check to see if the page contains an entry for the /register route
		page.css('div#neighbour_form')[0].wont_be_nil
	end
end