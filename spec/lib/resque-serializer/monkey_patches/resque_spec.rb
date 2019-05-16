# frozen_string_literal: true

require 'spec_helper'

class ResqueDequeueHookJob
  extend Resque::Plugins::Serializer

  serialize :both

  @queue = :default

  def self.perform(*args); end
end

RSpec.describe ResqueSerializer::MonkeyPatches::Resque do
  describe 'when prepended' do
    let(:args)          { %w[arg1 arg2] }
    let(:queue_name)    { :default }
    let(:dequeue_hooks) { [] }
    let(:worker)        { Resque::Worker.new(queue_name) }

    before do
      allow(Resque::Plugin).
        to receive(:before_dequeue_hooks).
        and_return(dequeue_hooks)
      allow(Resque::Plugin).
        to receive(:after_dequeue_hooks).
        and_return(dequeue_hooks)

      Resque.enqueue(ResqueDequeueHookJob)
    end

    subject(:execute_job) { worker.reserve }

    it 'executes the dequeue hooks' do
      expect(::Resque::Plugin).to receive(:before_dequeue_hooks).ordered
      expect(::Resque::Plugin).to receive(:after_dequeue_hooks).ordered

      execute_job
    end
  end
end
