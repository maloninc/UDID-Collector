#UDID Collector
Hiroyuki Nakamura <hiroyuki@maloninc.com>

UDID Collector is a web-based simple server to collect UDIDs.
It is usefull when you want to use MDM service and need to collect UDIDs which you will give employees.

#Getting Started
Just run the following command.

	% ./server

And then, access http://your.server:8888/ from your iOS devices.
After click "enroll" link, the iOS device show "Install Profile" screen.
Just tap "install" and finally it will show "The profile does not contain any data".
That looks an error message, but it is OK. The UDID Collector collects UDID of the device at this point.

#How to get a list of UDIDs
Access http://your.server:8888/ from your PC/Mac (not iOS devices).
You will see the list of UDIDs and you can download them by clicking "Download CSV" button.
You can clear the list by clicking "Clear database" button.

#License
WTFPL
