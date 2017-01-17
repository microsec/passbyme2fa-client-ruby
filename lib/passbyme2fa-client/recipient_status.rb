require_relative 'json_helper'

class RecipientStatus
  include JSONHelper

  attr_reader :user_id, :status

  def initialize(json)
    @user_id = get_json_field(json, "userId")
    @status = get_json_field(json, "status")
  end

end
