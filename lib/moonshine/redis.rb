module Moonshine
  module Redis
    
    # converts 'truey' things to 'yes' and 'falsey' things to 'no' to fit the redis config file conventions.
    def redis_config_boolean(key, default = true)
      if key.nil?
        default ? 'yes' : 'no'
      else
        ((!!key) == true) ? 'yes' : 'no'
      end
    end

    # Checks version of Redis do determine if it supports virtual memory.
    def redis_supports_virtual_memory?
      major, minor, patch = *(configuration[:redis][:version] || '2.4.17').split('.')
      if (major.to_i <= 2 && minor.to_i <= 4)
        true
      else
        false
      end
    end

    # Used in the recipe to decide whether or not to restart redis after config changes.
    def redis_restart_on_change
      restart_on_change = configuration[:redis][:restart_on_change]
      restart_on_change = true if restart_on_change.nil? # nil is true so we have a default value.
      restart_on_change
    end

    # Define options for this plugin via the <tt>configure</tt> method
    # in your application manifest (or in moonshine.yml):
    #
    #   configure(:redis => { :version => '2.0.1-1', :arch => 'i386', :ruby_client => :latest })
    #
    # Then call the recipe(s) you need:
    #
    #  recipe :redis
    
    def redis(options={})
      options = HashWithIndifferentAccess.new({ :enable_on_boot => true }.merge(options))
      make_command = options[:arch] || Facter.architecture == 'i386' ? 'make 32bit' : 'make'
      version = options[:version] || '2.6.16'

      notifies = if redis_restart_on_change
                   [service('redis-server')]
                 else
                   []
                 end

      package 'wget', :ensure => :installed
      exec 'download redis',
        :command => "wget http://download.redis.io/releases/redis-#{version}.tar.gz",
        :require => package('wget'),
        :cwd     => '/usr/local/src',
        :creates => "/usr/local/src/redis-#{version}.tar.gz"
      exec 'untar redis',
        :command => "tar xzvf redis-#{version}.tar.gz",
        :require => exec('download redis'),
        :cwd     => '/usr/local/src',
        :creates => "/usr/local/src/redis-#{version}"
      exec 'compile redis',
        :command => make_command,
        :require => exec('untar redis'),
        :cwd     => "/usr/local/src/redis-#{version}",
        :creates => "/usr/local/src/redis-#{version}/src/redis-server"
      package 'redis-server',
        :ensure   => :absent,
        :provider => :dpkg,
        :require   => exec('compile redis')
      exec 'shutdown redis',
        :command => "redis-cli shutdown",
        :timeout => 0,
        :onlyif => "which redis-cli",
        :refreshonly => true
      exec 'install redis',
        :command => "sudo make install",
        :timeout => 0,
        :require => package('redis-server'),
        :cwd     => "/usr/local/src/redis-#{version}",
        :notify => exec('shutdown redis'),
        :unless => "test -f /usr/local/bin/redis-server && /usr/local/bin/redis-server --version | grep '#{version} '"

      group 'redis', :ensure =>:present
      user 'redis',
        :gid => 'redis',
        :comment => 'redis server',
        :home => '/var/lib/redis',
        :shell => '/bin/false',
        :require => group('redis')

      file '/var/lib/redis',
        :ensure => :directory,
        :owner  => 'redis',
        :group  => 'redis',
        :mode   => '755'

      file '/var/log/redis',
        :ensure => :directory,
        :owner  => 'redis',
        :group  => 'redis',
        :mode   => '755'

      file '/var/log/redis/redis-server.log',
        :ensure => :present,
        :owner  => 'redis',
        :group  => 'redis',
        :mode   => '660'

      service 'redis-server',
        :ensure  => :running,
        :enable  => options[:enable_on_boot],
        :require => [
          exec('install redis'),
          file('/etc/init.d/redis-server'),
          user('redis'), group('redis'),
          file('/var/lib/redis'),
          file('/var/log/redis')
        ]

      file '/etc/init.d/redis-server',
        :ensure  => :present,
        :mode    => '755',
        :content => template(File.join(File.dirname(__FILE__), '..', '..', 'templates', 'init.d'), binding)

      file '/etc/redis', :ensure => :directory
      file '/etc/redis/redis.conf',
        :ensure  => :present,
        :mode    => '644',
        :notify  => notifies,
        :content => template(File.join(File.dirname(__FILE__), '..', '..', 'templates', 'redis.conf.erb'), binding)

      # install client gem if specified
      if options[:ruby_client]
        gem 'redis', :require => package('redis-server'), :version => options[:ruby_client]
      end
    end

  end  
end
