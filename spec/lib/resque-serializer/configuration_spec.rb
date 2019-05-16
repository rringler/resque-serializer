require 'spec_helper'

describe Resque::Plugins::Serializer::Configuration do
  describe 'instance methods' do
    describe '#mutex_generator' do
      let(:instance) { described_class.instance }
      let(:key)      { 'key' }

      context 'when called' do
        subject { instance.mutex_generator.call(key) }

        it 'returns an instance of the mutex' do
          expect(subject).to be_a(Resque::Plugins::Serializer::Mutex)

          expect(subject).to have_attributes(key: key)
        end
      end
    end
  end
end
