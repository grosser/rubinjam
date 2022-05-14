name = "rubinjam"
require "./lib/#{name.gsub("-","/")}/version"

Gem::Specification.new name, Rubinjam::VERSION do |s|
  s.summary = "Jam a gem into a universal binary that works with any ruby"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "https://github.com/grosser/#{name}"
  s.files = Dir['{lib/**/*.rb,bin/*,MIT-LICENSE}']
  s.license = "MIT"
  s.executables = ["rubinjam"]
  s.add_runtime_dependency "bundler"
  s.required_ruby_version = '>= 2.5'
end
