require 'spec_helper'

class JobSerializedByQueue
  extend Resque::Plugins::Serializer

  @queue = :default

  serialize :queue

  # before_enqueue: ✓
  #        enqueue: |
  #  after_enqueue: |
  # before_dequeue: |
  #        dequeue: |
  #  after_dequeue: ✗
  # before_perform:
  #        perform:
  #  after_perform:

  def self.perform(*args); end
end

RSpec.describe JobSerializedByQueue do
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

  describe 'after dequeuing the job' do
    let(:mutex) { described_class.mutex(args) }

    subject(:dequeue_job) { Resque.dequeue(described_class, *args) }

    before { mutex.lock! }

    it 'unlocks the mutex' do
      expect { dequeue_job }.to change {
        mutex.locked?
      }.from(true).to(false)
    end
  end
end
