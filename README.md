# rt-client
RT_Client is a ruby object that accesses the REST interface version 1.0 of a Request Tracker instance. See http://www.bestpractical.com/ for Request Tracker.
A ruby library API to Request Tracker's REST interface. Requires the
rubygem rest-client be installed.  You can
create a file name .rtclientrc in the same directory as client.rb with a
default server/user/pass to connect to RT as, so that you don't have to
specify it/update it in lots of different scripts.

Thanks to the following members of the RT community for patches:
* Brian McArdle for patch dealing with spaces in Custom Fields (use '_')
* Steven Craig for a bug fix and feature additions to the usersearch() method.
* Rafael Abdo for fixing a broken regex.

* Extra Special Thanks to Robert Vinson for 1.9.x compatibility and refactoring the old mess into something with much fewer
dependencies.

TODO: Streaming, chunking attachments in compose method

See each method for sample usage.  To use this, "gem install rt-client" and
```ruby
require "rt_client"
```

# Documentation
For usage documentation, see [http://www.rubydoc.info/gems/rt-client/1.0.0/RT_Client]
