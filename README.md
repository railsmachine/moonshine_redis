# Moonshine Redis

### A plugin for Moonshine[http://github.com/railsmachine/moonshine]

A plugin for installing and managing [Redis](http://code.google.com/p/redis/), an
advanced persistent key-value store. Currently this, like Moonshine's Rails
recipes in general, is Ubuntu/Debian-specific.

### Instructions

* <tt>script/plugin install git://github.com/railsmachine/moonshine_redis.git</tt>
* Configure settings if needed. You may specify:
  * Package architecture. Default is amd64.
  * Version. Default is 2.4.17, but should work fine with 2.6+
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
    
### Available configuration options in the <code>:redis:</code> section of moonshine.yml, their default and an explanation if needed:

* :version: 2.4.17
* :restart_on_change: true # should redis restart after its config files change?
* :port: 6379
* :bind: 0.0.0.0
* :loglevel: notice
* :databases: 16 # Number of databases to run with. 16 should be enough for almost all uses.
* :saves: # how often to write the rdb file based on number of changes per time period (ie: 1 change, save every 900 seconds)
  * - 'save 900 1'
  * - 'save 300 10'
  * - 'save 60 10000'
* :rdbcompression: false
* :slaves: # an array of 'slaveof IP PORT', defaults to none.
* :masterauth: # defaults to no authentication. If you want a password, :masterauth: should be set to that password.
* :requirepass: false
* :maxclients: 0
* :maxmemory: 0
* :appendonly: false
* :appendfsync: everysec # this is the default for redis and the recommended setting.
* :vm_enabled: false # warning: virtual memory has been removed in 2.6 and won't be added to the config file if you have version set > 2.4
* :vm_max_memory: # defaults to unset
* :vm_page_size: # defaults to unset
* :vm_pages: # defaults to unset
* :vm_max_threads: # defaults to unset

## Virtual Memory and Redis

We *highly* recommend setting the sysctl setting <code>vm.overcommit_memory</code>.  Thankfully, [moonshine_systcl](http://github.com/railsmachine/moonshine_sysctl) can help with this.  Just install the plugin and then add the following the config/moonshine.yml:

<pre><code>:sysctl:
  vm.overcommit_memory: 1</code></pre>

You'll also need to add <code>recipe :sysctl</code> to your manifest.