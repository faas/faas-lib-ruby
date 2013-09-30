require 'faraday'
require 'multi_json'

class Faas

  SESSION_COOKIE_NAME = 'faas_cookie'.freeze


  # Faas.config do |config|
  #   config.api_key = ENV['FAAS_API_KEY']
  #   config.api_secret = ENV['FAAS_API_SECRET']
  # end
  class Config
    attr_accessor :api_key, :api_secret, :cookie_signing_secret
  end
  def config
    @config ||= Config.new # TODO: thread safety?
    if block_given?
      yield(@config)
    else
      @config
    end
  end


  class << self

    def method_missing(symbol, *args, &block)
      if @faas.respond_to?(symbol)
        @faas.send(symbol, *args, &block)
      else
        super
      end
    end

  end

  def current_user(request)
    cookie = request.cookies[SESSION_COOKIE_NAME]
    cookie && !cookie.empty? && validate_cookie(cookie)
  end


  private

  def cookie_signing_secret
    unless @cookie_signing_secret_is_set
      # TODO: Race condition / thread safety.
      @cookie_signing_secret ||=
        begin
          if config.cookie_signing_secret
            config.cookie_signing_secret
          elsif config.api_key && config.api_secret
            params = {
              api_key: config.api_key,
              # api_secret: config.api_secret,
              app_secret: config.api_secret,
            }
            conn = Faraday.new('https://api-beta.faas.io/')
            response = conn.post('bouncer/getCookieSharedSecret') do |request|
              request.headers[:content_type] = 'application/json'
              request.body = MultiJson.dump(params)
            end
            response_json = MultiJson.load(response.body)
            response_json['data'] && response_json['data']['cookie_shared_secret']
          else
            nil
          end
        end
      @cookie_signing_secret_is_set = true
    end
    @cookie_signing_secret
  end

  def validate_cookie(cookie)
    obj = nil
    val_sig = cookie[0,3] == 's:{' ? cookie[2..-1] : nil
    val, dot, sig = val_sig.rpartition('.') if val_sig
    if val && !val.empty?
      if cookie_signing_secret
        compare_sig = compute_signature(val)
        if compare_sig == sig
          trusted_val = val
        end
      else
        raise "Unable to retrieve cookie signing secret: api_key is #{config.api_key && '' || 'NOT '}set, api_secret is #{config.api_secret && '' || 'NOT '}set."
      # else # validateSignedCookie API - BAD :(
      #   params = {
      #     api_key: API_KEY,
      #     signed_cookie: CGI.escape(cookie),
      #   }
      #   conn = Faraday.new('https://api-beta.faas.io/')
      #   response = conn.post('bouncer/validateSignedCookie') do |request|
      #     request.headers[:content_type] = 'application/json'
      #     request.body = MultiJson.dump(params)
      #   end
      #   response_json = MultiJson.load(response.body)
      #   if response_json['result']
      #     trusted_val = val
      #   end
      end
      if trusted_val
        obj = User.new(MultiJson.load(trusted_val)) # Require dependency
      end
    end
    obj
  end

  def compute_signature(val)
    key = cookie_signing_secret
    if key
      @digest ||= OpenSSL::Digest::Digest.new('sha256') # Dependencies?
      sig = OpenSSL::HMAC.digest(@digest, key, val)
      sig = Base64.encode64(sig).sub(/=*\s*$/,'')
      sig
    end
  end


  class User

    def initialize(hash=nil)
      @hash = hash || {}
    end

    def method_missing(symbol, *args)
      key = symbol.to_s
      if args.empty? && @hash.has_key?(symbol.to_s)
        @hash[symbol.to_s]
      else
        super
      end
    end

  end


  @faas = new

end
