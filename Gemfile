source "https://rubygems.org"

ruby File.read('.ruby-version').strip if ENV["RACK_ENV"] == "production" # strict ruby version only on heroku

gemspec

group :test do
  gem "bump"
  gem "rake"
  gem "rspec"
  gem "byebug", :platform => [:ruby_20, :ruby_21]
end

# server
gem "sinatra"
gem "sinatra-contrib"
gem "json"
gem "thin"
gem "rollbar"
