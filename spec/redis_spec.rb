require File.join(File.dirname(__FILE__), 'spec_helper.rb')

class RedisManifest < Moonshine::Manifest::Rails
end

describe "A manifest with the Redis plugin" do

  before do
    @manifest = RedisManifest.new
    @manifest.redis
  end

  it "should download the redis package for the specified arch, defaulting to amd64" do
    @manifest.execs['download redis'].command.should match(/amd64/)
    @manifest.redis(:arch => 'i386')
    @manifest.execs['download redis'].command.should match(/i386/)
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

end
