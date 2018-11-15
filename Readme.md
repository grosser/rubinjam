Jam entire gem into a binary that works with any ruby.

 - 5KB for hello-world executables
 - Release a ruby tool as standalone executable (great for [github releases](https://github.com/grosser/git-autobisect/commit/1850359b60f4119a2e2a27797fac4e7659ddcfdc))
 - Still readable, users can add debugging
 - Avoid installing a gem for each ruby version

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
 - change tests to only verify that creation works on 2.0+ and that execution works on ree/1.9.3/2+
 - ignore json gem if it has no version requirement since 1.9+ includes json
 - ruby version requirements
 - non utf-8 encoding support
 - native extensions

Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://travis-ci.org/grosser/rubinjam.png)](https://travis-ci.org/grosser/rubinjam)
