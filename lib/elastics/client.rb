require 'httpclient'

module Elastics
  class Client
    HEADERS = {'Content-Type' => 'application/json'}

    attr_writer :index, :type
    attr_reader :client

    def initialize(defaults = {})
      @host = defaults[:host] || '127.0.0.1'
      @port = defaults[:port] || 9200
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

    def uri(params)
      str = "http://#{@host}:#{@port}"
      if index = params[:index]  || @index
        str += "/#{index}"
        type  = params[:type]   || @type
        str += "/#{type}" if type
      end
      path = params[:id]
      str += "/#{path}" if path
      str
    end

    def request(params)
      http_method = params[:method] || :get
      body = params[:data].try!(:to_json)
      res = @client.request(http_method, uri(params), params[:query], body, HEADERS)
      status = res.status
      return JSON.parse(res.body) if 300 > status
      raise NotFound if 404 == status
      raise Error.new(res.reason)
    end

    # shortcuts
    [:put, :post, :delete].each do |method|
      define_method(method) do |params|
        params[:method] = method
        request params
      end
    end

    def get(params)
      params = {id: params} unless params.is_a?(Hash)
      params[:method] = :get
      request(params)
    end

    def set(id, data)
      request(id: id, data: data, method: :put)
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
      get(index: index, type: nil, id: :_mapping)
      true
    rescue NotFound
      false
    end
  end
end