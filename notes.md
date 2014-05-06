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
- refactored neighbours_spec
- add_random_neighbours now adds within radius (and is tested for)

ToDo

- add full JSON responses to every API call, even if only status+count

## 25/04/2014 22:19

ToDo
- add full JSON responses to every API call
   + request valid=true/false
   + user action needed = true/false, action=re-authenticate
- require name/id for /neighbours call, so that location of name is updated
- add register route (server responds with token)
   + /neighbours call then requires token
   + require password, email, name, location
   + authentication? https://github.com/hassox/warden/wiki
      + https://github.com/nmattisson/sinatra-warden-api
- verify/escape all input
- add validity checks on requests, e.g. location cannot change too drastically
- /neighbours call only returns location/name/timestamps
- explore https
- capture/record environment (e.g. wifi, etc)
- CORS ?
- consider https://github.com/12-oz/pliny, "Opinionated template Sinatra app for writing excellent APIs in Ruby"

doing
- adding helpers section
   + notes on helpers: http://stackoverflow.com/questions/6916626/sinatra-helper-in-external-file
- adding test for /register
   + defining json format, http://labs.omniti.com/labs/jsend
- minitest details: http://www.rubyinside.com/a-minitestspec-tutorial-elegant-spec-style-testing-that-comes-with-ruby-5354.html
- adding token
   + http://stackoverflow.com/questions/18228324/i-need-to-generate-uuid-for-my-rails-application-what-are-the-optionsgems-i-h
   + http://stackoverflow.com/questions/6021372/best-way-to-create-unique-token-in-rails
- checking for token in /neighbours (expecting tests to fail)
   + /neighbour now returns status structure and requires token ... breaks tests

ToDo
- fix tests to work with new /neighbours
   + check requires token
   + pass in token
   + check returns correct response

## 26/04/2014 08:45
- refactored /register into def register_new_neighbour
- refactoring /neighbours and /add_random_neighbours
   + still errors, but fewer
- removing self from /neighbours response
- refactoring expectations (https://gist.github.com/ordinaryzelig/2032303)
   + need to change the order of expected/actual

ToDo
- check /neighbours does return excess user data
- CORS?
   + http://thibaultdenizet.com/tutorial/cors-with-angular-js-and-sinatra/

- adding /re-register

- Notes: long polling: http://www.sinatrarb.com/2011/09/30/sinatra-1.3.0.html

- logging? 

- documentation? https://github.com/jillesvangurp/sinatra-docdsl
   + annoying buglet where the error entry in the footer seems to need the extra {...}

- Q: versioning? (see Pliny? https://github.com/12-oz/pliny)

- add basic pages
   + views/layout.erb

- adding put /do_register
   + needed to use the shimmy: <input type="hidden" name="_method" value="put" /> and form action="post"

## 27/04/2013
- acceptace tests... 
   + using capybara: http://www.simontaranto.com/2013/10/18/testing-sinatra-apps-with-capybara-and-minitest.html

- Sinatra: modular vs classic: http://www.sinatrarb.com/intro.html#Modular%20vs.%20Classic%20Style

- Sinatra setup: 
   + http://blog.sourcing.io/structuring-sinatra
   + http://mayerdan.com/ruby/2013/08/20/fast-prototyping-with-sinatra/

- twitter bootstrap
   + https://github.com/bootstrap-ruby/sinatra-bootstrap

- RVM? http://tech.pro/tutorial/1303/bootstrap-your-web-application-with-ruby--sinatra

- parsing HTML for acceptance tests
   + added nokogiri gem
   + added spec/neighbours_web_spec.rb
   + using nokgiri: http://ruby.bastardsbook.com/chapters/html-parsing/

- The question "how can I call a ruby route from inside another ruby route?" is probably best answered by, "you don't. Instead, refactor the route you want to re-use so that it calls a helper function, and make that helper function available to the other route."

- /web/neighbours now works
   + ToDo: add display of neighbour entities in the page. DONE
   + add distance field, sort by distance, closest first
   + fixed bug which did not find neighbours

- should refactor out the /neighbours with no location/radius into a separate method

- not done /web/re-register

- maybe require atoken *and name*

## 28/04/2014

- trying to push to heroku. trouble with multiple accounts (work and personal)
   + http://stackoverflow.com/questions/20586992/your-account-someoneelsegmail-com-does-not-have-access-to-app-name
   + http://martyhaught.com/articles/2010/12/14/managing-multiple-heroku-accounts/
   + heroku plugins:install git://github.com/ddollar/heroku-accounts.git

$ heroku accounts:add personal
Enter your Heroku credentials.
Email: xxxxx@xxxx.com
Password (typing will be hidden):

Add the following to your ~/.ssh/config

Host heroku.personal
  HostName heroku.com
  IdentityFile /PATH/TO/PRIVATE/KEY
  IdentitiesOnly yes

$ heroku accounts:add work --auto
Enter your Heroku credentials.
Email: xxxx.xxxx@xxxx.com
Password (typing will be hidden):
Generating new SSH key
Generating public/private rsa key pair.
Your identification has been saved in c:/Users/lenovo/.ssh/identity.heroku.work.
Your public key has been saved in c:/Users/lenovo/.ssh/identity.heroku.work.pub.
The key fingerprint is:
xxxxx
Adding entry to ~/.ssh/config
Adding public key to Heroku account: xxxx.xxxx@xxxx.com

$ heroku accounts
work
personal

$ heroku accounts:default personal

$ heroku accounts
work
* personal

$ heroku accounts:set personal # or work

- added Profile and config.ru
- added/uncommented postgres and :production

- still not running on heroku
   + missing DB URL (not visible via heroku configs)

- created new app
   + heroku apps:destroy --app prev_app
   + heroku app:create
   + heroku accounts:default personal
   + git push heroku master

05/05/2014 20:49

- to attach a new/missing free Postgres instance for a heroku app
   + https://devcenter.heroku.com/articles/heroku-postgresql
   + $ heroku addons:add heroku-postgresql:dev

todo
- add some JS loveliness to the display
   + initially just some JS to draw a dynamic graph
   + then make it plot the neighbours
      + pondering http://ocanvas.org/
            + especially the satellite example
   + keep an eye on these for later: 
      + http://chapter31.com/2006/12/07/including-js-files-from-within-js-files/ 
      + http://www.sitepoint.com/using-sinatra-helpers-to-clean-up-your-code/
   + DONE
- display the actual neighbours (keeping them as satallites with satellites for now... ;-)
   + use log(radius)
      + so that remote neighbours at least show up
      + could it display *all* neighbours?
         + nighbours at opposite end of world would flicker about the periphery.

06/05/2014 19:18
- https://github.com/railsagainstignorance/neighbours

todo
- get coords from browser using JS