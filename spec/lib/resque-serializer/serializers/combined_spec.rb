require 'spec_helper'

class JobSerializedByCombined
  extend Resque::Plugins::Serializer

  @queue = :default

  serialize :combined

  # before_enqueue: ✓
  #        enqueue: |
  #  after_enqueue: |
  # before_dequeue: |
  #        dequeue: |
  #  after_dequeue: |
  # before_perform: |
  #        perform: |
  #  after_perform: ✗

  def self.perform(*args); end
end

RSpec.describe JobSerializedByCombined do
  let(:args) { %w(arg1 arg2) }

  before do
    ResqueSpec.reset!
    Resque.redis.redis.flushall
  end

  describe 'before enqueuing the job' do
    let(:mutex) { described_class.mutex(args) }

    subject(:enqueue_job) { Resque.enqueue(described_class, *args) }

    context 'when a lock for the job exists' do
      before { mutex.lock! }

      it 'does not enqueue the job' do
        expect { enqueue_job }.to_not change {
          ResqueSpec.queue_for(described_class).size
        }.from(0)
      end

      it 'does not change the mutex' do
        expect { enqueue_job }.to_not change {
          mutex.locked?
        }.from(true)
      end
    end

    context 'when a lock for the job does not exist' do
      before { mutex.unlock }

      it 'enqueues the job' do
        expect { enqueue_job }.to change {
          ResqueSpec.queue_for(described_class).size
        }.from(0).to(1)
      end

      it 'locks the mutex' do
        expect { enqueue_job }.to change {
          mutex.locked?
        }.from(false).to(true)
      end
    end
  end

  describe 'after performing the job' do
    let(:mutex) { described_class.mutex(args) }

    before do
      # Note: this locks the mutex on the :before_enqueue_* hook
      Resque.enqueue(described_class, *args)
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
