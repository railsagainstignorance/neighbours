source 'https://rubygems.org'

gem "sinatra"
#gem 'sinatra-contrib'
gem "json"

gem "data_mapper"
gem "geocoder"

gem 'sinatra-docdsl'
gem 'rest-client'

gem 'nokogiri'

group :test do
	gem "rack-test"
end

group :development do
	gem "sinatra-contrib"
end

group :development, :test do
	gem "dm-sqlite-adapter"
	gem "sqlite3"
	gem "do_sqlite3"
end

group :production do
	gem "pg"
	gem "dm-postgres-adapter"
end
