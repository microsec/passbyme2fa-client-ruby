require 'bundler/setup'
require 'minitest/autorun'
require 'passbyme2fa-client'
require 'webmock/minitest'

WebMock.disable_net_connect!(allow_localhost: true)

class TrackMessageTest < Minitest::Unit::TestCase
  def setup
    pem_file = File.read(File.expand_path("../auth.pem", __FILE__))
    @pbm = PassByME2FAClient.new({
      :cert => OpenSSL::X509::Certificate.new(pem_file),
      :key => OpenSSL::PKey::RSA.new(pem_file, "123456")
    })
  end

  def test_missing_message_id
    assert_raises(ArgumentError) {
      @pbm.track_message({
      })
    }
    assert_raises(ArgumentError) {
      @pbm.track_message("")
    }
    assert_raises(ArgumentError) {
      @pbm.track_message(nil)
    }
    assert_raises(ArgumentError) {
      @pbm.track_message({messageId: nil})
    }
    assert_raises(ArgumentError) {
      @pbm.track_message({messageId: ""})
    }
  end
  
  def test_message_contents
    WebMock.stub_request(:get, "https://auth-sp.passbyme.com/frontend/messages/YzX95zUA1et2ijQ")
      .to_return(status: 200,
        body: "{\"messageId\": \"YzX95zUA1et2ijQ\", \"expirationDate\" : \"2015-06-11T13:06:12.658+02:00\"," +
          "\"recipients\" : [{ \"userId\": \"pbmId1\", \"status\": \"PENDING\" }," +
            "{\"userId\": \"pbmId2\", \"status\": \"NOTIFIED\" },"+
            "{\"userId\": \"pbmId3\", \"status\": \"SEEN\" }]}")
    message_handle = @pbm.track_message(
        "YzX95zUA1et2ijQ"
      )
    assert_equal("YzX95zUA1et2ijQ", message_handle.message_id)
    assert_equal(Time.parse("2015-06-11T13:06:12.658+02:00"), message_handle.expiration_date)
    assert_equal(3, message_handle.recipient_statuses.length)
    assert_equal("pbmId1", message_handle.recipient_statuses[0].user_id)
    assert_equal(PassByME2FAClient::MessageStatus::PENDING, message_handle.recipient_statuses[0].status)
    assert_equal("pbmId2", message_handle.recipient_statuses[1].user_id)
    assert_equal(PassByME2FAClient::MessageStatus::NOTIFIED, message_handle.recipient_statuses[1].status)
    assert_equal("pbmId3", message_handle.recipient_statuses[2].user_id)
    assert_equal(PassByME2FAClient::MessageStatus::SEEN, message_handle.recipient_statuses[2].status)
  end
  
  def test_message_handle_refresh
    WebMock.stub_request(:post, "https://auth-sp.passbyme.com/frontend/messages")
      .to_return(status: 200,
        body: "{\"messageId\": \"YzX95zUA1et2ijQ\", \"expirationDate\" : \"2015-06-11T13:06:12.658+02:00\"," +
          "\"recipients\" : [{ \"userId\": \"pbmId1\", \"status\": \"PENDING\" }]}")
    WebMock.stub_request(:get, "https://auth-sp.passbyme.com/frontend/messages/YzX95zUA1et2ijQ")
      .to_return(status: 200,
        body: "{\"messageId\": \"YzX95zUA1et2ijQ\", \"expirationDate\" : \"2015-06-11T13:06:12.658+02:00\"," +
          "\"recipients\" : [{ \"userId\": \"pbmId1\", \"status\": \"APPROVED\" }]}")
    message_handle = @pbm.send_message({
        :recipients => ["somebody@somewhe.re"],
        :availability => 300, 
        :type => PassByME2FAClient::MessageType::MESSAGE
      })
    assert_equal("YzX95zUA1et2ijQ", message_handle.message_id)
    assert_equal(Time.parse("2015-06-11T13:06:12.658+02:00"), message_handle.expiration_date)
    assert_equal(1, message_handle.recipient_statuses.length)
    assert_equal("pbmId1", message_handle.recipient_statuses[0].user_id)
    assert_equal(PassByME2FAClient::MessageStatus::PENDING, message_handle.recipient_statuses[0].status)
    
    message_handle.refresh
    
    assert_equal(PassByME2FAClient::MessageStatus::APPROVED, message_handle.recipient_statuses[0].status)    
  end
end
