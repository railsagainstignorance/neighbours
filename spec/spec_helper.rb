ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'
require 'pp'
require_relative '../neighbours'

include Rack::Test::Methods

def app
	Sinatra::Application
end