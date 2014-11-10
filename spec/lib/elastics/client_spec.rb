require 'spec_helper'

describe Elastics::Client do
  let(:instance) { described_class.new }
  let(:index_name) { 'elastics_test' }

  describe '#refresh!' do
    subject { instance.refresh!(index_name) }

    context 'when index exists' do
      before { instance.post(index: index_name) }
      after { instance.delete(index: index_name) }
      it { should be }
    end

    context 'when index does not exist' do
      it { expect { subject }.to raise_error(Elastics::NotFound) }
    end
  end

  describe '#refresh' do
    subject { instance.refresh(index_name) }

    context 'when index exists' do
      before { instance.post(index: index_name) }
      after { instance.delete(index: index_name) }
      it { should be }
    end

    context 'when index does not exist' do
      it { should be_nil }
    end
  end
end
