# frozen_string_literal: true

require 'active_support/core_ext/numeric/time'

module Resque
  module Plugins
    module Serializer
      class Mutex
        class LockFailed < StandardError; end

        attr_reader :key, :ttl

        delegate :redis,
          to: :Resque

        def initialize(key, ttl: 5.minutes)
          @key = key
          @ttl = ttl.to_i
        end

        def lock
          !!redis.set(key, true, set_options)
        end

        def lock!
          !!redis.set(key, true, set_options) || raise(LockFailed)
        end

        def locked?
          !!redis.get(key)
        end

        def unlock
          !!redis.del(key)
        end

        private

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
