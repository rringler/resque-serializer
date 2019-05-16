# frozen_string_literal: true

module ResqueSerializer
  module MonkeyPatches
    module Resque
      # NOTE: `Resque#pop` is called when working queued jobs via the
      # `resque:work` rake task. Resque's default implementation will
      # not trigger the `before_dequeue` or `after_dequeue` hooks;
      # this patch will force it do so.
      def pop(queue)
        return unless (job_details = decode(data_store.pop_from_queue(queue)))

        klass  = job_details['class'].safe_constantize
        args   = job_details['args']

        # Perform before_dequeue hooks. Don't perform dequeue if any hook
        # returns false
        before_hooks = ::Resque::Plugin.before_dequeue_hooks(klass).
          collect { |hook| klass.send(hook, *args) }

        return job_details if before_hooks.any? { |result| result == false }

        ::Resque::Plugin.after_dequeue_hooks(klass).each do |hook|
          klass.send(hook, *args)
        end

        job_details
      end
    end
  end
end

module Resque
  prepend ResqueSerializer::MonkeyPatches::Resque

  module_function :pop
end
