require 'spec_helper'

describe Elastics::AutoRefresh do
  let(:client) { Elastics::Client.new }
  let(:response) { OpenStruct.new(body: '{}', status: 200) }
  before { allow(client).to receive(:http_request) { response } }

  describe '.enable!' do
    around { |ex| described_class.enable! { ex.run } }

    context 'for GET & search request' do
      it 'doesn`t invoke refresh' do
        expect(client).to_not receive(:refresh)
        client.get 1
        client.search query: {match_all: {}}
        client.request method: :get, id: :_mapping
      end
    end

    context 'for POST, PUT & DELETE requests' do
      it 'invokes refresh after each request' do
        expect(client).to receive(:refresh).exactly(3).times
        client.post id: 1
        client.put_mapping type: {fields: {}}
        client.delete id: 2
      end

      it 'invokes refresh after each request, not wrapped in .disable! block' do
        expect(client).to receive(:refresh).exactly(2).times
        client.post id: 1
        described_class.disable! { client.put_mapping type: {fields: {}} }
        client.delete id: 2
      end
    end
  end
end
