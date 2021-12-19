INTRO
-----
This is a very simple web-interface for raspKAKU, a program that
allows you to switch Klik-aan, Klik-uit switches with a 433MHz 
module on a Raspberry Pi. It also provides an interface for API
calls to Domoticz.


REQUIREMENTS
------------
Of course, you will need the hardware (Pi, 433MHz module, KAKU
switches).

First, download reskKaku and get it working from the CLI. You can
get raspKaku from:

https://github.com/chaanstra/raspKaku

Next, you will need a webserver that allows you to install CGI
scripts. I used Apache, but there may be others.


SECURITY
--------
These scripts are for internal use on your own private network.
They are not suitable for access over the Internet, or any other
network that is not your home network.

Also, you need to keep in mind that Klik-aan, Klik-uit is a very
simpel system, that is suitable for home environments, but not
for much more.
