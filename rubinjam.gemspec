name = "rubinjam"
require "./lib/#{name.gsub("-","/")}/version"

Gem::Specification.new name, Rubinjam::VERSION do |s|
  s.summary = "Jam a gem into a universal binary that works with any ruby"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "https://github.com/grosser/#{name}"
  s.files = `git ls-files lib/ bin/ MIT-LICENSE`.split("\n")
  s.license = "MIT"
  s.executables = ["rubinjam"]
  s.add_runtime_dependency "bundler"
end
