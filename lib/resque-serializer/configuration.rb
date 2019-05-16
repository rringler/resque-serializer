# frozen_string_literal: true

module Resque
  module Plugins
    module Serializer
      class Configuration
        include Singleton

        attr_accessor :mutex_generator

        DEFAULT_MUTEX_GENERATOR = ->(key) { Serializer::Mutex.new(key) }

        def initialize
          @mutex_generator = DEFAULT_MUTEX_GENERATOR
        end
      end
    end
  end
end
