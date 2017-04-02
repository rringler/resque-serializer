require 'spec_helper'

describe Resque::Plugins::Serializer::Mutex do
  let(:redis) { Resque.redis }

  describe 'instance methods' do
    describe '#lock' do
      let(:key)     { 'key' }
      let(:options) { {} }
      let(:mutex)   { described_class.new(key, options) }

      subject(:lock) { mutex.lock }

      it 'calls redis#set with the correct arguments' do
        default_ttl = 5.minutes

        expect(redis).to receive(:set).with(
          key,
          true,
          nx: true,
          px: default_ttl.to_i * 1000
        ).and_return(true)

        lock
      end

      context 'when the lock gets set' do
        before { allow(redis).to receive(:set).and_return(true) }

        it 'returns true' do
          expect(lock).to eq(true)
        end
      end

      context 'when the lock does not get set' do
        before { allow(redis).to receive(:set).and_return(false) }

        it 'returns false' do
          expect(lock).to eq(false)
        end
      end
    end

    describe '#lock!' do
      let(:key)     { 'key' }
      let(:options) { {} }
      let(:mutex)   { described_class.new(key, options) }

      subject(:lock!) { mutex.lock! }

      it 'calls redis#set with the correct arguments' do
        default_ttl = 5.minutes

        expect(redis).to receive(:set).with(
          key,
          true,
          nx: true,
          px: default_ttl.to_i * 1000
        ).and_return(true)

        lock!
      end

      context 'when the lock gets set' do
        before { allow(redis).to receive(:set).and_return(true) }

        it 'returns true' do
          expect(lock!).to eq(true)
        end
      end

      context 'when the lock does not get set' do
        let(:error) { described_class::LockFailed }

        before { allow(redis).to receive(:set).and_raise(error) }

        it 'raises a Mutex::LockFailed error' do
          expect { lock! }.to raise_error(error)
        end
      end
    end

    describe '#unlock' do
      let(:key)   { 'key' }
      let(:mutex) { described_class.new(key) }

      subject(:unlock) { mutex.unlock }

      it 'calls redis#del with its key' do
        expect(redis).to receive(:del).with(key)
        unlock
      end

      it 'returns true' do
        expect(unlock).to eq(true)
      end
    end
  end
end
