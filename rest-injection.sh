#!/bin/bash

########################################################################################
#
# Author: Hassan Bellinger
# Relevance: Momentum 4 with MD5 Digest Authentication
#
# This script is designed to demonstrate how to utilize MD5 Digest Authentication with
# Momentum 4.x (i.e.: tested against a fresh installation of Momentum 4.3).
# It demonstrates the process of calling the server to obtain the digest, retrieving and
# storing the server response, parsing the response in order to create the client request
# (with the calculated response value), and issuing the authenticated request to the server.
#
# Relevant RFCs:
#	RFC 2069: An Extension to HTTP: Digest Access Authentication
#	https://tools.ietf.org/html/rfc2617
#
#	RFC 2617: HTTP Authentication: Basic and Digest Access Authentication
#	https://tools.ietf.org/html/rfc2617
#
# Further reading:
#	Code Project: Digest Calculator
#	https://www.codeproject.com/Articles/30403/Digest-Calculator
#
#	Wikipedia: Digest access authentication
#	https://en.wikipedia.org/wiki/Digest_access_authentication
#
# This script is provided with no warranty nor a gaurantee of any kind.
#
########################################################################################

########################################################################################
# User Settings
########################################################################################

# Define the base URI and the API endpoint here
base_uri="{{URL_TO_MTA:2081}}"
uri_endpoint="/api/v1/transmissions"

# Define Authentication Here
username="{{username}}"
password="{{password}}"

# Define Message Parameters Here
campaign_id="{{campaign_id}}"
binding="{{binding}}"

subject="Momentum 4 Test Message"
return_path="{{return_path_address}}"

from_address="{{from_address}}"
from_name="{{from_friendly}}"

recipient_address="{{recipient_address}}"
recipient_name="{{recipient_friendly}}"

# Miscellaneous
client_name="{{witty_client_name}}"

########################################################################################
# No User-Definable Settings Below this Line
########################################################################################

user_agent=$(echo "$client_name/$(curl --version | head -n1)")
request_method="POST"

echo ""
echo "-------------------------------------"
echo "Querying for Client Digest"
echo "-------------------------------------"
echo ""

# Make a request to the remote in order to retrieve Digest parameters.
no_auth_request=$(curl -H "User-Agent: $user_agent" -H "Connection: keep-alive" -sSL -D - $base_uri -o /dev/null)

# echo $no_auth_request

no_auth_response=$(echo "$no_auth_request" | grep "WWW-Authenticate")

echo "Response:"
printf "\t$no_auth_response"
echo ""

# Parse out Digest parameters

realm=$(echo "$no_auth_response" | grep -oE 'realm="[a-zA-Z0-9]{0,255}"' | sed -e 's|realm=||' | sed -e 's|"||g')
nonce=$(echo "$no_auth_response" | grep -oE 'nonce="[a-zA-Z0-9]{0,255}"' | sed -e 's|nonce=||' | sed -e 's|"||g')
qop=$(echo "$no_auth_response" | grep -oE 'qop="[a-zA-Z0-9]{0,255}"' | sed -e 's|qop=||' | sed -e 's|"||g')
algorithm=$(echo "$no_auth_response" | grep -oE 'algorithm="[a-zA-Z0-9]{0,255}"' | sed -e 's|algorithm=||' | sed -e 's|"||g')
charset=$(echo "$no_auth_response" | grep -oE 'charset=[a-zA-Z0-9-]{0,255}' | sed -e 's|charset=||')

echo ""
echo "-------------------------------------"
echo "Parsed Parameters: "
echo "-------------------------------------"
echo ""
echo "Realm:		$realm"
echo "Nonce:		$nonce"
echo "QOP:		$qop"
echo "Algorithm:	$algorithm"
echo "Charset:	$charset"

# The "response" value is calculated in three steps, as follows. Where values are combined, they are delimited by colons.
#	1. The MD5 hash of the combined username, authentication realm and password is calculated. The result is referred to as HA1.
#	2. The MD5 hash of the combined method and digest URI is calculated, e.g. of "GET" and "/dir/index.html". The result is referred to as HA2.
#	3. The MD5 hash of the combined HA1 result, server nonce (nonce), request counter (nc), client nonce (cnonce), quality of protection code (qop) and HA2 result is calculated. The result is the "response" value provided by the client.
#
# - https://en.wikipedia.org/w/index.php?title=Digest_access_authentication&oldid=922268473#Example_with_explanation

echo ""
echo "-------------------------------------"
echo "Hashing Parameters:"
echo "-------------------------------------"
echo ""

HA1=$(printf "$username:$realm:$password" | md5sum | awk '{print $1}')
HA2=$(printf "$request_method:$uri_endpoint" | md5sum | awk '{print $1}')

echo "A1:	$HA1"
echo "A2:	$HA2"

echo ""
echo "-------------------------------------"
echo ""

# nonce Count?
# The hexadecimal count of the number of requests (including the current request)
# that the client has sent with the nonce value in this request.
# This must be specified if a qop directive is sent. This must not be specified if the server did not send
# a qop directive in the WWW-Authenticate response header.

# In the case of this script, the nonce will be randomly generated every instance.
# Accordingly, supply "00000001".
nc="00000001"

# Client Nonce
# An opaque quoted string value provided by the client and used by client and server to avoid chosen
# plaintext attacks, to provide mutual authentication, and to provide some message integrity protection.
# This must be specified if a qop directive is sent. This must not be specified if the server did not send
# a qop directive in the WWW-Authenticate response header.
# ------------------------------------------------------------------------
# In the case of this script, one will be randomly generated every time.
# Accordingly, supply a random value. In this case, *roughly* mimic the behavior of digest.c from curl:
# Generate 32 random hex chars, 32 bytes + 1 zero termination
# Reference: https://github.com/curl/curl/blob/master/lib/vauth/digest.c
cnonce=$(printf "%32d" $(date +%s) | base64)

# Opaque
# This is a string of data specified by the server in the WWW-Authenticate response header and should
# be used here unchanged with URIs in the same protection space. It is recommended that this string be
# base64 or hexadecimal data.
# ------------------------------------------------------------------------
# Momentum 4 does not return an Opaque



# Build the full client response to send to the server.

echo "Response (Unhashed):	$HA1:$nonce:$nc:$cnonce:$qop:$HA2"

full_response=$(printf "$HA1:$nonce:$nc:$cnonce:$qop:$HA2" | md5sum | awk '{print $1}')

echo "Response (Hashed):	$full_response"

echo ""
echo "-------------------------------------"
echo ""

echo "Making the request to $base_uri$uri_endpoint"

echo ""
echo "-------------------------------------"
echo ""

# Make the request.
curl --verbose \
  --request $request_method \
  --url "$base_uri$uri_endpoint" \
  --header "Authorization: Digest username=\"$username\", realm=\"$realm\", nonce=\"$nonce\", uri=\"$uri_endpoint\", cnonce=\"$cnonce\", nc=$nc, qop=$qop, response=\"$full_response\", algorithm=\"$algorithm\"" \
  --header "Host: " $(echo $uri_endpoint | sed -e "s|http://||" | sed -e "s|https://||") \
  --header "User-Agent: $user_agent" \
  --header "Accept: */*" \
  --header "Content-Type: application/json" \
  --header "Connection: keep-alive" \
  --header "X-MSYS-Customer: 1" \
  --header "Cache-Control: no-cache" \
  --data '{
  "campaign_id": "'"$campaign_id"'",
  "return_path": "'"$return_path"'",
  "recipients":[
    {
      "address": {
        "email":"'"$recipient_address"'",
        "name": "'"$recipient_name"'"
      }
    }
  ],
  "content":{
    "from": {
      "name": "'"$from_name"'",
      "email": "'"$from_address"'"
    },
    "subject": "'"$subject"'",
    "headers": {
      "X-Binding": "'"$binding"'"
      , "X-Mailer": "'"$client_name"'"
    },
    "html": "<p>Hello there!</p><p>This is a test email to make sure that email injection works.</p>Thank you for your participation.</p>",
    "text": "Hello there!\r\n\r\nThis is a test email to verify that email injection works.\r\n\r\nThank you for your participation."
  }
}'