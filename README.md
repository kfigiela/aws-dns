# aws-dns

DNS server for Mac OS X that maps Amazon EC2 instance ids and names into virtual `.aws` domain. No Linux support at this time.

Heavily inspired by [Pow](http://pow.cx).

## How to use?

* `npm install -g https://github.com/kfigiela/aws-dns/archive/master.tar.gz`,
* `aws-dns-install`, the script will:
  * enable `.aws` virtual TLD in OS X resolver (sudo required),
  * register and start `aws-dns` service with launchd (see install.sh for more details).
