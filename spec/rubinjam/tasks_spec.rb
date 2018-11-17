require "spec_helper"
require "rake"
require "rubinjam/tasks"

SingleCov.covered! uncovered: 5

describe Rubinjam::Tasks do
  describe ".upload_binary" do
    it "uploads" do
      Rubinjam::Tasks.should_receive(:sh) { |*cmd| cmd.join(" ").should include "get-url" }.and_return("git@github.com:foo/bar.git")
      Rubinjam::Tasks.should_receive(:sh) { |*cmd| cmd.join(" ").should include "curl -H" }.and_return({id: 123}.to_json)
      Rubinjam::Tasks.should_receive(:sh) { |*cmd| cmd.join(" ").should include "curl -X POST" }
      Rubinjam::Tasks.should_receive(:sh) { |*cmd| cmd.join(" ").should include "rm -f" }
      Rubinjam::Tasks.upload_binary "1.2.3", "abcd"
    end
  end

  describe ".sh" do
    it "executes" do
      Rubinjam::Tasks.sh("echo", "1").should == "1\n"
    end

    it "fails" do
      -> { Rubinjam::Tasks.sh("false") }.should raise_error(RuntimeError)
    end
  end
end
