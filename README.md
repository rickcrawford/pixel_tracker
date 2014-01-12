Pixel Tracker
--------------

This pixel tracker is built on OpenResty build of NGINX.  It uses lua to generate a random
UUID for each request. Lua gives you an opportunity to do some more intelligent routing if 
you want. All responses are logged to a file called `access.log`

This project serves a couple of purposes:

1. It's a simple pixel tracker that logs all requests with the raw request data to a log file
2. It's a default lua project for OpenResty that shows you how to leverage access filters and response
filters. 

Features:
* 1px gif response (200)
* no content gif response (204)
* ability to capture post data
* redirects

Getting Started
===============

Assuming you are running this on OSX, you will need sudo access to run on port 80/443. 
This project assumes you are using the host name as the account. The best way to run this would
be using a wildcard domain `*.hostname.com`, where * is the account (a-z0-9). If you want SSL you 
would need to setup a wildcard cert. The configuration file by default is setup for `localhost`. 

For testing purposes, you will need to modify your `/etc/hosts` file to include some test domains.
In this case I have added two domains `test.localhost` and `test2.localhost` for testing.
```
##
#
# localhost is used to configure the loopback interface
# when the system is booting.  Do not change this entry.
##
127.0.0.1	localhost test.localhost test2.localhost
255.255.255.255	broadcasthost
::1             localhost
fe80::1%lo0	localhost
```

Once created, you can start NGINX as a sudo user.

```bash
sudo nginx -p /Users/rick/Documents/workspaces/opensource/pixel_tracker/
```

When you request one of the application urls, you will log the response in tab separated format.
Test a couple requests using your browser. To test post, use the following curl command:

```
curl -X POST "http://test.localhost/id_here/data" -d '{"title" : "Test", "tags" : ["foo","bar"]}' 
```


Here's an example of what data in the log will look like:

```
1389561927.133	cb9c1a5b-6910-4fb2-b457-a9c72a392d90	test	testlaptop.local	127.0.0.1	-	GET /test/uuid.json HTTP/1.1	200	test	http	test.localhost	/test/uuid.json	-	-	1	-	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.63 Safari/537.36	text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8	gzip,deflate,sdch	en-US,en;q=0.8	-	-	-	-	GET /test/uuid.json HTTP/1.1\x0D\x0AHost: test.localhost\x0D\x0AConnection: keep-alive\x0D\x0ACache-Control: max-age=0\x0D\x0AAccept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8\x0D\x0AUser-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.63 Safari/537.36\x0D\x0ADNT: 1\x0D\x0AAccept-Encoding: gzip,deflate,sdch\x0D\x0AAccept-Language: en-US,en;q=0.8\x0D\x0A\x0D\x0A
1389562820.171	8e3cea51-20d3-440b-9aa6-a90a1bf1839c	id_here	testlaptop.local	127.0.0.1	-	POST /id_here/data HTTP/1.1	200	test	http	test.localhost	/id_here/data	-	-	-	-	curl/7.24.0 (x86_64-apple-darwin12.0) libcurl/7.24.0 OpenSSL/0.9.8y zlib/1.2.5	*/*	-	-	-	-	{\x22title\x22 : \x22Test\x22, \x22tags\x22 : [\x22foo\x22,\x22bar\x22]}	-	POST /id_here/data HTTP/1.1\x0D\x0AUser-Agent: curl/7.24.0 (x86_64-apple-darwin12.0) libcurl/7.24.0 OpenSSL/0.9.8y zlib/1.2.5\x0D\x0AHost: test.localhost\x0D\x0AAccept: */*\x0D\x0AContent-Length: 42\x0D\x0AContent-Type: application/x-www-form-urlencoded\x0D\x0A\x0D\x0A	data
```

Other Notes
============

The raw response is included in your log file. NGINX encodes the response. You will see
lines with `\x0D\x0A` etc. These are encoded for your safety. You will need to decode them
to process them effectively. 

To save you some time I have a couple code samples of how to do this in:
* perl
* java
* javascript

For Perl, use the following one-liner:

```perl
	$txt =~ s{\\x(([01][0-9a-f])|([2][2f])|([5][c]))}{ chr(hex($1)) }egi;
```

I found using the `StringEscapeUtilities` from the Apache Commons library does
the job nicely for Java. Use the following code to make your life easier:

```java
	protected static final String decodeEscapeSequence(String str,
			String defaultValue) {

		if (StringUtils.isBlank(str)) {
			return defaultValue;
		}
		return StringEscapeUtils.unescapeJava(
				str.replaceAll("(?i)\\\\x([0-9a-f]{2})", "\\\\u00$1")).trim();
	}
```

For Javascript, use the following String prototype function:

```javascript
	String.prototype.decodeEscapeSequence = function() {
  	  return this.replace(/\\x([0-9A-Fa-f]{2})/g, function() {
  	      return String.fromCharCode(parseInt(arguments[1], 16));
  	  })
  	  .trim();
	};
```