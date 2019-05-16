# frozen_string_literal: true

require 'resque-serializer'

require 'bundler/setup'
require 'mock_redis'
require 'resque'
require 'pry-byebug'
require 'resque_test_helper'

RSpec.configure do |config|
  config.expect_with(:rspec) do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    Resque.redis = MockRedis.new
  end

  config.include ResqueTestHelper
end
