require 'bundler/setup'
require 'minitest/autorun'
require 'passbyme2fa-client'

class ConfigTest < Minitest::Unit::TestCase
  
  def test_should_miss_key
    assert_raises(ArgumentError) {
      PassByME2FAClient.new({})
    }
  end
  
  def test_should_miss_cert
    assert_raises(ArgumentError) {
      PassByME2FAClient.new({:cert => nil})
    }
  end
   
end