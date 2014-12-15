Jam entire gem into a binary that works with any ruby.

 - All dependencies included
 - Still readable, can add debugging
 - use when you cannot install gems or don't want to install a gems multiple times

```Bash
# https://rubinjam.herokuapp.com/pack/GEM/VERSION
curl https://rubinjam.herokuapp.com/pack/rake > rake && chmod +x rake
./rake --version
```

Pack local/non-gem
============

```Bash
gem install rubinjam
rubinjam # convert current directory into a binary
```

TODO
====
 - ruby version requirements
 - non utf-8 encoding support
 - native extensions

Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://travis-ci.org/grosser/rubinjam.png)](https://travis-ci.org/grosser/rubinjam)
