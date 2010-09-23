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
      options = { :enable_on_boot => true }.merge(options)
      arch = options[:arch] || 'amd64'
      version = options[:version] || '2.0.1-2'

      package 'wget', :ensure => :installed
      exec 'download redis',
        :command => "wget http://http.us.debian.org/debian/pool/main/r/redis/redis-server_#{version}_#{arch}.deb",
        :require => package('wget'),
        :cwd     => '/usr/local/src',
        :creates => "/usr/local/src/redis-server_#{version}_#{arch}.deb"
      package 'redis-server',
        :ensure   => :installed,
        :provider => :dpkg,
        :source   => "/usr/local/src/redis-server_#{version}_#{arch}.deb",
        :require  => exec('download redis')

      service 'redis-server',
        :ensure  => :running,
        :enable  => options[:enable_on_boot],
        :require => package('redis-server')
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
