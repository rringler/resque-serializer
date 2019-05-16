# frozen_string_literal: true

module Resque
  module Plugins
    module Serializer
      module Serializers
        module Queue
          # before_enqueue: ✓
          #        enqueue: |
          #  after_enqueue: |
          # before_dequeue: |
          #        dequeue: |
          #  after_dequeue: ✗
          # before_perform:
          #        perform:
          #  after_perform:

          def before_enqueue_set_lock(*args)
            mutex(args).lock
          end

          def after_dequeue_clear_lock(*args)
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
            klass = name.tableize.singularize
            args  = args.map(&:to_s).join(',')

            "resque-serializer:#{klass}:#{args}"
          end
        end
      end
    end
  end
end
