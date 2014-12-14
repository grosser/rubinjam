require "bundler/setup"
require "bundler/gem_tasks"
require "bump/tasks"

def run(cmd)
  result = `#{cmd}`
  raise "Failed #{result}" unless $?.success?
  result
end

task :default do
  sh "rspec spec/"
  Rake::Task[:generate].invoke
end

task :generate do
  run "./bin/rubinjam && mv rubinjam examples/dogfood"
  run "cd examples/hello_world && ../dogfood/rubinjam" # using it's own compiled version to compile :D
  raise "compile error" unless run("./examples/hello_world/hello_world") == "hello world\n"
end

task :server do
  sh "bundle exec rackup server/config.ru"
end
