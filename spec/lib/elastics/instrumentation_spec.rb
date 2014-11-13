require 'spec_helper'

describe Elastics::Instrumentation do
  describe '.prettify_json' do
    context 'when string is json' do
      it 'parses it and yields hash into block' do
        result = described_class.prettify_json('{"a":1}') { |x| x.keys[0] }
        expect(result).to eq 'a'
      end
    end

    context 'when string is multiple jsons joined with new line (bulk request)' do
      it 'parses it into array and yields hashes into block one by one' do
        result = described_class.prettify_json("{\"a\":1}\n{\"b\":2}") do |x|
          x.keys[0]
        end
        expect(result).to eq "a\nb"
      end
    end

    context 'when string is not json' do
      it 'returns original string' do
        [
          "{\"a\":1",
          "{\"a\":1}\n{b\":2}",
          "{\"a\":1}\n{\"b\":2}\n{",
          'not json'
        ].each do |str|
          expect(described_class.prettify_json(str) { raise }).to eq(str)
        end
      end
    end
  end

  describe '.prettify_body' do
    context 'when body_prettifier is true' do
      before { described_class.body_prettifier = true }

      it 'uses JSON.pretty_generate to prettify' do
        expect(JSON).to receive(:pretty_generate).with('a' => 1).and_return(1)
        expect(JSON).to receive(:pretty_generate).with('b' => 2).and_return(2)
        expect(described_class.prettify_body("{\"a\":1}\n{\"b\":2}")).to eq "1\n2"
      end
    end
  end
end
