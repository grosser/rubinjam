require "spec_helper"
require "rake"
require "rubinjam/tasks"

SingleCov.covered! uncovered: 4

describe Rubinjam::Tasks do
  def expect_sh(includes, result)
    Rubinjam::Tasks.should_receive(:sh) { |*cmd| cmd.join(" ").should include includes }.and_return(result)
  end

  describe ".upload_binary" do
    # discard stdout
    around do |t|
      begin
        old = $stdout
        $stdout = StringIO.new
        t.call
      ensure
        $stdout = old
      end
    end

    it "uploads" do
      expect_sh "get-url", "git@github.com:foo/bar.git"
      expect_sh"curl -H", {id: 123}.to_json
      expect_sh"curl -X POST", ""
      expect_sh"rm -f", ""
      Rubinjam::Tasks.upload_binary "1.2.3", "abcd"
      `rm -f rubinjam`
    end
  end

  describe ".find_or_create_release" do
    it "creates" do
      output
      expect_sh"--data" , {id: 123}.to_json
      Rubinjam::Tasks.send(:find_or_create_release, ["x"], "foo/bar", "1.2.3")
    end

    it "fetches when existing" do
      output
      expect_sh "--data", {errors: ["foo"]}.to_json
      expect_sh "releases/tags", {id: 123}.to_json
      Rubinjam::Tasks.send(:find_or_create_release, ["x"], "foo/bar", "1.2.3").should == 123
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
