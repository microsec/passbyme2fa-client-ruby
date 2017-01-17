PassBy[ME] Mobile ID client
===========================================

This library provides you with functionality to handle PassBy[ME] messages.

For further information on PassBy[ME] please visit:
[www.passbyme.com](https://www.passbyme.com) and sign up for a free account.
You can download our API documentation after login.

# Table of contents
* [Installation](#installation)
* [Usage](#usage)
	* [PassByME2FAClient](#passbyme2faclient)
	* [Handling messages](#handling-messages)
		* [Sending messages](#sending-messages)
		* [Tracking messages](#tracking-messages)
		* [Cancelling messages](#cancelling-messages)
		* [SessionInfo](#sessioninfo)
	* [Errors](#errors)
		* [HTTPError](#httperror)
		* [PassByMEError](#passbymeerror)
* [Build](#build)
* [Release History](#release-history)

# Installation
```
gem install passbyme2fa-client
```
# Usage
To use the PassBy[ME] Mobile ID SDK first you have to acquire the following:

- Account authentication PEM file and its password

You can get these after registering at
[www.passbyme.com](https://www.passbyme.com), by hitting the "Sign up for
free" button. To complete the registration you will need an Android or iOS
device with the PassBy[ME] application installed.

If you login after registration you can download the PEM from the Application
menu. You can add new applications to your registration by hitting the "New
application". The application (along with its Application Id) will appear in
the table below.

*We suggest you to read the available User Guides and API documentation before
you continue with the integration. You can download these from the
Documentation section of the administration website after login.*

## PassByME2FAClient
```ruby
require 'passbyme2fa-client'

pem_file = File.read("auth.pem")
pbm = PassByME2FAClient.new({
  :cert => OpenSSL::X509::Certificate.new(pem_file),
  :key => OpenSSL::PKey::RSA.new(pem_file, "<auth.pem password>")
})
```
The **PassByME2FAClient** constructor accepts the following parameters in a
Hash object:

- **cert**: the authentication certificate. (See:
[Net::HTTP attributes](https://ruby-doc.org/stdlib-2.4.0/libdoc/net/http/rdoc/Net/HTTP.html)
for details)
- **key**: the authentication key. (See:
[Net::HTTP attributes](https://ruby-doc.org/stdlib-2.4.0/libdoc/net/http/rdoc/Net/HTTP.html)
for details)
- **address**: The address of the PassBy[ME] service to use. This parameter is
optional. by default the SDK will connect to our test service. The PassBy[ME]
service url-s are the following:
	- *Test service*: auth-sp.passbyme.com
	- *Production service*: api.passbyme.com
- You can supply any attribute accepted by Net::HTTP
(see: https://ruby-doc.org/stdlib-2.4.0/libdoc/net/http/rdoc/Net/HTTP.html)
to influence the connection.

Throws an  [ArgumentError](https://ruby-doc.org/core-2.4.0/ArgumentError.html)
when a required parameter is missing.

## Handling Messages

### Sending messages
```ruby
session_info = pbm.send_message(
  recipients: ["test@pers.on"],
  availability: 300,
  type: PassByME2FAClient::MessageType::AUTHORIZATION,
  subject: "Test subject", body: "Test message"
)
```
The **send_message** method accepts the following parameters in a Hash object
(or as named parameters, as in the example above):
- **recipients**: An array containing the PassBy[ME] ID-s of the recipients
- **subject**: The subject of the message
- **body**: The body of the message
- **availability**: The availability of the message in seconds
- **type**: One of the following types:
    - **PassByME2FAClient::MessageType::AUTHORIZATION** - for authorization requests
    - **PassByME2FAClient::MessageType::MESSAGE** - to send a general message with
		arbitrary body
    - **PassByME2FAClient::MessageType::ESIGN** - if the message body contains an
		esign url

When successful, returns a [SessionInfo](#sessioninfo) object.

Throws an [ArgumentError](https://ruby-doc.org/core-2.4.0/ArgumentError.html)
when a required parameter is missing.
Throws an [HTTPError](#httperror) if an error in HTTP communication occurs.
**HTTPError.response** contains the HTTP response.
Throws a [PassByMEError](#passbymeerror) if a PassBy[ME] specific error occurs.
**PassByMEError.response** contains the JSON response received from the PassBy[ME]
server as a Hash object.

### Tracking messages
```ruby
session_info.refresh
```

To track messages, the most efficient way is to call **SessionInfo.refresh**.
After a successful call, the [SessionInfo](#sessionInfo) object will contain
up-to-date information about the message.

Throws an [HTTPError](#httperror) if an error in HTTP communication occurs.
Throws a [PassByMEError](#passbymeerror) if a PassBy[ME] specific error occurs.

### Cancelling messages
```ruby
session_info.cancel
```

To cancel the message, the most efficient way is to call **SessionInfo.cancel**.
After a successful call, the message will be cancelled and the
[SessionInfo](#sessionInfo) object will contain up-to-date information about the
message.

Throws an [HTTPError](#httperror) if an error in HTTP communication occurs.
Throws a [PassByMEError](#passbymeerror) if a PassBy[ME] specific error occurs.

### SessionInfo
The **SessionInfo** object describes the state of a message session. It consists
of the following readable attributes:
- **message_id**: The id of the message that can be used to reference the message
- **expiration_date**: The date and time until the message can be downloaded with
the PassBy[ME] applications
- **recipient_statuses**: An array of **RecipientStatus** objects. Each object
consist of the following fields
	- **user_id**: The PassBy[ME] ID of the user represented by this recipient object
	- **status**: The delivery status of this message for this user

Available statuses are (all constants available as **PassByME2FAClient::MessageStatus::***):
- **PENDING**: Initial status of the message.
- **NOTIFIED**: The recipient has been notified about a new message.
- **DOWNLOADED**: The recipient has downloaded the message, but has not uploaded
the evidence yet.
- **SEEN**: The recipient has seen the message and uploaded the evidence.
- **NOT_SEEN**: The recipient has not seen the message.
- **NOT_NOTIFIED**: The recipient has not received the notification.
- **NOT_DOWNLOADED**: The recipient received the notification about the message
but has not downloaded the message
- **NO_DEVICE**: The message could not be sent because the recipient had no PassBy[ME]
ready device that supports messaging.
- **FAILED**: The message could not be sent because of an error.
- **DISABLED**: The message could not be sent because the recipient is disabled.
- **CANCELLED**: The message was cancelled by the sender.
- **APPROVED**: Authentication has finished successfully.
- **DENIED**: The user has cancelled the authentication.

## Errors

### HTTPError

Denotes that the server responded with a HTTP error code. Its readable **response**
attribute contains the [Net::HTTPResponse](https://ruby-doc.org/stdlib-2.4.0/libdoc/net/http/rdoc/Net/HTTPResponse.html)
received from the server.

### PassByMEError

Denotes a PassBy[ME] specific error. See the API documentation for the possible
error codes. Its readable **response** attribute contains the JSON message
received from the server as a Hash object.

# Build

To build the gem, first we have to run our tests, which can be done typing
```
rake
```
If the tests all pass, we can create the gem using the command
```
gem build passbyme2fa-client.gemspec
```

# Release History

- 1.0.0
	- Initial release
