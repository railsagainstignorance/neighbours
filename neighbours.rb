require 'sinatra'
require "sinatra/reloader" if development?

require 'json'
require 'data_mapper'
require 'dm-validations'

require 'geocoder'
require 'pp'

configure :test do
	DataMapper.setup( :default, "sqlite3::memory:" )
end

configure :development do
	DataMapper.setup( :default, "sqlite3://#{Dir.pwd}/neighbours.db" )
end

# configure :production do
#	 DataMapper.setup( :default, ENV['DATABASE_URL'] )
# end

Geocoder.configure( ) # default=:mi, but might want to specify :units => :km 

class Neighbour
	include DataMapper::Resource

	property :id, 		         Serial
	property :name, 	         String,   :required => true, :unique => true
	property :latitude,          Float,    :required => true
	property :longitude,         Float,    :required => true
	property :created_at,        DateTime, :required => true
	property :updated_at,        DateTime, :required => true
	property :email,             String,                      :unique => true
	property :atoken,            String,                      :unique => true
	property :atoken_created_at, DateTime, :required => true
end

DataMapper.finalize

Neighbour.auto_upgrade!

helpers do
	def generate_token
		loop do
      		random_token = SecureRandom.urlsafe_base64(nil, false)
      		break random_token unless Neighbour.count(:atoken => random_token) > 0
    	end
	end

	def register_new_neighbour( params )
		now  = Time.now
		nhbr = Neighbour.new(
			:name              => params['name'],
			:email             => params['email'],
			:latitude          => params['latitude'],
			:longitude         => params['longitude'],
			:created_at        => now,
			:updated_at        => now,
			:atoken            => generate_token(),
			:atoken_created_at => now
			)
	
		if nhbr.valid?
			nhbr.save
			response = { 
				'status' => 'success',
				'data' => {'atoken' => nhbr.atoken} 
			}
		else
			response = { 
				'status' => 'fail',
				'data' => {'message' => 'failed validation'} 
			}
		end

		return {
			:response  => response, # NB, not yet json-ified
			:neighbour => nhbr      # in case the caller wants to do something with it
		}
	end
end

#get '/' do
#	halt(404)
#end

get '/' do
	content_type :json, 'charset' => 'utf-8'
	"Hello World".to_json
end

get '/neighbours' do
	content_type :json, 'charset' => 'utf-8'

	if !params.include?('atoken')
		response = { 
			'status' => 'fail',
			'data' => {'message' => 'no atoken'} 
		}
	elsif Neighbour.count(:atoken => atoken) == 0
		response = { 
			'status' => 'success',
			'data' => {'neighbours' => []} 
		}
	else
		# get the nhbrs
		if params.include?('latitude') and params.include?('longitude') and params.include?('radius')
			latitude  = params['latitude'].to_f
			longitude = params['longitude'].to_f
			radius    = params['radius'].to_f
	
			nhbrs = Neighbour.all(
				:latitude.gte  => latitude  - radius,
				:latitude.lte  => latitude  + radius,
				:longitude.gte => longitude - radius,
				:longitude.lte => longitude + radius
				)
	
			# and another pass thru the list of neighbours to ensure we are actually within the radius (and not in the corners of the bounding square)
			nhbrs.keep_if { |n|
				distance_in_miles = Geocoder::Calculations.distance_between( [n['latitude'], n['longitude']], [latitude, longitude] )
				distance_in_miles <= radius
			}
		else
			nhbrs = Neighbour.all()
		end

		# extract only the subset of data from each nhbr for return
		nhbrs_basics = nhbrs.map { |n| 
			{
				:name       => n.name,
				:latitude   => n.latitude,
				:longitude  => n.longitude,
				:updated_at => n.updated_at
			}
		 }

		response = { 
			'status' => 'success',
			'data' => {'neighbours' => nhbrs_basics} 
		}
	end

	return response.to_json
end

get '/neighbours_destroy' do
	Neighbour.destroy
end

get '/add_random_neighbours' do
	content_type :json, 'charset' => 'utf-8'

	params[:num]       ||= 3
	params[:latitude]  ||= 0.0
	params[:longitude] ||= 0.0
	params[:radius]    ||= 1 # miles

	# params values will be strings, so need to convert them

	num       = params[:num].to_i
	latitude  = params[:latitude].to_f 
	longitude = params[:longitude].to_f
	radius    = params[:radius].to_f 

	#puts "DEBUG: add_random_neighbours: latitude=#{latitude}, longitude=#{longitude}, radius=#{radius}"

	before_count = Neighbour.count
	before_count.to_json
	num.times do |i|
		now = Time.now
		random_coords = Geocoder::Calculations.random_point_near([latitude, longitude], radius)
		#puts "DEBUG: add_random_neighbours: i=#{i}, random_coords=#{random_coords.to_s}"
		nhbr = Neighbour.first_or_create(
			:name              => "neighbour #{now.to_f}",
			:latitude          => random_coords.first,
			:longitude         => random_coords.last,
			:created_at        => now,
			:updated_at        => now,
			:email             => SecureRandom.hex(10) + '@madeup.com',
			:atoken            => generate_token(),
			:atoken_created_at => now
			)
	end
	after_count = Neighbour.count
	(after_count - before_count).to_json
end

put '/register' do
	content_type :json, 'charset' => 'utf-8'
	registration = register_new_neighbour( params )
	return registration[:response].to_json
end
