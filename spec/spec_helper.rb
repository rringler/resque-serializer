require 'resque-serializer'

require 'bundler/setup'
require 'mock_redis'
require 'resque'
require 'resque_spec'
require 'pry-byebug'

RSpec.configure do |config|
  config.expect_with(:rspec) do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    Resque.redis = MockRedis.new
  end
end
