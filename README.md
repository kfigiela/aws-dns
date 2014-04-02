# aws-dns

DNS server for Mac OS X that maps Amazon EC2 instance ids and names into virtual `.aws` domain. 

Heavily inspired by [Pow](http://pow.cx).

## How to use?

* Create `/etc/resolver/aws` file with the following contents:
  ```
  nameserver 127.0.0.1
  port 20561```
* Run server
  