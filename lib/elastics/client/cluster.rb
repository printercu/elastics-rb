require 'timeout'
require 'thread'
require 'thread_safe'

module Elastics
  class Client
    module Cluster
      class NoAliveHosts < Error; end

      def discover_cluster
        # `nothing` allows not to fetch all unnecessary data
        discovered = request(index: '_nodes', type: '_all', id: 'nothing')['nodes'].
          map { |id, node|
            match = node['http_address'].match(/inet\[.*?\/([\da-f.:]+)/i)
            match && match[1]
          }.compact
        @cluster_mutex.synchronize do
          @hosts.clear.concat(discovered - @dead_hosts.keys)
        end
      end

      private
        def initialize_cluster(defaults)
          @hosts = ThreadSafe::Array.new defaults[:host]
          @dead_hosts = ThreadSafe::Hash.new
          @connect_timeout = defaults[:connect_timeout] || 10
          @resurrect_timeout = defaults[:resurrect_timeout] || 60
          @current_host_n = 0
          @cluster_mutex = Mutex.new
          discover_cluster if defaults[:discover]
        end

        def http_request(method, path, query, body, params = nil)
          host = next_cluster_host
          Timeout.timeout(@connect_timeout) do
            super(method, path, query, body, params, host)
          end
        rescue Timeout::Error, HTTPClient::ConnectTimeoutError
          add_dead_host(host)
          retry
        end

        # Very simple implementation. It may skip some hosts on current cycle
        # when other is marked as dead. This should not be a problem.
        # TODO: check Enumerable#cycle for thread-safety and use it if possible
        def next_cluster_host
          if @resurrect_at
            time = Time.now.to_i
            resurrect_cluster(time) if @resurrect_at <= time
          end
          host_n = @current_host_n
          loop do
            host = @hosts[host_n]
            if !host
              raise NoAliveHosts if host_n == 0
              host_n = 0
            else
              @current_host_n = host_n + 1
              return host
            end
          end
        end

        def resurrect_cluster(time = Time.now.to_i)
          @cluster_mutex.synchronize do
            @dead_hosts.delete_if do |host, resurrect_at|
              # skip the rest because values are sorted
              if time < resurrect_at
                @resurrect_at = resurrect_at
                break
              end
              @hosts << host
            end
          end
        end

        def add_dead_host(host, resurrect_at = nil)
          resurrect_at ||= Time.now.to_i + @resurrect_timeout
          @hosts.delete(host)
          @dead_hosts[host] = resurrect_at
          @resurrect_at ||= resurrect_at
        end
    end
  end
end
