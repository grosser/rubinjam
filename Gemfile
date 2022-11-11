source "https://rubygems.org"

ruby File.read('.ruby-version').strip if ENV["RACK_ENV"] == "production" # strict ruby version only when deployed

gemspec

group :test do
  gem "bump"
  gem "rake"
  gem "rspec"
  gem "single_cov"
end

# server
gem "sinatra"
gem "sinatra-contrib"
gem "json"
gem "thin"
gem "rollbar"
