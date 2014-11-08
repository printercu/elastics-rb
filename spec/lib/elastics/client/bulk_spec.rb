require 'spec_helper'

describe Elastics::Client::Bulk::Builder do
  let(:instance) { described_class.new }

  describe '#add_action' do
    context 'if params is hash' do
      it 'add param as is' do
        expect { instance.add_action :action, {test: 1} }.
          to change { instance.actions }.
          from([]).
          to([{action: {test: 1}}])
      end
    end

    context 'if params is not a hash' do
      it 'treats params as id' do
        expect { instance.add_action :action, 1 }.
          to change { instance.actions }.
          from([]).
          to([{action: {_id: 1}}])
      end
    end

    it 'adds data as is' do
      expect { instance.add_action :action, {test: 1}, :data }.
        to change { instance.actions }.
        from([]).
        to([{action: {test: 1}}, :data])
    end
  end
end

describe Elastics::Client do
  let(:client) { Elastics::Client.new }

  describe '#bulk' do
    context 'when no actions added' do
      it 'should not invoke #request' do
        expect(client).to_not receive(:request)
        client.bulk {}
      end
    end

    context 'when some actions added' do
      it 'should invoke request' do
        expect(client).to receive(:request).with(
          id:     :_bulk,
          method: :post,
          index:  :index1,
          body:   "{\"delete\":{\"_id\":1}}\n",
        )
        client.bulk(index: :index1) { |x| x.delete 1 }
      end
    end
  end
end
