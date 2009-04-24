# inspired by http://www.rowtheboat.com/archives/32
# slightly modified by jefflarkin


# get all datamapper related gems (assume sqlite3 to be database)
gem "addressable", :lib => "addressable/uri"
gem "do_sqlite3" if yes?("Install do_sqlite3?")
gem "do_mysql" if yes?("Install do_mysql?")
gem "do_postgres" if yes?("Install do_postgres?")
gem 'dm-validations'
gem 'dm-timestamps'
gem "dm-types"
gem "rspec", :lib => false
gem "rspec-rails", :lib => false
gem "datamapper4rail", :lib => 'datamapper4rails' # excuse the typo

rake "gems:install"

# have specs
generate("rspec")

# install datamapper rake tasks
generate("dm_install")

# fix config files to work with datamapper instead of active_record
run "sed -i config/environment.rb -e 's/#.*config.frameworks.*/config.frameworks -= [ :active_record ]/'"
run "sed -i spec/spec_helper.rb -e 's/^\\s*config[.]/#\\0/'"
run "sed -i test/test_helper.rb -e 's/^[^#]*fixtures/#\\0/'"

# fix a problem with missing class constants for models woth relations
initializer 'preload_models.rb', <<-CODE
require 'datamapper4rails/preload_models'
CODE

# set up git
git :init
git :add => '.'
git :commit => "-a -m 'Initial commit'"
