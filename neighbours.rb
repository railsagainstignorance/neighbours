require 'sinatra'
require 'json'

#get '/' do
#	halt(404)
#end

get '/' do
	content_type :json, 'charset' => 'utf-8'
	"Hello World".to_json
end