require 'spec_helper'

describe Resque::Plugins::Serializer::Mutex do
  let(:redis) { Resque.redis }

  describe 'class methods' do
    describe '.synchronize' do
      let(:key)      { 'key' }
      let(:instance) { described_class.new(key) }

      subject(:synchronize) { described_class.synchronize(key) { true } }

      before do
        allow(described_class).to receive(:new).and_return(instance)
      end

      it 'calls #synchronize on a new instance of the class' do
        expect(instance).to receive(:synchronize)

        synchronize
      end
    end
  end

  describe 'instance methods' do
    describe '#lock' do
      let(:key)   { 'key' }
      let(:mutex) { described_class.new(key, options) }

      subject(:lock) { mutex.lock }

      context 'when options include a ttl' do
        let(:options) { { ttl: ttl } }
        let(:ttl)     { 1.minute }

        it 'calls redis#set with the correct arguments' do
          expect(redis).to receive(:set).with(
            key,
            nx: true,
            px: ttl.to_i * 1000
          ).and_return(true)

          lock
        end
      end

      context 'when options do not include a ttl' do
        let(:options) { {} }

        it 'calls redis#set with the correct arguments' do
          expect(redis).to receive(:set).with(
            key,
            nx: true,
            px: 5.minutes.to_i * 1000
          ).and_return(true)

          lock
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
    end

    describe '#synchronize' do
      let(:key)   { 'key' }
      let(:mutex) { described_class.new(key) }
      let(:block) { double }

      subject(:synchronize) { mutex.synchronize { block.call } }

      before do
        allow(mutex).to receive(:lock).and_return(true)
        allow(mutex).to receive(:unlock).and_return(true)
      end

      context 'when the block completes successfully' do
        before { allow(block).to receive(:call).and_return(true) }

        it 'calls #lock, block#call, and #unlock in order' do
          expect(mutex).to receive(:lock).and_return(true).ordered
          expect(block).to receive(:call).ordered
          expect(mutex).to receive(:unlock).and_return(true).ordered

          synchronize
        end
      end

      context 'when the block raises an exception' do
        let(:error) { RuntimeError }

        before { allow(block).to receive(:call).and_raise(error) }

        it 'still calls #lock, block#call, and #unlock' do
          expect { synchronize }.to raise_error(error)

          expect(mutex).to have_received(:lock).ordered
          expect(block).to have_received(:call).ordered
          expect(mutex).to have_received(:unlock).ordered
        end
      end
    end
  end
end
