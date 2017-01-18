require 'net/http'
require 'openssl'
require 'json'

require_relative 'passbyme2fa-client/http_error'
require_relative 'passbyme2fa-client/passbyme_error'
require_relative 'passbyme2fa-client/session_info'

class PassByME2FAClient

  VERSION = "1.0.1"

  module MessageType
    AUTHORIZATION = "authorization"
    MESSAGE       = "message"
    ESIGN         = "esign"
  end

  module MessageStatus
    PENDING        = "PENDING"
    NOTIFIED       = "NOTIFIED"
    DOWNLOADED     = "DOWNLOADED"
    SEEN           = "SEEN"
    NOT_SEEN       = "NOT_SEEN"
    NOT_NOTIFIED   = "NOT_NOTIFIED"
    NOT_DOWNLOADED = "NOT_DOWNLOADED"
    NO_DEVICE      = "NO_DEVICE"
    FAILED         = "FAILED"
    DISABLED       = "DISABLED"
    CANCELLED      = "CANCELLED"
    APPROVED       = "APPROVED"
    DENIED         = "DENIED"
  end

  def initialize(http_options)
    if !http_options.include? :key or !http_options.include? :cert
      raise ArgumentError.new("SSL key or certificate is missing!")
    end
    url = (http_options.include?(:address) ? http_options[:address] : "auth-sp.passbyme.com")
    http_options.delete :address
    @http = Net::HTTP.start(url, http_options.merge({
      :use_ssl => true,
      :verify_mode => OpenSSL::SSL::VERIFY_PEER,
      :ca_file => File.expand_path("../passbyme2fa-client/truststore.pem", __FILE__),
    }))
  end

  def send_message(params)
    recipients = params[:recipients]
    subject = params[:subject]
    body = params[:body]
    availability = params[:availability]
    type = params[:type]
    callbackUrl = params[:callbackUrl]

    if recipients.nil? or recipients.length == 0
      raise ArgumentError.new("Missing recipients!")
    end

    availability = availability.to_i
    if availability < 1
      raise ArgumentError.new("Availability must be an integer greater than 0.")
    end

    raise ArgumentError.new("Invalid message type #{type}.") unless MessageType.constants.index { |ct|
      MessageType.const_get(ct) == type
    }

    req = Net::HTTP::Post.new("/frontend/messages", "Content-Type" => "application/json")
    req.body = {
      :recipients => recipients,
      :subject => subject,
      :body => body,
      :availability => availability,
      :type => type,
      :callbackUrl => callbackUrl
    }.to_json

    SessionInfo.new(JSON.parse(do_https(req)), self)
  end

  def track_message(message_id)
    handle_existing_message(message_id, Net::HTTP::Get)
  end

  def cancel_message(message_id)
    handle_existing_message(message_id, Net::HTTP::Delete)
  end

  private

  def handle_existing_message(message_id, net_http_class)
    message_handle = nil
    if message_id.is_a? Hash
      message_id = message_id[:messageId]
    end
    if message_id.is_a? SessionInfo
      message_handle = message_id
      message_id = message_id.message_id
    end
    if message_id.nil? or message_id == ""
      raise ArgumentError.new("Empty message id!")
    end

    req = net_http_class.new("/frontend/messages/#{message_id}")

    json = JSON.parse(do_https(req))

    if message_handle.nil?
      message_handle = SessionInfo.new(json, self)
    else
      message_handle.re_initialize(json)
    end

    message_handle
  end

  def do_https(req)
    req.add_field("X-PBM-API-VERSION", "1")

    res = @http.request(req)
    raise HTTPError.new(res) unless res.body

    if res.code !~ /\A2..\z/
      if res.code == "420"
        raise PassByMEError.new(JSON.parse(res.body))
      else
        raise HTTPError.new(res)
      end
    end

    res.body
  end
end
