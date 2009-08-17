require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

Aqua.set_storage_engine('CouchDB') # to initialize the Aqua::Store namespace
CouchDB = Aqua::Store::CouchDB unless defined?( CouchDB )
describe CouchDB do
  describe 'http_client setup' do
    describe 'autoloading' do
      it 'should not raise an error loading the default adapter' do 
        lambda{ CouchDB.set_http_adapter }.should_not raise_error
      end
    
      it 'should add rest methods to the Aqua module' do
        CouchDB.set_http_adapter
        CouchDB.should respond_to(:get)
      end 
    end
    
    describe 'manual loading of an alternate library' do
      # TODO: when there is an alternate library
    end         
  end
  
  describe 'servers' do
    it '#servers should return an empty hash by default' do
      CouchDB.servers.should == {}
    end
    
    it 'should create a default server if no argument is passed' do 
      server = CouchDB.server 
      server.should_not be_nil
      CouchDB.servers.should_not be_empty
      CouchDB.servers[:aqua].should == server
      server.namespace.should == 'aqua'
    end    
    
    it 'should add servers when a symbol is requested that is not found as a servers key' do 
      server = CouchDB.server(:users)
      CouchDB.servers.size.should == 2
      CouchDB.servers[:users].should == server
      server.namespace.should == 'users'
    end
    
    it 'should not duplicate servers' do
      CouchDB.server(:users)
      CouchDB.servers.size.should == 2
      CouchDB.server
      CouchDB.servers.size.should == 2
    end    
    
    it 'should list the servers in use' do
      CouchDB.server(:noodle)
      CouchDB.servers.size.should == 3 
      CouchDB.servers.each do |key, server|
        server.class.should == Aqua::Store::CouchDB::Server
      end   
    end
    
    it 'should allow the addition of customized servers' do
      new_host = 'http://newhost.com:8888' 
      CouchDB.servers[:custom] = CouchDB::Server.new( :server => new_host )
      CouchDB.servers.size.should == 4
      CouchDB.servers[:custom].uri.should == new_host
    end   
  end  

  describe 'helper methods' do 
    describe 'escaping names' do 
      it 'should escape :: module/class separators with a double underscore __' do
        string = CouchDB.escape('not::kosher')
        string.should == 'not__kosher'
      end
      
      it 'should remove non alpha-numeric, hyphen, underscores from a string' do 
        string = CouchDB.escape('&not_!kosher*%')
        string.should == 'not_kosher'
      end        
    end
    
    describe 'paramify_url' do
      it 'should build a query filled url from a base url and a params hash' do 
        url = CouchDB.paramify_url( 'http://localhost:5984', {:gerbil => true, :keys => 'you_know_it'} )
        url.should match(/\?/)
        url.should match(/&/)
        url.should match(/keys=you_know_it/)
        url.should match(/gerbil=true/)
      end  
    end     
  end  
end    
  