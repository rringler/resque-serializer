# frozen_string_literal: true

require 'spec_helper'

class JobSerializedByJob
  extend Resque::Plugins::Serializer

  @queue = :default

  serialize :job

  # before_enqueue:
  #        enqueue:
  #  after_enqueue:
  # before_dequeue: ✓
  #        dequeue: |
  #  after_dequeue: |
  # before_perform: |
  #        perform: |
  #  after_perform: ✗

  def self.perform(*_args); end
end

RSpec.describe JobSerializedByJob do
  let(:args)       { %w[arg1 arg2] }
  let(:queue_name) { :default }

  before do
    Resque.redis.redis.flushall
  end

  context 'with no jobs in the queue' do
    before do
      expect(queue_size).to eq(0)
    end

    it 'can enqueue the job' do
      expect { enqueue_job }.to change {
        queue_size
      }.from(0).to(1)
    end

    it 'can not execute any jobs' do
      expect(execute_job).to be_nil
    end
  end

  context 'with one job in the queue' do
    before do
      enqueue_job
      expect(queue_size).to eq(1)
    end

    it 'can enqueue the same job' do
      expect { enqueue_job }.to change {
        queue_size
      }.from(1).to(2)
    end

    it 'can execute the job' do
      expect(execute_job).to_not be_nil
    end
  end

  context 'with one job in the queue and one job being executed' do
    before do
      enqueue_job
      expect(queue_size).to eq(1)
      execute_job
      expect(queue_size).to eq(0)
      enqueue_job
      expect(queue_size).to eq(1)
    end

    it 'can enqueue the same job' do
      expect { enqueue_job }.to change {
        queue_size
      }.from(1).to(2)
    end
  end
end
