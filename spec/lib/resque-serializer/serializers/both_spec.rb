require 'spec_helper'

class JobSerializedByBoth
  extend Resque::Plugins::Serializer

  @queue = :default

  serialize :both

  # before_enqueue: ✓
  #        enqueue: |
  #  after_enqueue: |
  # before_dequeue: | ✓
  #        dequeue: | |
  #  after_dequeue: ✗ |
  # before_perform:   |
  #        perform:   |
  #  after_perform:   ✗

  def self.perform(*args); end
end

RSpec.describe JobSerializedByBoth do
  let(:args) { %w(arg1 arg2) }

  before do
    ResqueSpec.reset!
    Resque.redis.redis.flushall
  end

  describe 'before enqueuing the job' do
    let(:mutex) { described_class.queue_mutex(args) }

    subject(:enqueue_job) { Resque.enqueue(described_class, *args) }

    context 'when a lock for the job exists' do
      before { mutex.lock! }

      it 'does not enqueue the job' do
        expect { enqueue_job }.to_not change {
          ResqueSpec.queue_for(described_class).size
        }.from(0)
      end

      it 'does not unlock the mutex' do
        expect { enqueue_job }.to_not change {
          mutex.locked?
        }.from(true)
      end
    end

    context 'when a lock for the job does not exist' do
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

  describe 'after dequeuing the job' do
    let(:mutex) { described_class.queue_mutex(args) }

    subject(:dequeue_job) { Resque.dequeue(described_class, *args) }

    before { mutex.lock! }

    it 'unlocks the mutex' do
      expect { dequeue_job }.to change {
        mutex.locked?
      }.from(true).to(false)
    end
  end

  describe 'before dequeuing the job' do
    let(:mutex) { described_class.job_mutex(args) }

    subject(:dequeue_job) { Resque.dequeue(described_class, *args) }

    it 'locks the mutex' do
      expect { dequeue_job }.to change {
        mutex.locked?
      }.from(false).to(true)
    end
  end

  describe 'after performing the job' do
    let(:mutex) { described_class.job_mutex(args) }

    before do
      Resque.enqueue(described_class, *args)
      mutex.lock!
    end

    subject(:perform_job) { ResqueSpec.perform_next(:default) }

    context 'if the job completes successfully' do
      it 'releases the lock after execution' do
        expect { perform_job }.to change {
          mutex.locked?
        }.from(true).to(false)
      end
    end

    context 'if the job raises an exception' do
      let(:error) { StandardError }

      before do
        allow(described_class).to receive(:perform).and_raise(error)
      end

      it 'still releases the lock after execution' do
        expect(mutex.locked?).to eq(true)

        expect { perform_job }.to raise_error(error)

        expect(mutex.locked?).to eq(false)
      end
    end
  end
end
