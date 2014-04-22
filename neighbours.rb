require 'sinatra'
require "sinatra/reloader" if development?

require 'json'
require 'data_mapper'
require 'dm-validations'

configure :test do
	DataMapper.setup( :default, "sqlite3::memory:" )
end

configure :development do
	DataMapper.setup( :default, "sqlite3://#{Dir.pwd}/neighbours.db" )
end

# configure :production do
#	 DataMapper.setup( :default, ENV['DATABASE_URL'] )
# end

class Neighbour
	include DataMapper::Resource

	property :id, 		  Serial
	property :name, 	  String, :required => true, :unique => true
	property :latitude,   Float, :required => true
	property :longitude,  Float, :required => true
	property :created_at, DateTime, :required => true
	property :updated_at, DateTime, :required => true
end

DataMapper.finalize

Neighbour.auto_upgrade!

#get '/' do
#	halt(404)
#end

get '/' do
	content_type :json, 'charset' => 'utf-8'
	"Hello World".to_json
end

get '/neighbours' do
	@nhbrs = Neighbour.all()
	@nhbrs.to_json
end

get '/add_5_random_neighbours' do
	content_type :json, 'charset' => 'utf-8'
	(1..5).each do |i|
		now = Time.now
		nhbr = Neighbour.first_or_create(
			:name       => "neighbour #{i}",
			:latitude   => rand(-90.000000000...90.000000000),
			:longitude  => rand(-180.000000000...180.000000000),
			:created_at => now,
			:updated_at => now
			)
	end
end

get '/neighbours_destroy' do
	Neighbour.destroy
end