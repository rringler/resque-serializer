require 'spec_helper'

class SerializedJob
  extend Resque::Plugins::Serializer

  @queue = :default

  def self.perform(*args); end
end

RSpec.describe Resque::Plugins::Serializer do
  let(:redis) { Resque.redis }

  before { redis.redis.flushall }

  describe 'enqueuing' do
    let(:args)       { %w(arg1 arg2) }
    let(:queue_key)  { SerializedJob.send(:queue_key, args) }
    let(:queue_lock) { Resque::Plugins::Serializer::Mutex.new(queue_key) }

    subject(:enqueue_job) { Resque.enqueue(SerializedJob, *args) }

    context 'when a queue_lock for the job exists' do
      before { queue_lock.lock! }

      it 'enqueuing the job returns nil (indicating the job was not enqueued)' do
        expect(enqueue_job).to be_nil
      end
    end

    context 'when a queue_lock for the job does not exist' do
      before { queue_lock.unlock }

      it 'enqueuing the job returns true (indicating the job was enqueued)' do
        expect(enqueue_job).to eq(true)
      end
    end
  end

  describe 'dequeuing' do
    let(:args)     { %w(arg1 arg2) }
    let(:job_key)  { SerializedJob.send(:job_key, args) }
    let(:job_lock) { Resque::Plugins::Serializer::Mutex.new(job_key) }

    before { Resque.enqueue(SerializedJob, *args) }

    subject(:dequeue_job) { Resque.dequeue(SerializedJob, *args) }

    context 'when a job_lock for the job exists' do
      before { job_lock.lock! }

      it 'dequeuing the job returns nil (the number of jobs dequeued)' do
        expect(dequeue_job).to be_nil
      end
    end

    context 'when a job_lock for the job does not exist' do
      before { job_lock.unlock }

      it 'dequeuing the job returns 1 (the number of jobs dequeued)' do
        expect(dequeue_job).to eq(1)
      end
    end
  end

  describe 'performing' do
    let(:args)       { %w(arg1 arg2) }
    let(:job_key)    { SerializedJob.send(:job_key, args) }
    let(:queue_key)  { SerializedJob.send(:queue_key, args) }
    let(:job_lock)   { spy('Resque::Plugins::Serializer::Mutex') }
    let(:queue_lock) { spy('Resque::Plugins::Serializer::Mutex') }

    before { Resque.inline = true  }
    after  { Resque.inline = false }

    before do
      allow(described_class::Mutex).to receive(:new).with(job_key).and_return(job_lock)
      allow(described_class::Mutex).to receive(:new).with(queue_key).and_return(queue_lock)
    end

    subject(:perform_job) { Resque.enqueue(SerializedJob, *args) }

    context 'if the job completes successfully' do
      it 'releases the locks after execution' do
        perform_job

        expect(job_lock).to   have_received(:unlock)
        expect(queue_lock).to have_received(:unlock)
      end
    end

    context 'if the job raises an exception' do
      let(:error) { RuntimeError }

      before do
        allow(SerializedJob).to receive(:perform).and_raise(error)
      end

      it 'still releases the locks after execution' do
        expect { perform_job }.to raise_error(error)

        expect(job_lock).to   have_received(:unlock)
        expect(queue_lock).to have_received(:unlock)
      end
    end
  end

  describe 'class methods' do
    describe '.job_key' do
      let(:args) { %w(arg1 arg2) }

      subject(:job_key) { SerializedJob.send(:job_key, args) }

      it 'returns a string with the job class and arguments' do
        expect(job_key).to eq(
          'resque-serializer:job:serialized_job:arg1,arg2'
        )
      end
    end

    describe '.queue_key' do
      let(:args) { %w(arg1 arg2) }

      subject(:queue_key) { SerializedJob.send(:queue_key, args) }

      it 'returns a string with the job class and arguments' do
        expect(queue_key).to eq(
          'resque-serializer:queue:serialized_job:arg1,arg2'
        )
      end
    end
  end
end
