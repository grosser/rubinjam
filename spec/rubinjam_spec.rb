require "spec_helper"

describe Rubinjam do
  it "has a VERSION" do
    Rubinjam::VERSION.should =~ /^[\.\da-z]+$/
  end
end
