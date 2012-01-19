# Moonshine Redis

### A plugin for Moonshine[http://github.com/railsmachine/moonshine]

A plugin for installing and managing [Redis](http://code.google.com/p/redis/), an
advanced persistent key-value store. Currently this, like Moonshine's Rails
recipes in general, is Ubuntu/Debian-specific.

### Instructions

* <tt>script/plugin install git://github.com/railsmachine/moonshine_redis.git</tt>
* Configure settings if needed. You may specify:
  * Package architecture. Default is amd64.
  * Version. Default is 2.0.1-2. Versions are those as determined by Debian in [this repo](http://http.us.debian.org/debian/pool/main/r/redis/).
  * <tt>enable_on_boot</tt> in case you want to disable starting the service on
    boot at system-level (useful if you want god to do it instead, for instance).
    Default is true.
  * <tt>ruby_client</tt> to optionally install the given version of the
    <tt>redis</tt> client library as a rubygem. This also accepts
    <tt>latest</tt> as a value, which will install updated versions if
    available each time your Moonshine manifest is applied. Default is none.
  * <tt>max_fd</tt> to adjust the maximum number of open file descriptors
    allotted to Redis by the shell that launches it. Servers with a high
	  number of connections may need to specify a value here. A typical default
	  is 1024. Versions of Redis released prior to [this commit](https://github.com/antirez/redis/commit/e074416be49947c7bab5e237fab7210441bd99e5)
	  have a compiled-in upper limit of 10240.
    
For example, in <tt>moonshine.yml</tt>:

    :redis:
      :version: 2.0.1-2
      :arch: i386
      :ruby_client: 1.0.7
      :enable_on_boot: false
      :max_fd: 4096

* Include the recipe in your Moonshine manifest

    recipe :redis
