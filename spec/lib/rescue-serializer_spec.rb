require 'spec_helper'

class SerializedJob
  extend Resque::Plugins::Serializer

  @queue = :default

  def self.perform(*args); end
end

RSpec.describe Resque::Plugins::Serializer do
  let(:redis) { Resque.redis }

  before { redis.redis.flushall }

  describe 'dequeuing' do
    subject(:dequeue_job) { Resque.dequeue(SerializedJob) }

    before do
      Resque.enqueue(SerializedJob, 'args')
      expect(SerializedJob).to receive(:can_lock?).and_return(can_lock)
    end

    context 'when a lock can be acquired' do
      let(:can_lock) { true }

      it 'calls .unlocked?' do
        expect(dequeue_job).to eq(1)
      end
    end

    context 'when a lock can not be acquired' do
      let(:can_lock) { false }

      it 'calls .unlocked?' do
        expect(dequeue_job).to be_nil
      end
    end
  end

  describe 'performing' do
    let(:args) { ['args'] }
    let(:key)  { SerializedJob.send(:key, *args) }

    before { Resque.inline = true  }
    after  { Resque.inline = false }

    subject(:perform_job) { Resque.enqueue(SerializedJob, *args) }

    it 'calls Mutex.synchronize before performing the job' do
      expect(Resque::Plugins::Serializer::Mutex).to receive(:synchronize).
        with(key).and_return(true)

      perform_job
    end
  end

  describe 'class methods' do
    describe '.can_lock?' do
      let(:mutex) { Resque::Plugins::Serializer::Mutex.new(key) }
      let(:key)   { SerializedJob.send(:key, *args) }
      let(:args)  { ['args'] }

      subject(:can_lock?) { SerializedJob.send(:can_lock?, args) }

      context 'when a lock already exists' do
        before { mutex.lock }

        it 'returns false' do
          expect(can_lock?).to eq(false)
        end
      end

      context 'when a lock does not already exist' do
        it 'returns true' do
          expect(can_lock?).to eq(true)
        end
      end
    end

    describe '.key' do
      let(:args) { %w(arg1 arg2) }

      subject(:key) { SerializedJob.send(:key, *args) }

      it 'returns a string with the job class and arguments' do
        expect(key).to eq('serialized_job:arg1,arg2')
      end
    end
  end
end
