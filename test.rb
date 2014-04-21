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
		last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
		intended = "Hello World".to_json
		intended.must_equal last_response.body
	end
end