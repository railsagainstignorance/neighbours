require_relative 'spec_helper'

describe "NeighboursViaWeb" do

	before do
		Neighbour.destroy
	end

	it "should display some documentation" do
		get '/doc'
		assert last_response.ok?, "response code not ok"
		page = Nokogiri::HTML( last_response.body )
	
		# very basic check to see if the page contains an entry for the /register route
		page.css('h2#put-register')[0].wont_be_nil
		'PUT /register'.must_equal page.css('h2#put-register')[0].text
	end
end