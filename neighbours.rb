require 'sinatra'
require "sinatra/reloader" if development?

require 'json'
require 'data_mapper'
require 'dm-validations'

require 'geocoder'
require 'pp'

require 'docdsl'
require 'rest_client'
require 'uri'
require 'logger'

require 'nokogiri'
require 'open-uri'

configure do
	set :default_radius, 1.0
end

configure :test do
	DataMapper.setup( :default, "sqlite3::memory:" )
end

configure :development do
	DataMapper.setup( :default, "sqlite3://#{Dir.pwd}/neighbours.db" )
end

configure :production do
	DataMapper.setup( :default, ENV['DATABASE_URL'] )
end

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

register Sinatra::DocDsl
page do      
	title "Neighbours POC"
	introduction "update your location and see who is nearby."
	footer "
# A note on the API responses
The API methods respond with JSON using the [JSEND convention](http://labs.omniti.com/labs/jsend).

## success 
{:status => 'success', :data => {:assorted => 'stuff', :that_makes_up => 'the response'}}

## failure (because of the data provided)
{:status => 'fail', :data => {:message => 'why did it fail with those params?'}}

## error (because of code/system/karma)
{{:status => 'error', :message => 'what was the error'}} <-- the [DocDSL](https://github.com/jillesvangurp/sinatra-docdsl) is a bit broken and needs the extra {...} on this one line

## the end
"
end

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
			:name              => params[:name],
			:email             => params[:email],
			:latitude          => params[:latitude],
			:longitude         => params[:longitude],
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
				'data' => {'message' => "failed validation: error=#{nhbr.errors.map { |e| e.to_s }.to_s}"} 
			}
		end

		return {
			:response  => response, # NB, not yet json-ified
			:neighbour => nhbr      # in case the caller wants to do something with it
		}
	end

	def re_register_neighbour( params )
		now  = Time.now

		missing_params = []
		['name', 'email', 'latitude', 'longitude'].each do |n|
			missing_params << n if ! params.include?(n)
		end

		if ! missing_params.empty?
			response = {
				:status => 'fail',
				:data   => {
					:message => "missing params: #{missing_params}"
				}
			}
		else
			nhbrs = Neighbour.all( :name => params['name'])

			if nhbrs.count == 0
				response = {
					:status => 'fail',
					:data => {
						:message => 'no such user'
					}
				}
			elsif nhbrs.count > 1
				response = {
					:status => 'error',
					:message => 'duplicate users'
				}
			else
				nhbr = nhbrs.first

				nhbr.latitude          = params[:latitude]
				nhbr.longitude         = params[:longitude]
				nhbr.atoken            = generate_token()
				nhbr.atoken_created_at = now
				nhbr.updated_at        = now
			
				if nhbr.valid?
					nhbr.save
					response = { 
						'status' => 'success',
						'data' => {'atoken' => nhbr.atoken} 
					}
				else
					response = { 
						'status' => 'fail',
						'data' => {'message' => "failed validation@: error=#{nhbr.errors.map { |e| e.to_s }.to_s}"} 
					}
				end
			end
		end

		return {
			:response  => response, # NB, not yet json-ified
			:neighbour => nhbr      # in case the caller wants to do something with it
		}
	end

	def validate_token( atoken )
		if atoken.nil?
			response = { 
				:status => 'fail',
				:data   => {:message => 'no atoken'} 
			}
		else
			nhbrs = Neighbour.all( :atoken => atoken )
	
			if nhbrs.count == 0
				response = { 
					:status => 'fail',
					:data   => {:message => 'unrecognised token'} 
				}
			elsif nhbrs.count > 1
				response = {
					:status  => 'error',
					:message => 'duplicate atoken found'
				}
			else
				response = {
					:status => 'success',
					:data   => { :neighbour => nhbrs.first }
				}
			end
		end

		return response
	end

	def extract_neighbour_basics( n )
			{
				:name       => n.name,
				:latitude   => n.latitude,
				:longitude  => n.longitude,
				:updated_at => n.updated_at
			}
	end

	def extract_neighbours_basics( nhbrs )
		nhbrs.map { |n| extract_neighbour_basics(n) }
	end

	def lookup_neighbours( params )
		now = Time.now
		atoken_response = validate_token( params[:atoken] )
	
		if atoken_response[:status] != 'success'
			response = atoken_response
		elsif ! ( 	params.include?('latitude') and 
					params.include?('longitude') and 
					params.include?('radius') 
				)
			response = { 
				:status => 'fail',
				:data   => {:message => 'missing any/all of latitude/longitude/radius'} 
			}
		else
			latitude  = params['latitude'].to_f
			longitude = params['longitude'].to_f
			radius    = params['radius'].to_f
					# update the location of this instance
			nhbr = atoken_response[:data][:neighbour]
			update_ok = nhbr.update(
				:latitude   => latitude,
				:longitude  => longitude,
				:updated_at => now
				)
			if !update_ok
				response = { 
					:status  => 'error',
					:message => 'failed to update location' 
				}
			else
				nhbrs_basics = extract_neighbours_basics( 
						Neighbour.all(
							:latitude.gte  => latitude  - radius,
							:latitude.lte  => latitude  + radius,
							:longitude.gte => longitude - radius,
							:longitude.lte => longitude + radius,
							:id.not        => nhbr.id
						)
					)

				# and another pass thru the list of neighbours to ensure we are actually within the radius (and not in the corners of the bounding square)
				nhbrs_basics.keep_if { |n|
					distance_in_miles = Geocoder::Calculations.distance_between( [n[:latitude], n[:longitude]], [latitude, longitude] )
					n[:distance] = distance_in_miles # possibly naughty, but modifies the nhbr
					distance_in_miles <= radius
				}

				# sort by distance, closest first
				nhbrs_basics.sort! { |x,y| x[:distance] <=> y[:distance] }

				response = { 
					'status' => 'success',
					'data' => {
						'neighbours' => nhbrs_basics,
						'me'         => extract_neighbour_basics(nhbr)
					} 
				}
			end
		end

		return response
	end

	def lookup_neighbours_all( params )
		atoken_response = validate_token( params[:atoken] )
	
		if atoken_response[:status] != 'success'
			response = atoken_response
		else
			nhbrs_basics = extract_neighbours_basics( Neighbour.all() )
			
			response = { 
				'status' => 'success',
				'data' => {'neighbours' => nhbrs_basics} 
			}
		end

		return response
	end

	def add_random_neighbours( params )
		atoken_response = validate_token( params[:atoken] )
	
		if atoken_response[:status] != 'success'
			response = atoken_response
		else
			num       = (params[:num]       || 3  ).to_i
			radius    = (params[:radius]    || 1  ).to_f # miles
			latitude  = (params[:latitude]  || 0.0).to_f
			longitude = (params[:longitude] || 0.0).to_f
		
			now          = Time.now
			before_count = Neighbour.count
			responses    = []
		
			num.times do |i|
				new_latitude, new_longitude = 
					Geocoder::Calculations.random_point_near([latitude, longitude], radius)
				
				random_params = {
					:latitude  => new_latitude,
					:longitude => new_longitude,
					:name      => "neighbour #{now.to_f}, #{i} of #{num}",
					:email     => SecureRandom.hex(10) + '@madeupdomain.com'
				}
		
				registration = register_new_neighbour( random_params )
				responses << registration[:response]
			end
		
			after_count = Neighbour.count
			num_added   = after_count - before_count
		
			if num_added == num
				response = { 
					:status => 'success',
					:data   => {:num_added => num_added} 
				}
			else
				response = { 
					:status => 'fail',
					:data   => {:message => "only added #{num_added} out of #{num}: responses=#{responses.to_s}"} 
				}
			end
		end
		return response
	end

	# display-related helpers

	# If @title is assigned, add it to the page's title.
	def title
		brand = 'Neighbours'
		if @title
			"#{@title} -- #{brand}"
		else
			brand
		end
	end

	# Format the Ruby Time object returned from a post's created_at method
	# into a string that looks like this: 06 Jan 2012
	def pretty_date(time)
		time.strftime("%d %b %Y")
	end

	# from http://www.sitepoint.com/using-sinatra-helpers-to-clean-up-your-code/
	# include this in the layout file: <%= javascripts %>
	# add extra non-standard js in the route: @js = ["custom.js","sorter.js","colorpicker.js"]

	set :javascripts, [] # default list of js for all web pages is empty for now

	def javascripts *scripts
    	javascripts = (@js ? @js + settings.javascripts + scripts : settings.javascripts + scripts).uniq
    	
    	javascripts.map { |script|
    		"<script src=\"/#{script}\"></script>"
    	}.join
	end
end

documentation 'Hello? Is this thing on?' do
    response '', { :status => 'success', :data => { :message => 'Hello World' }}
end
get '/' do
	content_type :json, 'charset' => 'utf-8'
	
	{ 
		:status => 'success',
		:data   => {:message => 'Hello World'} 
	}.to_json
end

documentation 'user updates location and receives list of neighbours' do
    query_param :latitude,  'current location of user'
    query_param :longitude, 'current location of user'
    query_param :radius,    'how big is the neighbourhood? (possibly being deprecated)'
    query_param :atoken,    'authentication token'
    response '', {
    	:status => 'success', 
    	:data => { 
    		:neighbours => {
    			:name => "neighbour's name",
    			:latitude => 'most recent location of neighbour',
    			:longitude => 'most recent location of neighbour',
    			:updated_at => 'when neighbour last updated their location'
    			},
    		:me => {
    			:name => "my name",
    			:latitude => 'my most recent location',
    			:longitude => 'my most recent location',
    			:updated_at => 'when I last updated my location'
    			}
    		}
    	}
end
get '/neighbours' do
	content_type :json, 'charset' => 'utf-8'
	logger.info "/neighbours: params=#{params.to_s}"
	response = lookup_neighbours( params )
	return response.to_json
end

get '/neighbours/all' do
	content_type :json, 'charset' => 'utf-8'
	logger.info "/neighbours/all: params=#{params.to_s}"
	response = lookup_neighbours_all( params )
	return response.to_json
end


get '/neighbours_destroy' do
	Neighbour.destroy
end

get '/add_random_neighbours' do
	content_type :json, 'charset' => 'utf-8'
	response = add_random_neighbours( params )
	return response.to_json
end

documentation "register a new user" do
    query_param :name, "user name (must be unique)"
    query_param :email, "email address (not used yet, but must be unique)"
    query_param :latitude, "current location of user"
    query_param :longitude, "current location of user"
    response '', {:status => 'success', :data => {:atoken => 'to be used in all subsequent requests by user'}}
end
put '/register' do
	content_type :json, 'charset' => 'utf-8'
	registration = register_new_neighbour( params )
	return registration[:response].to_json
end

documentation "re-register a new user (due to lost/invalidated token)" do
    query_param :name, "user name (must be unique)"
    query_param :email, "email address (not used yet, but must be unique)"
    query_param :latitude, "current location of user"
    query_param :longitude, "current location of user"
    response '', {:status => 'success', :data => {:atoken => 'to be used in all subsequent requests by user'}}
end
put '/re-register' do
	content_type :json, 'charset' => 'utf-8'
	registration = re_register_neighbour( params )
	return registration[:response].to_json
end

# this tells docdsl to render the documentation when you do a GET on /doc
doc_endpoint "/doc" 

# web-facing routes

get '/web/register' do
	erb :register, :locals => {:msg => params['msg']}
end

put '/web/do_register' do
	# "reached put '/web/do_register'"
	registration = register_new_neighbour( params )
	api_response = registration[:response]

	if api_response['status'] == 'fail'
		redirect to("/web/register?msg=#{URI.escape(api_response['data']['message'])}")
	elsif api_response['status'] == 'error'
		redirect to("/web/register?msg=#{URI.escape(api_response['message'])}")
	else
		atoken    = api_response['data']['atoken']
		latitude  = params['latitude']
		longitude = params['longitude']
		redirect to("/web/neighbours?atoken=#{URI.escape(atoken)}&latitude=#{URI.escape(latitude)}&longitude=#{URI.escape(longitude)}&radius=#{settings.default_radius}")
	end
end

get '/web/neighbours' do
	@js = ['js/ocanvas-2.7.1.min.js', 'js/satellites.js', 'js/geolocation.js']
	# check params, do registration, obtain atoken
	api_response = lookup_neighbours( params )

	if api_response[:status] == 'fail'
		message = api_response[:data][:message] || "no message"
		escaped_message = URI.escape(message)
		redirect to("/web/register?msg=#{escaped_message}")
	elsif api_response[:status] == 'error'
		message = api_response[:message] || "no message"
		redirect to("/web/register?msg=#{URI.escape(message)}")
	else
		erb :neighbours, 
			:locals => {
				:atoken     => params['atoken'], 
				:radius     => settings.default_radius,
				:latitude   => params['latitude']  || 0.0,
				:longitude  => params['longitude'] || 0.0,
				:neighbours => api_response['data']['neighbours'],
				:me         => api_response['data']['me']
			}
	end
end