Jam a gem into a universal binary that works with any ruby.

 - Everything in 1 tiny binary
 - No gem installation
 - No version management
 - Readable/Editable binary to add debugging output when needed

Install
=======

As gem:

```Bash
gem install rubinjam
```

Standalone binary:

```Bash
curl https://rubinjam.herokuapp.com/pack/rubinjam > rubinjam && chmod +x rubinjam
./rubinjam -v
```

Usage
=====

### CLI

```Bash
rubinjam # convert current directory into a binary
```

### Web

```Bash
curl https://rubinjam.herokuapp.com/pack/pru > pru && chmod +x pru
./pru -v
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
