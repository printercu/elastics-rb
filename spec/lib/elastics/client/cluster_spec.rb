require 'spec_helper'

describe Elastics::Client do
  let(:client) { described_class.new(config) }
  let(:config) { {
    host: hosts,
    resurrect_timeout: resurrect_timeout,
  } }
  let(:hosts) { [:one, :two, :three] }
  let(:resurrect_timeout) { 5 }

  describe '#next_cluster_host' do
    subject { -> { client.send(:next_cluster_host) } }
    context 'when @hosts contains one element' do
      let(:hosts) { [:one] }

      it 'returns this host on each call' do
        expect(6.times.map { subject.call }).to eq([:one] * 6)
      end
    end

    context 'when @hosts contains multiple elements' do
      it 'returns host using round-robbin' do
        expect(6.times.map { subject.call }).to eq(hosts.cycle.take(6))
      end

      context 'and one host is dead' do
        before { client.send(:add_dead_host, :one, resurrect_at) }
        let(:resurrect_at) {}

        it 'returns other hosts using round-robbin' do
          expect(6.times.map { subject.call }).to eq((hosts - [:one]).cycle.take(6))
        end

        context 'but should be resurrected' do
          let(:resurrect_at) { 0 }

          it 'resurrects this host' do
            expect(6.times.map { subject.call }).to eq(hosts.cycle.take(7).drop(1))
          end
        end
      end

      context 'and all hosts are dead' do
        before { hosts.each { |host| client.send(:add_dead_host, host) } }
        it { should raise_error(Elastics::Client::Cluster::NoAliveHosts) }
      end
    end
  end

  describe '#resurrect_cluster' do
    subject { -> { client.send(:resurrect_cluster) } }
    context 'when multiple hosts are blocked' do
      before { hosts.each { |host| client.send(:add_dead_host, host) } }

      it { should_not change { client.instance_variable_get(:@hosts) }.from([]) }

      context 'and can be resurrected' do
        before { expect(Time).to receive(:now).and_return(resurrect_timeout.seconds.from_now) }
        it { should change { client.instance_variable_get(:@hosts) }.from([]).to(hosts) }
      end
    end
  end

  describe '#http_request' do
    subject { -> { client.send :http_request, :method, '/path', :query, :body } }

    context 'when all hosts are alive' do
      it 'uses hosts using round-robbin' do
        hosts.cycle.take(6).each do |host|
          expect(client.client).to receive(:request).
            with(:method, "http://#{host}/path", :query, :body, Elastics::Client::HEADERS)
          subject.call
        end
      end
    end

    context 'when one host is unreachable' do
      before do
        expect(client.client).to receive(:request).
          with(:method, "http://one/path", :query, :body, Elastics::Client::HEADERS) do
          raise Timeout::Error
        end
      end

      it 'uses hosts using round-robbin' do
        (hosts - [:one]).cycle.take(6).each do |host|
          expect(client.client).to receive(:request).
            with(:method, "http://#{host}/path", :query, :body, Elastics::Client::HEADERS)
        end
        6.times { subject.call }
      end
    end

    context 'when all hosts are unreachable' do
      before do
        hosts.each do |host|
          expect(client.client).to receive(:request).
            with(:method, "http://#{host}/path", :query, :body, Elastics::Client::HEADERS) do
            raise Timeout::Error
          end
        end
      end

      it { should raise_error(Elastics::Client::Cluster::NoAliveHosts) }
    end
  end
end
