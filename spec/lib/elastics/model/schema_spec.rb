require 'spec_helper'

describe Elastics::Model::Schema do
  let(:model) { Class.new.tap { |x| x.extend described_class } }

  describe '#elastics_type_name' do
    subject { model.elastics_type_name }

    context 'when type was manually set' do
      before { model.elastics_type_name = :test }
      it { should be :test }
    end

    context 'when class name does not include modules' do
      before { expect(model).to receive(:name) { 'Test' } }
      it { should eq 'test' }
    end

    context 'when class name includes modules' do
      before { expect(model).to receive(:name) { 'Module::Other::Index' } }
      it { should eq 'index' }
    end
  end
end
