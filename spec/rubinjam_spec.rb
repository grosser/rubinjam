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
        sh("./foo", fail: true).should include("uninitialized constant Bar (NameError)")
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
    end

    it "does not use binding from inside require method" do
      write "lib/bar.rb", "puts defined?(code).inspect"
      write "bin/foo", "require 'bar'"
      rubinjam
      sh("./foo").should == "nil\n"
    end

    context "with gem dependency" do
      let(:gemspec) { "foo.gemspec" }

      before do
        write gemspec, <<-RUBY.gsub(/^          /, "")
          Gem::Specification.new "foo", '1.2.3' do |s|
            s.summary = "test"
            s.authors = ["Test"]
            s.email = "test@test.it"
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
    end

    it "fails with multiple binaries" do
      write "bin/foo", "puts 111"
      write "bin/bar", "puts 111"
      rubinjam("", :fail => true).should include "Can only pack exactly 1 binary"
    end

    it "fails without binary" do
      rubinjam("", :fail => true).should include "No binary found in ./bin"
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
