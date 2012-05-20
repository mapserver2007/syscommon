require 'uri'
require 'cgi'
require 'openssl'
require 'net/http'
require 'rubygems'
require 'json'

class Auth
  TCLIPER_BASE_URL = 'http://192.168.0.103:3001/'
  TCLIPER_PATH = '/tcliper/users'
  LIVEDOOR_BASE_URL = 'http://auth.livedoor.com/'
  LIVEDOOR_PATH = {:auth_login => '/login/', :auth_rpc => '/rpc/auth'}.freeze
  LIVEDOOR_PARAM_VERSION = '1.0'
  LIVEDOOR_PARAM_PERMS = 'id' # or userhash
  LIVEDOOR_RPC_FORMAT = 'json' # or xml

  def initialize(params = {})
    @app_key = params[:app_key]
    @secret  = params[:secret]
  end

  def livedoor_login
    login_url
  end

  def livedoor_id param
    uri = auth_rpc_url param
    result = nil
    Net::HTTP.start(uri.host) do |http|
      result = JSON.parse(
        http.post(uri.path, uri.query,
          {"Content-type" => "application/x-www-form-urlencoded"}).body
      )
    end
    if result[:error].to_i == 0
      result['user']['livedoor_id']
    else
      raise
    end
  end

  def auto_signup(param = {})
    response = nil
    uri = auto_signup_url(param)
    #uri

#    query_string = uri.query.map do |key, value|
#     "#{URI.encode(key)}=#{URI.encode(value)}"
#    end.join("&")

#    uri.query
    #Net::HTTP.version_1_2
#    test_uri = URI.parse('http://localhost:3001/tcliper/user')
#    request = Net::HTTP::POST.new(test_uri.path);
#    request['content-type'] = 'application/x-www-form-urlencoded'
#
#    http = Net::HTTP.start(uri.host, uri.port)
#    res = http.request(request)


    Net::HTTP.start('localhost', 3001) do |http|
      response = http.post('/tcliper/users', 'ttt=ttt', {"Content-type" => "application/x-www-form-urlencoded"}).body
    end

    #response.body
    #uri
  end


  private
  def query(request = {})
    q = request.update(:app_key => @app_key)
    q[:v] ||= LIVEDOOR_PARAM_VERSION
    q[:t] ||= Time.new.to_i
    q[:sig] = sig q
    q.map{|k, v| "#{k}=#{v.to_s}"}.join('&')
  end

  def sig hash
    OpenSSL::HMAC::hexdigest(OpenSSL::Digest::SHA1.new, @secret,
      hash.reject{|k,v| k == :sig}.to_a.sort_by {|i| i.first.to_s}.join)
  end

  def login_url
    request = {:perms => LIVEDOOR_PARAM_PERMS}
    uri = URI.parse LIVEDOOR_BASE_URL
    uri.path = LIVEDOOR_PATH[:auth_login]
    uri.query = query(request)
    uri.to_s
  end

  def auth_rpc_url param
    request = {
      :format => LIVEDOOR_RPC_FORMAT,
      :token => param[:token],
      :v => param[:v],
      :t => param[:t]
    }
    uri = URI.parse LIVEDOOR_BASE_URL
    uri.path = LIVEDOOR_PATH[:auth_rpc]
    uri.query = query(request)
    uri
  end

  def auto_signup_url param
    request = {
      'user[login]' => param[:id],
      'user[email]' => param[:id] + '@tcliper.co.jp',
      'user[password]' => 'dummy_pw',
      'user[password_confirmation]' => 'dummy_pw',
      :authenticity_token => param[:authenticity_token],
      :commit => 'Signup'
    }
    uri = URI.parse TCLIPER_BASE_URL
    uri.path = TCLIPER_PATH
    uri.query = request.map{|k, v| "#{k}=#{CGI.escape(v.to_s)}"}.join('&')
    uri
  end

end
