require File.join(File.dirname(__FILE__), 'spec_helper.rb')

class RedisManifest < Moonshine::Manifest::Rails
  include Moonshine::Redis
end

describe "A manifest with the Redis plugin" do

  before do
    @manifest = RedisManifest.new
    @manifest.redis
  end

  it "should download the specified version, defaulting to 2.2.11" do
    @manifest.execs['download redis'].command.should match(/2\.2\.11/)
    @manifest.redis(:version => '1.2.6-1')
    @manifest.execs['download redis'].command.should match(/1\.2\.6-1/)
  end

  it "should install the redis-server package" do
    @manifest.packages.keys.should include('redis-server')
  end

  it "should configure and run the redis-server service" do
    @manifest.services.keys.should include('redis-server')
    @manifest.services['redis-server'].ensure.should == :running
  end

  it "should allow running service at boot to be disabled" do
    @manifest.services['redis-server'].enable.should == true
    @manifest.redis(:enable_on_boot => false)
    @manifest.services['redis-server'].enable.should_not == true
  end

  it "should install the redis configuration file" do
    @manifest.files['/etc/redis/redis.conf'].should_not be(nil)
  end
  it "should install the Ruby client library for Redis iff the option is given" do
    @manifest.packages.keys.should_not include('redis')

    # stub so Gem ignores what you really have installed locally
    Gem.stub_chain(:source_index, :search => [])
    @manifest.redis(:ruby_client => '0.1.1')
    @manifest.packages.keys.should include('redis')
    @manifest.packages['redis'].ensure.should == '0.1.1'
  end

  it "should create a log directory" do
    redis_log_directory = @manifest.files['/var/log/redis']
    redis_log_directory.should_not be(nil)
    redis_log_directory[:ensure].should == :directory
    redis_log_directory[:owner].should == 'redis'
    redis_log_directory[:group].should == 'redis'
    redis_log_directory[:mode].should == '755'
  end

  it "should create a log file" do
    redis_log_file = @manifest.files['/var/log/redis/redis-server.log']
    redis_log_file.should_not be(nil)
    redis_log_file[:owner].should == 'redis'
    redis_log_file[:group].should == 'redis'
    redis_log_file[:mode].should == '660'
  end

  it "should create a log directory" do
    redis_log_directory = @manifest.files['/var/log/redis']
    redis_log_directory.should_not be(nil)
    redis_log_directory[:ensure].should == :directory
    redis_log_directory[:owner].should == 'redis'
    redis_log_directory[:group].should == 'redis'
    redis_log_directory[:mode].should == '755'
  end

  it "should create a redis user" do
    redis_user = @manifest.users['redis']
    redis_user.should_not be(nil)
    redis_user[:home].should == '/var/lib/redis'
    redis_user[:shell].should == '/bin/false'
    redis_user[:gid].should == 'redis'
  end

  it "should create a redis group" do
    @manifest.groups.should include('redis')
  end
end
