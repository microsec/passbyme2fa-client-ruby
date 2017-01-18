# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "passbyme2fa-client"

Gem::Specification.new do |spec|
  spec.name          = "passbyme2fa-client"
  spec.version       = PassByME2FAClient::VERSION
  spec.authors       = ["Microsec ltd."]
  spec.email         = ["development@passbyme.com"]

  spec.summary       = "PassBy[ME] Mobile ID Client SDK"
  spec.description   = "Messaging SDK for PassBy[ME] Mobile ID solution"
  spec.homepage      = "https://www.passbyme.com/"
  spec.license       = "MIT"

  spec.files         = Dir[
    "lib/**/*.rb",
    "lib/passbyme2fa-client/truststore.pem",
    "README.md"
  ]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "webmock"

  # This gem will work with 1.9 or greater...
  spec.required_ruby_version = '>= 1.9'
end
