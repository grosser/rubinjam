require "bundler/setup"
require "bundler/gem_tasks"
require "bump/tasks"

def server(extra=nil)
  exec "rackup server/config.ru #{extra}"
end

def run(cmd)
  result = `#{cmd}`
  raise "Failed #{result}" unless $?.success?
  result
end

def child_pids(pid)
  pipe = IO.popen("ps -ef | grep #{pid}")

  pipe.readlines.map do |line|
    parts = line.split(/\s+/)
    parts[2].to_i if parts[3] == pid.to_s and parts[2] != pipe.pid.to_s
  end.compact
end

task :default do
  sh "rspec spec/"
  Rake::Task[:generate].invoke
  Rake::Task[:test_server].invoke unless RUBY_VERSION < "2.0.0"
end

task :generate do
  run "./bin/rubinjam && mv rubinjam examples/dogfood"
  Bundler.with_clean_env { run "cd examples/hello_world && ../dogfood/rubinjam" } # using it's own compiled version to compile :D
  raise "compile error" unless run("./examples/hello_world/hello_world") == "hello world\n"
end

task :server do
  server
end

task :test_server do
  pid = fork { server ">/dev/null 2>&1" }
  begin
    sleep 5
    result = `curl --silent 127.0.0.1:9292/pack/pru > pru && chmod +x pru && ./pru -h`
    raise "Server failed: #{result}" unless result.include?("Pipeable Ruby")
  ensure
    `rm -f pru`
    (child_pids(pid) + [pid]).each { |pid| Process.kill(:TERM, pid) }
  end
end
