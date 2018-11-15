require "spec_helper"

describe Rubinjam do
  around do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir, &example)
    end
  end

  it "has a VERSION" do
    Rubinjam::VERSION.should =~ /^[\.\da-z]+$/
  end

  describe "CLI" do
    it "shows --version" do
      rubinjam("--version").should include(Rubinjam::VERSION)
    end

    it "shows --help" do
      rubinjam("--help").should include("rubinjam")
    end

    it "packs super simple" do
      write "bin/foo", "puts 111"
      rubinjam
      sh("./foo").should == "111\n"
    end

    it "packs with lib" do
      write "lib/bar.rb", "module BAR\n  BAZ = '\"111\"'\nend"
      write "bin/foo", "require 'bar'; puts BAR::BAZ"
      rubinjam
      sh("./foo").should == "\"111\"\n"
    end

    it "does not require twice" do
      write "lib/bar.rb", "puts 111"
      write "bin/foo", "require 'bar';require 'bar'"
      rubinjam
      sh("./foo").should == "111\n"
    end

    it "requires absolute files" do
      write "lib/bar.rb", "puts 111"
      write "bin/foo", "require File.expand_path('../lib/bar', __FILE__)"
      rubinjam
      write "lib/bar.rb", "puts 222"
      sh("./foo").should == "111\n"
    end

    describe 'autoload' do
      it "cannot load missing" do
        write "bin/foo", "puts Bar::BAZ"
        rubinjam
        sh("./foo", :fail => true).should include("uninitialized constant Bar (NameError)")
      end

      it "can autoload normal files" do
        write "lib/bar.rb", "module Bar; BAZ=111;end"
        write "bin/foo", "autoload :Bar, 'bar';puts Bar::BAZ"
        rubinjam
        sh("./foo").should == "111\n"
      end

      it "can autoload inside modules" do
        write "lib/bar/baz.rb", "module Bar; module Baz; FOO=111;end;end"
        write "lib/bar.rb", "module Bar; autoload :Baz, 'bar/baz';end"
        write "bin/foo", "require 'bar';puts Bar::Baz::FOO"
        rubinjam
        sh("./foo").should == "111\n"
      end

      it "can autoload inherited" do
        write "lib/bar/foo.rb", "module Bar; Foo = 111;end"
        write "lib/bar/baz.rb", "module Bar; module Baz; FOO=Foo;end;end"
        write "lib/bar.rb", "module Bar; autoload :Baz, 'bar/baz';autoload :Foo, 'bar/foo';end"
        write "bin/foo", "require 'bar';puts Bar::Baz::FOO"
        rubinjam
        sh("./foo").should == "111\n"
      end

      it "autoloads in correct order of usage" do
        write "lib/bar/baz.rb", "module Bar; module Baz; FOO=444;end;end;puts 333"
        write "lib/bar.rb", "module Bar; autoload :Baz, 'bar/baz';end; puts 111"
        write "bin/foo", "require 'bar';puts '222';puts Bar::Baz::FOO"
        rubinjam
        sh("./foo").should == "111\n222\n333\n444\n"
      end

      it "autoloads multiple modules in different namespaces" do
        write "lib/bar/baz.rb", "module Bar; module Baz; FOO=111;end;end"
        write "lib/baz/baz.rb", "module Baz; module Baz; FOO=222;end;end"
        write "lib/bar.rb", "module Bar; autoload :Baz, 'bar/baz';end;module Baz; autoload :Baz, 'baz/baz';end;"
        write "bin/foo", "require 'bar';puts Bar::Baz::FOO;puts Baz::Baz::FOO"
        rubinjam
        sh("./foo").should == "111\n222\n"
      end

      it "can autoload absolute paths" do
        write "lib/bar/baz.rb", "module Bar; module Baz; FOO=111;end;end"
        write "lib/bar.rb", "module Bar; autoload :Baz, File.expand_path('../bar/baz', __FILE__);end"
        write "bin/foo", "require 'bar'; puts Bar::Baz::FOO"
        rubinjam
        sh("./foo").should == "111\n"
      end

      it "does not loop when autoloaded constant is not found via require" do
        write "lib/bar/baz.rb", "module Bar; module Ooops; FOO=111;end;end"
        write "lib/bar.rb", "module Bar; autoload :Baz, 'bar/baz';end"
        write "bin/foo", "require 'bar';puts Bar::Baz::FOO"
        rubinjam
        sh("./foo", :fail => true).should include("uninitialized constant Bar::Baz (NameError)")
      end
    end

    it "does not use binding from inside require method" do
      write "lib/bar.rb", "puts defined?(code).inspect"
      write "bin/foo", "require 'bar'"
      rubinjam
      sh("./foo").should == "nil\n"
    end

    context "with gem dependency" do
      let(:gemspec) { "foo.gemspec" }
      let(:extra) { "" }

      before do
        write gemspec, <<-RUBY.gsub(/^          /, "")
          Gem::Specification.new "foo", '1.2.3' do |s|
            s.summary = "test"
            s.authors = ["Test"]
            s.email = "test@test.it"
            #{extra}
            s.add_runtime_dependency "parallel", "1.3.3"
          end
        RUBY
        write "bin/foo", "require 'parallel'; puts Parallel::VERSION"
      end

      it "packs with gem" do
        rubinjam
        sh("./foo").should == "1.3.3\n"
      end

      it "does not ship with bundler files" do
        rubinjam
        File.read("foo").should_not include("bundler/") # does not ship with bundler files
      end

      it "includes all local files" do
        write "lib/bar.rb", "puts 'bar'"
        write(gemspec, "require './lib/bar'\n" + File.read(gemspec))
        rubinjam # does not blow up
        sh("./foo").should == "1.3.3\n" # ... and still works
      end

      describe "with development dependency" do
        let(:extra) { "s.add_development_dependency 'pru'" }
        it "does not include development dependencies" do
          rubinjam
          File.read("foo").should_not include "pru"
        end
      end
    end

    it "fails with multiple binaries" do
      write "bin/foo", "puts 111"
      write "bin/bar", "puts 111"
      rubinjam("", :fail => true).should include "Can only pack exactly 1 binary"
    end

    it "prefers exe folder since bin is often used for local binaries" do
      write "bin/foo", "puts 111"
      write "exe/bar", "puts 111"
      rubinjam("").should == ""
      File.exist?("bar").should == true
    end

    it "fails without binary" do
      rubinjam("", :fail => true).should include "No binary found in ./exe or ./bin"
    end
  end

  describe ".pack_gem" do
    before { skip "only needed for server ..." if RUBY_VERSION < "2.0.0" } # they somehow work on travis, but I don't care ...

    it "packs a simple gem" do
      name, content = Rubinjam.pack_gem("pru")
      write(name, content)
      sh("chmod +x pru && ./pru -v").should =~ /\A\d\.\d\.\d\n\z/
    end

    it "packs a gem with json dependency without using bundler" do
      name, content = Rubinjam.pack_gem("cmd2json")
      write(name, content)
      sh("chmod +x cmd2json && ./cmd2json -v").should =~ /\A\d\.\d\.\d\n\z/
    end

    it "packs a gem with dependencies" do
      name, content = Rubinjam.pack_gem("maxitest")
      write(name, content)
      sh("chmod +x mtest && ./mtest -h").should include("check syntax only")
      File.read('mtest').should include "minitest/benchmark" # shipped with runtime dependency
    end
  end

  def write(file, content)
    FileUtils.mkdir_p(File.dirname(file))
    File.open(file, "w") { |f| f.write content }
  end

  def rubinjam(command="", options={})
    sh("#{Bundler.root}/bin/rubinjam #{command}", options)
  end

  def sh(command, options={})
    result = Bundler.with_clean_env { `#{command} #{"2>&1" unless options[:keep_output]}` }
    raise "#{options[:fail] ? "SUCCESS" : "FAIL"} #{command}\n#{result}" if $?.success? == !!options[:fail]
    result
  end
end
