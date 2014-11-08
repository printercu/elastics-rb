require 'httpclient'

module Elastics
  class Client
    HEADERS = {'Content-Type' => 'application/json'}

    autoload :Cluster, 'elastics/client/cluster'

    require 'elastics/client/bulk'
    include Bulk

    attr_writer :index, :type
    attr_reader :client

    def initialize(defaults = {})
      if defaults[:host].is_a?(Array)
        extend Cluster
        initialize_cluster(defaults)
      else
        @host = defaults[:host] || '127.0.0.1:9200'
      end
      @index  = defaults[:index]
      @type   = defaults[:type]
      @client = HTTPClient.new
    end

    def debug!(dev = STDOUT)
      @client.debug_dev = dev
    end

    def debug_off!
      @client.debug_dev = nil
    end

    def set_index(index, type = nil)
      @index = index || nil
      @type  = type  || nil
    end

    def request_path(params)
      str = ""
      if index = params[:index] || @index
        str << "/#{index}"
        type = params[:type] || @type
        str << "/#{type}" if type
      end
      path = params[:id]
      str << "/#{path}" if path
      str
    end

    def request(params = {})
      method = params[:method] || :get
      body = params[:body]
      body = body.to_json if body && !body.is_a?(String)
      res = http_request(method, request_path(params), params[:query], body, params)
      status = res.status
      return JSON.parse(res.body) if 300 > status
      result = JSON.parse(res.body) rescue nil
      err_msg = "#{res.reason}: #{result && result['error'] || '-'}"
      # NotFound is raised only for valid responses from ElasticSearch
      raise NotFound, err_msg if 404 == status && result
      raise Error, err_msg
    end

    # shortcuts
    [:put, :post].each do |method|
      define_method(method) do |params|
        params[:method] = method
        request params
      end
    end

    def delete!(params)
      params = {id: params} unless params.is_a?(Hash)
      params[:method] = :delete
      request params
    end

    def delete(params)
      delete!(params)
    rescue NotFound
    end

    def get!(params)
      params = {id: params} unless params.is_a?(Hash)
      params[:method] = :get
      request(params)
    end

    def get(params)
      get!(params)
    rescue NotFound
    end

    def set(id, data)
      request(id: id, body: data, method: :put)
    end

    def put_mapping(params)
      params[:id] = :_mapping
      params[:method] = :put
      request(params)
    end

    def search(params)
      params[:id] = :_search
      params[:method] = :post
      request(params)
    end

    def index(params)
      params[:id] ? put(params) : post(params)
    end

    def index_exists?(index)
      !!get(index: index, type: nil, id: :_mapping)
    end

    def refresh(index = nil)
      request(method: :post, index: index, type: nil, id: :_refresh)
    end

    private
      # Endpoint for low-level request. For easy host highjacking & instrumentation.
      # Params are not used directly but kept for instrumentation purpose.
      # You probably don't want to use this method directly.
      def http_request(method, path, query, body, params = nil, host = @host)
        uri = "http://#{host}#{path}"
        @client.request(method, uri, query, body, HEADERS)
      end
  end
end
