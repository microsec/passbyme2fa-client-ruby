require 'bundler/setup'
require 'minitest/autorun'
require 'passbyme2fa-client'
require 'webmock/minitest'

WebMock.disable_net_connect!(allow_localhost: true)

class SendMessageTest < Minitest::Unit::TestCase

  def setup
    pem_file = File.read(File.expand_path("../auth.pem", __FILE__))
    @pbm = PassByME2FAClient.new({
      :cert => OpenSSL::X509::Certificate.new(pem_file),
      :key => OpenSSL::PKey::RSA.new(pem_file, "123456")
    })
  end
  
  def test_missing_recipients
    assert_raises(ArgumentError) {
      @pbm.send_message({
        :availability => 300, 
        :type => PassByME2FAClient::MessageType::MESSAGE
      })
    }
  end
  
  def test_invalid_availability
    assert_raises(ArgumentError) {
      @pbm.send_message({
        :recipients => ["somebody@somewhe.re"],
        :availability => "hey", 
        :type => PassByME2FAClient::MessageType::MESSAGE
      })
    }
  end
  
  def test_invalid_type
    assert_raises(ArgumentError) {
      @pbm.send_message({
        :recipients => ["somebody@somewhe.re"],
        :availability => 300, 
        :type => "whoa"
      })
    } 
  end
  
  def test_non_420_error_code
    WebMock.stub_request(:post, "https://auth-sp.passbyme.com/frontend/messages").to_return(status: 500)
    assert_raises(HTTPError) {
      @pbm.send_message({
          :recipients => ["somebody@somewhe.re"],
          :availability => 300, 
          :type => PassByME2FAClient::MessageType::MESSAGE
        })
    }
  end
  
  def test_420_error_code_no_resp_body
    WebMock.stub_request(:post, "https://auth-sp.passbyme.com/frontend/messages").to_return(status: 420)
    assert_raises(HTTPError) {
      @pbm.send_message({
          :recipients => ["somebody@somewhe.re"],
          :availability => 300, 
          :type => PassByME2FAClient::MessageType::MESSAGE
        })
    }
  end
  
  def test_420_error_code_invalid_resp_body
    WebMock.stub_request(:post, "https://auth-sp.passbyme.com/frontend/messages").to_return(status: 420, body: "no json, sorry")
    assert_raises(JSON::ParserError) {
      @pbm.send_message({
          :recipients => ["somebody@somewhe.re"],
          :availability => 300, 
          :type => PassByME2FAClient::MessageType::MESSAGE
        })
    }
  end  
  
  def test_420_error_code
    WebMock.stub_request(:post, "https://auth-sp.passbyme.com/frontend/messages").to_return(status: 420, body: "{\"code\": 421}")
    err = assert_raises(PassByMEError) {
      @pbm.send_message({
          :recipients => ["somebody@somewhe.re"],
          :availability => 300, 
          :type => PassByME2FAClient::MessageType::MESSAGE
        })
    }
    assert_equal(421, err.response["code"])
  end 
  
  def test_no_response_body
    WebMock.stub_request(:post, "https://auth-sp.passbyme.com/frontend/messages").to_return(status: 200)
    assert_raises(HTTPError) {
      @pbm.send_message({
        :recipients => ["somebody@somewhe.re"],
        :availability => 300, 
        :type => PassByME2FAClient::MessageType::MESSAGE
      })
    }
  end 
  
  def test_response_body
    WebMock.stub_request(:post, "https://auth-sp.passbyme.com/frontend/messages")
      .to_return(status: 200,
        body: "{\"messageId\": \"YzX95zUA1et2ijQ\", \"expirationDate\" : \"2015-06-11T13:06:12.658+02:00\"," +
          "\"recipients\" : [{ \"userId\": \"pbmId1\", \"status\": \"PENDING\" }," +
            "{\"userId\": \"pbmId2\", \"status\": \"NOTIFIED\" },"+
            "{\"userId\": \"pbmId3\", \"status\": \"SEEN\" }]}")
    message_handle = @pbm.send_message({
        :recipients => ["somebody@somewhe.re"],
        :availability => 300, 
        :type => PassByME2FAClient::MessageType::MESSAGE
      })
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
  
  def test_accepts_address
    pem_file = File.read(File.expand_path("../auth.pem", __FILE__))
    @pbm = PassByME2FAClient.new({
      :cert => OpenSSL::X509::Certificate.new(pem_file),
      :key => OpenSSL::PKey::RSA.new(pem_file, "123456"),
      :address => "api.passbyme.com"
    })
    WebMock.stub_request(:post, "https://api.passbyme.com/frontend/messages").to_return(status: 500)
    assert_raises(HTTPError) {
      @pbm.send_message({
          :recipients => ["somebody@somewhe.re"],
          :availability => 300, 
          :type => PassByME2FAClient::MessageType::MESSAGE
        })
    }
  end
  
  def test_accepts_message
    pem_file = File.read(File.expand_path("../auth.pem", __FILE__))
    @pbm = PassByME2FAClient.new({
      :cert => OpenSSL::X509::Certificate.new(pem_file),
      :key => OpenSSL::PKey::RSA.new(pem_file, "123456"),
    })
    WebMock.stub_request(:post, "https://auth-sp.passbyme.com/frontend/messages")
      .with(:body => "{\"recipients\":[\"somebody@somewhe.re\"],\"subject\":null,\"body\":\"Test message.\",\"availability\":300,\"type\":\"message\",\"callbackUrl\":null}")
      .to_return(status: 500)
    assert_raises(HTTPError) {
      @pbm.send_message({
          :recipients => ["somebody@somewhe.re"],
          :availability => 300,
          :body => "Test message.",
          :type => PassByME2FAClient::MessageType::MESSAGE
        })
    }
  end
end
