require 'spec_helper'

class ResqueDequeueHookJob
  extend Resque::Plugins::Serializer

  serialize :both

  @queue = :default

  def self.perform(*args); end
end

RSpec.describe ResqueDequeueHookJob do
  let(:args)          { %w[arg1 arg2] }
  let(:queue_name)    { :default }
  let(:dequeue_hooks) { [] }

  before do
    allow(Resque::Plugin)
      .to receive(:before_dequeue_hooks)
      .and_return(dequeue_hooks)
    allow(Resque::Plugin)
      .to receive(:after_dequeue_hooks)
      .and_return(dequeue_hooks)
    enqueue_job
  end

  it 'executes the dequeue hooks' do
    expect(::Resque::Plugin).to receive(:before_dequeue_hooks).ordered
    expect(::Resque::Plugin).to receive(:after_dequeue_hooks).ordered

    execute_job
  end
end
