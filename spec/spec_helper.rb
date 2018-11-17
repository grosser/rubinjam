require "bundler/setup"

require "single_cov"
SingleCov.setup :rspec

require "rubinjam/version"
require "rubinjam"

require "tmpdir"

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :should }
  config.mock_with(:rspec) { |c| c.syntax = :should }
end
