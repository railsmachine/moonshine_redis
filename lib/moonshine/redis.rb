module Moonshine
  module Redis

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
      version = options[:version] || '2.2.0'

      package 'wget', :ensure => :installed
      exec 'download redis',
        :command => "wget http://redis.googlecode.com/files/redis-#{options[:version]}.tar.gz",
        :require => package('wget'),
        :cwd     => '/usr/local/src',
        :creates => "/usr/local/src/redis-#{options[:version]}.tar.gz"
      exec 'untar redis',
        :command => "tar xzvf redis-#{options[:version]}.tar.gz",
        :require => exec('download redis'),
        :cwd     => '/usr/local/src',
        :creates => "/usr/local/src/redis-#{options[:version]}"
      exec 'compile redis',
        :command => make_command,
        :require => exec('untar redis'),
        :cwd     => "/usr/local/src/redis-#{options[:version]}",
        :creates => "/usr/local/src/redis-#{options[:version]}/redis-server"
      exec 'shutdown redis',
        :command => "redis-cli shutdown || true",
        :timeout => 0,
        :require => exec('compile redis'),
        :refreshonly => true
      package 'redis-server',
        :ensure   => :absent,
        :provider => :dpkg,
        :require   => exec('shutdown redis')
      exec 'install redis',
        :command => "make install",
        :require => package('redis-server'),
        :cwd     => "/usr/local/src/redis-#{options[:version]}",
        :unless => "/usr/local/bin/redis-server --version | grep 'Redis server version #{options[:version]}$'"

      service 'redis-server',
        :ensure  => :running,
        :enable  => options[:enable_on_boot],
        :require => [package('redis-server'), exec('install redis'), file('/etc/init.d/redis-server')]

      file '/etc/init.d/redis-server',
        :ensure  => :present,
        :mode    => '755',
        :content => template(File.join(File.dirname(__FILE__), '..', '..', 'templates', 'init.d'), binding)

      file '/etc/redis', :ensure => :directory
      file '/etc/redis/redis.conf',
        :ensure  => :present,
        :mode    => '644',
        :notify  => service('redis-server'),
        :content => template(File.join(File.dirname(__FILE__), '..', '..', 'templates', 'redis.conf.erb'), binding)

      # install client gem if specified
      if options[:ruby_client]
        gem 'redis', :require => package('redis-server'), :version => options[:ruby_client]
      end
    end

  end
end