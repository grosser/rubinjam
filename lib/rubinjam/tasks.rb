require 'rubinjam'
require 'shellwords'
require 'json'

module Rubinjam
  module Tasks
    API_BASE =

    class << self
      def upload_binary(tag, github_token)
        # https://github.com/foo/bar or git@github.com:foo/bar.git -> foo/bar
        repo = sh("git", "remote", "get-url", "origin").strip
        repo.sub!(/\.git$/, "")
        repo = repo.split(/[:\/]/).last(2).join("/")

        auth = ["-H", "Authorization: token #{github_token}"]

        id = find_or_create_release(auth, repo, tag)
        puts "Release #{id}"

        # upload binary
        begin
          name = Rubinjam.write(Dir.pwd)
          puts "Uploading #{name} release asset"
          sh(
            "curl",
            "-X", "POST",
            "--data-binary", "@#{name}",
            "-H", "Content-Type: application/octet-stream",
            *auth,
            "https://uploads.github.com/repos/#{repo}/releases/#{id}/assets?name=#{name}"
          )
        ensure
          sh "rm", "-f", name.to_s
        end
      end

      def sh(*command)
        command = command.shelljoin
        result = `#{command}`
        raise "Command failed:\n#{command}\n#{result}" unless $?.success?
        result
      end

      private

      def find_or_create_release(auth, repo, tag)
        reply = sh("curl", *auth, "--data", {tag_name: tag}.to_json, "https://api.github.com/repos/#{repo}/releases")
        unless (id = JSON.parse(reply)["id"])
          reply = sh("curl", *auth, "https://api.github.com/repos/#{repo}/releases/tags/#{tag}")
          id = JSON.parse(reply).fetch("id")
        end
        id
      end
    end
  end
end

namespace :rubinjam do
  task :upload_binary  do
    # find token for auth
    github_token = begin
      Rubinjam::Tasks.sh("git", "config", "github.token").strip
    rescue
      abort "Set github.token with: git config --global github.token <GITHUB-TOKEN>"
    end

    # find current tag
    # TODO: allow users to set TAG= or do fuzzy match ?
    tag = Rubinjam::Tasks.sh("git", "describe", "--tags", "--exact-match").strip

    Rubinjam::Tasks.upload_binary(tag, github_token)
  end
end
