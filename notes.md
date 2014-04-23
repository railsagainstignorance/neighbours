# markdown syntax
- cheatsheet: https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet
- sandbox: http://markdown-here.com/livedemo.html

# steps
## 21/04/2014 21:30

- create dev dir, git init
- create test.rb

```ruby
ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'
require_relative 'neighbours.rb'

include Rack::Test::Methods

def app
	Sinatra::Application
end
```

   + minitest: http://mattsears.com/articles/2011/12/10/minitest-quick-reference

- ruby test.rb
   + "cannot load such file", i.e. we've not included the test gems yet
- create Gemfile

```ruby
source 'https://rubygems.org'
gem "sinatra"
gem "json"
gem "rack-test", :group => :test
```
- bundle install
   + Gem::InstallError: The 'json' native gem requires installed build tools.
      + via http://www.systemroot.ca/2012/07/how-to-install-ruby-on-rails-in-windows/
         + download http://rubyinstaller.org/downloads/, DevKit-tdm-32-4.5.2-20111229-1559-sfx.exe
         + ran/unpacked into c:/installs/ruby193/devkit
         + ruby dk.rb init
         + edited config.yml to remove old ruby line, and retain just the ruby193 entry
         + ruby dk.rb review, and then install
- bundle install # take two
   + yay!
- ruby test.rb

```
test.rb:4:in `require_relative': cannot load such file -- c:/Users/lenovo/dev/neighbours/neighbours.rb (LoadError)
```

- create repo on github
   + gem install hub
   + hub create neighbours
      + got 

```
...
Permission denied (publickey).
fatal: The remote end hung up unexpectedly
error: Could not fetch origin
```

   + via https://help.github.com/articles/error-permission-denied-publickey
      + added ~/.ssh/id_rsa.pub to github
   + reran hub create, got

```
railsagainstignorance/neighbours already exists on github.com
origin  git@github.com:railsagainstignorance/neighbours.git (fetch)
origin  git@github.com:railsagainstignorance/neighbours.git (push)
set remote origin: railsagainstignorance/neighbours
```

- git push origin master

- touch neighbours.rb
   + ruby test.rb --> 0 errors. Yay!

- added test for default route "hello world" in JSON and UTF8
- added route
- added test for 200 response
- added failed route

- adding local DB
   + via http://blog.dudeblake.com/2010/05/setting-up-sinatra-and-datamapper-on.html

```
gem "sqlite3"
gem "dm-core"
gem "dm-sqlite-adapter" #<-- NB, this is crucial
gem "do_sqlite3"
```

### Questions / ToDos
- tests involving setting and tearing down the db?
- create a DB entry
   + http://recipes.sinatrarb.com/p/models/data_mapper
- check for unique values: http://datamapper.org/docs/validations.html
- create additonal neighbours, relative/close to long/lat

## 22/04/2014 19:30

- adding favico.ico (built via http://www.favicon.cc/)
   + created test
   + created favicon
   + mkdir public; cd favico.ico public
   + yay!

- removed dm-core from Gemfile (covered by data_mapper gem)

- refactored Gemfile into dev/test/prod, ditto configure in neighbours.rb
   + now need to specify test db for tests
   + possibly use  
      + DataMapper::Logger.new($stdout, :debug)
      + DataMapper.setup(:default, 'sqlite::memory:')
   + via http://www.millwoodonline.co.uk/blog/mini-minitest-tutorial
   + Q: still not clear how to setup a test db
   + Q: what is the difference between a spec and a test?
   + created "configure :test"  entry in neightbours.rb
   + created spec folder, spec_helper, neighbours_spec
   + created Rakefile
   + test doing: rake test

- adding db validations
   + require dm-validations
      +  property :name,     String, :required => true, :unique => true

- added sinatra/reloader, via dev gem sinatra-contrib

- refactoring tests and code to support add_random_neighours
   + so far just handling correct number
   + next to add within radius of
      + adding gem geocoder (https://github.com/alexreisner/geocoder)
      + need to require 'geocoder' in order to have access to Geocoder::Calculations.distance_between
   + new route: /add_random_neighbours
   + testing it for neighbours within radius

ToDo
- create neighbours within radius
   + maybe have to switch from DataMapper to ActiveRecord to support use of geocoder
   + also, appears to be some downsides to using sqlite: https://github.com/alexreisner/geocoder, "Distance Queries in SQLite"

## 23/04/2014 22:35

- reset Geocoder.configure( ) to default (i.e. :unit = :mi)

- to create nearby random neighbours, can maybe use random_point_near (via http://www.omniref.com/ruby/gems/geocoder/1.1.9/classes/Geocoder::Calculations)
   + yay, after converting the params values to ints and floats

