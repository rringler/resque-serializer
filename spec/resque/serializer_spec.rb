require 'spec_helper'

RSpec.describe Resque::Serializer do
  it 'has a version number' do
    expect(Resque::Serializer::VERSION).not_to be nil
  end

  it 'does something useful' do
    expect(false).to eq(true)
  end
end
