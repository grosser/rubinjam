name = "rubinjam"
require "./lib/#{name.gsub("-","/")}/version"

Gem::Specification.new name, Rubinjam::VERSION do |s|
  s.summary = "Jam a gem into a universal binary that only needs some ruby installed"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "https://github.com/grosser/#{name}"
  s.files = `git ls-files lib/ bin/ MIT-LICENSE`.split("\n")
  s.license = "MIT"
end
