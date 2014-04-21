require 'sinatra'
require 'json'
require 'data_mapper'

DataMapper.setup( :default, "sqlite3://#{Dir.pwd}/neighbours.db" )

class Neighbour
	include DataMapper::Resource

	property :id, 		  Serial
	property :name, 	  String, :required => true
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