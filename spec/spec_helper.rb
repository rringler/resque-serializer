require 'resque-serializer'

require 'active_support'
require 'active_support/core_ext/numeric/time'
require 'bundler/setup'
require 'mock_redis'
require 'resque'
require 'pry-byebug'

RSpec.configure do |config|
  config.expect_with(:rspec) do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    Resque.redis = MockRedis.new
  end
end
