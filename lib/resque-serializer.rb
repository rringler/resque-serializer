require 'resque-serializer/version'
require 'resque-serializer/monkey_patches/resque'
require 'resque-serializer/mutex'
require 'resque-serializer/serializers/both'
require 'resque-serializer/serializers/combined'
require 'resque-serializer/serializers/job'
require 'resque-serializer/serializers/queue'

module Resque
  module Plugins
    module Serializer
      def serialize(resource)
        case resource
        when :job      then extend(Serializers::Job)
        when :queue    then extend(Serializers::Queue)
        when :both     then extend(Serializers::Both)
        when :combined then extend(Serializers::Combined)
        else                raise_invalid_resource
        end
      end

      private

      def raise_invalid_resource
        error_msg = begin
          'The passed argument must be one of: [:job, :queue, :both, :combined]'
        end

        raise ArgumentError, error_msg
      end
    end
  end
end
