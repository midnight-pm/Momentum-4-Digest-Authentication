# Momentum 4 Digest Authentication

This script is designed to demonstrate how to utilize MD5 Digest Authentication with Momentum 4.x (i.e.: tested against a fresh installation of Momentum 4.3).
It demonstrates the process of calling the server to obtain the digest, retrieving and storing the server response, parsing the response in order to create the client request (with the calculated response value), and issuing the authenticated request to the server.

 Relevant RFCs:

	RFC 2069: An Extension to HTTP: Digest Access Authentication
	https://tools.ietf.org/html/rfc2617

	RFC 2617: HTTP Authentication: Basic and Digest Access Authentication
	https://tools.ietf.org/html/rfc2617

 Further reading:

	Code Project: Digest Calculator
	https://www.codeproject.com/Articles/30403/Digest-Calculator

	Wikipedia: Digest access authentication
	https://en.wikipedia.org/wiki/Digest_access_authentication

This script is provided with no warranty nor a gaurantee of any kind.