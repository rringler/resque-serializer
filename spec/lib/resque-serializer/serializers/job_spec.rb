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

  def self.perform(*args); end
end

RSpec.describe JobSerializedByJob do
  let(:args) { %w(arg1 arg2) }

  before do
    ResqueSpec.reset!
    Resque.redis.redis.flushall
  end

  describe 'before dequeuing the job' do
    let(:mutex) { described_class.mutex(args) }

    subject(:dequeue_job) { Resque.dequeue(described_class, *args) }

    it 'locks the mutex' do
      expect { dequeue_job }.to change {
        mutex.locked?
      }.from(false).to(true)
    end
  end

  describe 'after performing the job' do
    let(:mutex) { described_class.mutex(args) }

    before do
      Resque.enqueue(described_class, *args)
      mutex.lock!
    end

    subject(:perform_job) { ResqueSpec.perform_next(:default) }

    context 'when the job completes successfully' do
      it 'releases the lock after execution' do
        expect { perform_job }.to change {
          mutex.locked?
        }.from(true).to(false)
      end
    end

    context 'when the job raises an exception' do
      let(:error) { StandardError }

      before { allow(described_class).to receive(:perform).and_raise(error) }

      it 'still releases the lock after execution' do
        expect(mutex.locked?).to eq(true)

        expect { perform_job }.to raise_error(error)

        expect(mutex.locked?).to eq(false)
      end
    end
  end
end
