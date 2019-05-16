module Resque
  module Plugins
    module Serializer
      module Serializers
        module Job

          # before_enqueue:
          #        enqueue:
          #  after_enqueue:
          # before_dequeue: ✓
          #        dequeue: |
          #  after_dequeue: |
          # before_perform: |
          #        perform: |
          #  after_perform: ✗

          def before_dequeue_set_lock(*args)
            mutex(args).lock
          end

          def around_perform_clear_lock(*args)
            yield
          ensure
            mutex(args).unlock
          end

          private

          delegate :configuration,
            to: Resque::Plugins::Serializer

          delegate :mutex_generator,
            to: :configuration

          def mutex(args)
            mutex_generator.call(key(args))
          end

          def key(args)
            klass = self.name.tableize.singularize
            args  = args.map(&:to_s).join(',')

            "resque-serializer:#{klass}:#{args}"
          end
        end
      end
    end
  end
end
