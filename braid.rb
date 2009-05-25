# bootstrapper.rb 
# Rails Bootstrapper using rails template
# Based on Extended Bort -http://github.com/laktek/extended-bort/tree/master 
# Ideal to use when building a comprehensive web app
# Uses Braid to track remote repos.
# by Lakshan Perera  

# Use Braid to track remote git or svn repos.
  def braid(command, repo, options={})
    other_params = ""
    path = ""

    options.each do |key, value|
      if key == :path
        path = value
      elsif value.is_a?(String)
        other_params << " --#{key}=#{value}"
      else #assume everything else are booleans
        other_params << " --#{key}" if value
      end
    end

    run "braid #{command.to_s} #{repo} #{path} #{other_params}" 
  end

# Delete unnecessary files
  run "rm README"
  run "rm public/index.html"
  run "rm public/favicon.ico"
  run "rm public/robots.txt"
  run "rm -f public/javascripts/*"
  run "rm -f public/stylesheets/*"

# Download JQuery
  run "curl -L http://jqueryjs.googlecode.com/files/jquery-1.3.2.min.js > public/javascripts/jquery.js"
  #run "curl -L http://jqueryjs.googlecode.com/svn/trunk/plugins/form/jquery.form.js > public/javascripts/jquery.form.js"

 # Set up git repository
  git :init
 
# Copy database.yml for distribution use
  run "cp config/database.yml config/database.yml.example"

# setup gitignore
  run "touch tmp/.gitignore log/.gitignore"
  run %{find . -type d -empty | xargs -I xxx touch xxx/.gitignore}
  file '.gitignore', <<-CODE
  log/\\*.log
  log/\\*.pid
  db/\\*.db
  db/\\*.sqlite3
  db/schema.rb
  tmp/\\*\\*/\\*
  .DS_Store
  doc/api
  doc/app
  config/database.yml
  CODE
 
# add files to git
  git :add => '.'

# do the initial commit
  git :commit => "-a -m 'Initial commit'"

# get edge rails (branch 2.3 stable)
  braid :add, "git://github.com/rails/rails.git", {:path => "vendor/rails", :branch => "2-3-stable"} 

  #Install Plugins
  #BDD  
  braid :add, "git://github.com/dchelimsky/rspec.git", :rails_plugin => true
  braid :add, "git://github.com/dchelimsky/rspec-rails.git", :rails_plugin => true
  braid :add, "git://github.com/rails/exception_notification.git", :rails_plugin => true
  braid :add, "git://github.com/notahat/machinist.git", :rails_plugin => true

  #Core Functionality
  braid :add, "git://github.com/binarylogic/authlogic.git", :rails_plugin => true
  braid :add, "git://github.com/mislav/will_paginate.git", :rails_plugin => true
  braid :add, "git://github.com/sbecker/asset_packager.git", :rails_plugin => true
  braid :add, "git://github.com/rubyist/aasm.git", :rails_plugin => true
  braid :add, "git://github.com/rotuka/annotate_models.git", :rails_plugin => true

  #Debugging and performance
  braid :add, "git://github.com/brynary/rack-bug.git", :rails_plugin => true
  braid :add, "git://github.com/rails/exception_notification.git", :rails_plugin => true
  braid :add, "git://github.com/ntalbott/query_trace.git", :rails_plugin => true

  #Optional Functionality
  optional_plugins = [["Atom Feed Helper", "git://github.com/rails/atom_feed_helper.git"], 
                      ["Country Select", "git://github.com/rails/country_select.git"],
                      ["Default Value (for model attributes)", "git://github.com/FooBarWidget/default_value_for.git"],
                      ["PaperClip (for file uploads)", "git://github.com/thoughtbot/paperclip.git"] ]

  optional_plugins.each do |plugin|
    if yes?("Install plugin #{plugin[0]}?")
      braid :add, plugin[1], :rails_plugin => true
    end
  end

  #Install the gems
  gem "capistrano-ext", :lib => "capistrano", :version => "1.2.1" #capistrano multistage
  gem "faker" #for machinist shams
  gem "nokogiri" #required for webrat
  gem "aslakhellesoy-cucumber", :lib => "cucumber", :source => "http://gems.github.com"
  gem "brynary-webrat",  :lib => "webrat", :source => "http://gems.github.com"
  gem 'sqlite3-ruby', :lib => 'sqlite3'
  gem 'RedCloth', :lib => 'redcloth'
  rake('gems:install', :sudo => true)

  #run default generators
  rake('db:sessions:create')
  generate("rspec")
  generate("cucumber")
  rake('db:migrate')
  run("capify .")

  #create machinist blueprints file
  run "touch spec/blueprints.rb"

  #create initializers
  #asset packager initializer
  initializer 'asset_package.rb', <<-CODE
  Synthesis::AssetPackage.merge_environments = ["staging", "production"]
  CODE

  #fix the rails default error fileds
  initializer 'fix_field_errors.rb', <<-CODE
  #Changing the default behavior of field Errors
  ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
    msg = instance.error_message
    if html_tag =~ /<(input|textarea|select)[^>]+class=/
      class_attribute = html_tag =~ /class=['"]/
      html_tag.insert(class_attribute + 7, "error")
    elsif html_tag =~ /<(input|textarea|select)/
      first_whitespace = html_tag =~ /\s/
      html_tag[first_whitespace] = " class='error' "
    end
    html_tag
  end 
  CODE

  initializer 'exception_notification.rb', <<-CODE
  #TODO: Change the settings 
  ExceptionNotifier.exception_recipients = %w(admin@example.com)
  ExceptionNotifier.sender_address = %("Your Project Bot <bot@example.com>")
  ExceptionNotifier.email_prefix = "[Your Project Name - \\#\\{RAILS_ENV\\}] "
  CODE

  initializer 'action_mailer_configs.rb', <<-CODE
  #TODO: Change the settings
  ActionMailer::Base.smtp_settings = {
    :address => "localhost",
    :port => 25,
    :domain => "your mail server domain"
  }
  CODE

  git :commit => "-am 'Done default bootstrapping. App is ready for development.'"
  puts "Congratulations! Bootstrapping Done."
