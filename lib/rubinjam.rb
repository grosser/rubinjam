require "tmpdir"
require "bundler"
require "rubinjam/version"

module Rubinjam
  class << self
    def pack(dir)
      Dir.chdir(dir) do
        binaries = Dir["bin/*"]
        raise "No binary found in ./bin" if binaries.size == 0
        raise "Can only pack exactly 1 binary, found #{binaries.join(",")} in ./bin" unless binaries.size == 1
        content = environment + File.read(binaries.first)
        [File.basename(binaries.first), content]
      end
    end

    def pack_gem(gem, version)
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          # unpack
          command = ["gem", "unpack", gem]
          command << "-v" << version if version
          IO.popen(command).read

          # bundle
          Dir.chdir(Dir["*"].first) { Rubinjam.pack(Dir.pwd) }
        end
      end
    end

    private

    def libraries
      libs_from_paths(["lib"]).merge(gem_libraries)
    end

    def gem_libraries
      return {} unless gemspec = Dir["*.gemspec"].first
      return {} unless File.read(gemspec) =~ /add_(runtime_)?dependency/

      Dir.mktmpdir do |dir|
        sh "cp -R . #{dir}/"
        Dir.chdir(dir) do
          write "Gemfile", <<-RUBY.gsub(/^            /, "")
            source "https://rubygems.org"
            gemspec
          RUBY
          sh("rm -f Gemfile.lock")
          bundle = "bundle install --quiet --path bundle"
          sh("#{bundle} --local || #{bundle}")
          paths = sh("bundle exec ruby -e 'puts $LOAD_PATH'").split("\n")
          paths = paths.grep(%r{/gems/}).reject { |r| r =~ %r{/gems/bundler-\d} }
          libs_from_paths(paths)
        end
      end
    end

    def libs_from_paths(paths)
      paths.select { |p| File.directory?(p) }.inject({}) do |all, path|
        Dir.chdir path do
          all.merge!(Hash[Dir["**/*.rb"].map { |f| [f.sub(/\.rb$/, ""), File.read(f)] }])
        end
      end
    end

    def sh(command, options={})
      result = Bundler.with_clean_env { `#{command} 2>/dev/null` }
      raise "#{options[:fail] ? "SUCCESS" : "FAIL"} #{command}\n#{result}" if $?.success? == !!options[:fail]
      result
    end

    def write(file, content)
      FileUtils.mkdir_p(File.dirname(file))
      File.open(file, "w") { |f| f.write content }
    end

    def environment
      <<-RUBY.gsub(/^        /, "")
        #!/usr/bin/env ruby
        # generated by rubinjam v#{VERSION} -- https://github.com/grosser/rubinjam
        module Rubinjam
          LIBRARIES = {
            #{libraries.map { |name,content| "#{name.inspect} => #{content.inspect}" }.join(",\n    ")}
          }
        end

        def require(file)
          if code = Rubinjam::LIBRARIES[file]
            return if code == :loaded
            eval(code, TOPLEVEL_BINDING, "rubinjam/\#{file}")
            Rubinjam::LIBRARIES[file] = :loaded
          else
            super
          end
        end
      RUBY
    end
  end
end
