require 'resque-serializer/mutex'
require 'resque-serializer/version'

module Resque
  module Plugins
    module Serializer
      def before_enqueue_set_queue_lock(*args)
        queue_mutex(args).lock
      end

      def before_dequeue_set_job_lock(*args)
        job_mutex(args).lock
      end

      def around_perform_with_lock(*args)
        yield
      ensure
        job_mutex(args).unlock
        queue_mutex(args).unlock
      end

      private

      delegate :redis,
        to: Resque

      def job_key(args)
        klass = self.name.tableize.singularize
        args  = args.map(&:to_s).join(',')

        "resque-serializer:job:#{klass}:#{args}"
      end

      def job_mutex(args)
        Mutex.new(job_key(args))
      end

      def queue_key(args)
        klass = self.name.tableize.singularize
        args  = args.map(&:to_s).join(',')

        "resque-serializer:queue:#{klass}:#{args}"
      end

      def queue_mutex(args)
        Mutex.new(queue_key(args))
      end
    end
  end
end
