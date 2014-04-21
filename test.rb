ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'
require_relative 'neighbours.rb'

include Rack::Test::Methods

def app
	Sinatra::Application
end

#----------------------

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
end