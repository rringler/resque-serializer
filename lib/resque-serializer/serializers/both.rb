module Resque
  module Plugins
    module Serializer
      module Serializers
        module Both

          # before_enqueue: ✓
          #        enqueue: |
          #  after_enqueue: |
          # before_dequeue: | ✓
          #        dequeue: | |
          #  after_dequeue: ✗ |
          # before_perform:   |
          #        perform:   |
          #  after_perform:   ✗

          def before_enqueue_set_queue_lock(*args)
            queue_mutex(args).lock
          end

          def before_dequeue_set_job_lock(*args)
            job_mutex(args).lock
          end

          def after_dequeue_clear_queue_lock(*args)
            queue_mutex(args).unlock
          end

          def around_perform_clear_job_lock(*args)
            yield
          ensure
            job_mutex(args).unlock
          end

          def queue_mutex(args)
            Serializer::Mutex.new(queue_key(args))
          end

          def job_mutex(args)
            Serializer::Mutex.new(job_key(args))
          end

          private

          def queue_key(args)
            klass = self.name.tableize.singularize
            args  = args.map(&:to_s).join(',')

            "resque-serializer:queue:#{klass}:#{args}"
          end

          def job_key(args)
            klass = self.name.tableize.singularize
            args  = args.map(&:to_s).join(',')

            "resque-serializer:job:#{klass}:#{args}"
          end
        end
      end
    end
  end
end
