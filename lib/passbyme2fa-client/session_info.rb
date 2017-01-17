require 'time'
require_relative 'json_helper'
require_relative 'recipient_status'

class SessionInfo
  include JSONHelper

  attr_reader :message_id, :expiration_date, :recipient_statuses

  def initialize(json, pbm_client)
    re_initialize(json)
    @pbm_client = pbm_client
    if !@pbm_client
      raise ArgumentError.new("PassBy[ME] client is missing.")
    end
  end

  def re_initialize(json)
    @message_id = get_json_field(json, "messageId")
    @expiration_date = Time.parse(get_json_field(json, "expirationDate"))
    @recipient_statuses = get_json_field(json, "recipients").collect { |recipient|
      RecipientStatus.new(recipient)
    }
  end

  def refresh
    @pbm_client.track_message(self)
  end

  def cancel
    @pbm_client.cancel_message(self)
  end

end
