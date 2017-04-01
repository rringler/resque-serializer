require 'active_support'
require 'active_support/core_ext/numeric/time'

module Resque
  module Plugins
    module Serializer
      class Mutex
        class LockFailed < StandardError; end

        def self.synchronize(key, options = {}, &block)
          new(key, options).synchronize(&block)
        end

        def initialize(key, options = {})
          @key = key
          @ttl = options.fetch(:ttl, 5.minutes).to_i
        end

        def synchronize(&block)
          lock

          yield
        ensure
          unlock
        end

        def lock
          redis.set(key, set_options) || fail(LockFailed)
        end

        def unlock
          redis.del(key)
        end

        private

        attr_reader :key, :ttl

        delegate :redis,
          to: Resque

        def set_options
          {
            nx: true,
            px: ttl * 1000 # msecs
          }
        end
      end
    end
  end
end
