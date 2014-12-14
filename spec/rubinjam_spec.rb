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
      rubinjam("", fail: true).should include "Can only pack exactly 1 binary"
    end

    it "fails without binary" do
      rubinjam("", fail: true).should include "No binary found in ./bin"
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
