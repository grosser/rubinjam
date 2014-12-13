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
  end

  def write(file, content)
    File.open(file, "w") { |f| f.write content }
  end

  def rubinjam(command, options={})
    sh("#{Bundler.root}/bin/rubinjam #{command}", options)
  end

  def sh(command, options={})
    result = Bundler.with_clean_env { `#{command} #{"2>&1" unless options[:keep_output]}` }
    raise "#{options[:fail] ? "SUCCESS" : "FAIL"} #{command}\n#{result}" if $?.success? == !!options[:fail]
    result
  end
end
