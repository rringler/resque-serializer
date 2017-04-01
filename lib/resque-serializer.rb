require 'resque-serializer/mutex'
require 'resque-serializer/version'

module Resque
  module Plugins
    module Serializer
      def before_dequeue_check_lock(*args)
        can_lock?(args)
      end

      def around_perform_with_lock(*args)
        Mutex.synchronize(key(*args)) { yield }
      end

      private

      delegate :redis,
        to: Resque

      def can_lock?(args)
        !redis.get(key(*args))
      end

      def key(*args)
        "#{self.name.tableize.singularize}:#{args.map(&:to_s).join(',')}"
      end
    end
  end
end
