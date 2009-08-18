require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

Aqua.set_storage_engine('CouchDB') # to initialize the Aqua::Store namespace
Server = Aqua::Store::CouchDB::Server unless defined?( Server )
    
describe 'Aqua::Store::CouchDB::Server' do
  before(:each) do
    @server = Server.new
  end
  
  before(:all) do 
    Server.new.delete_all
  end  
  
  describe 'initialization' do
    it 'should have a default uri "http://127.0.0.1:5984"' do
      @server.uri.should == 'http://127.0.0.1:5984' 
    end
    
    it 'should have a settable uri' do 
      server = Server.new(:server => 'http://newhost.com:5984')
      server.uri.should == 'http://newhost.com:5984'
    end
    
    it 'should have a database prefix for namespacing the collection of persistance databases' do
      @server.namespace.should == 'aqua'
    end
    
    it 'should have a settable namespace' do
      server = Server.new(:namespace => 'not_aqua') 
      server.namespace.should == 'not_aqua'
    end
    
    it 'should escape alpha-numeric, plus hyphen and underscore, characters from the namespace' do 
      server = Server.new(:namespace => '&not_!kosher*%')
      server.namespace.should == 'not_kosher'
    end
    
    it 'should escape :: in the namespace and substitute with __' do
      server = Server.new(:namespace => 'not::kosher')
      server.namespace.should == 'not__kosher'
    end
  end 
  
  describe 'general couchdb managment features' do
    it 'should retain a set of uuids to prevent collision' do
      token = @server.next_uuid( 2 )
      @server.next_uuid.should_not == token
      Aqua::Store::CouchDB.should_receive(:get).and_return({'uuids' => []}) # because we have run out of uuids on the last request
      @server.next_uuid
    end   
    
    it 'should get couchdb info' do
      info = @server.info #{"couchdb"=>"Welcome", "version"=>"0.9.0"}
      info.class.should == Hash  
      info['couchdb'].should == 'Welcome'
    end  
    
    it 'should restart the couchdb server' do
      Aqua::Store::CouchDB.should_receive(:post).with("#{@server.uri}/_restart" ) 
      @server.restart!
    end  
  end   
  
  describe 'managing databases' do
    before(:all) do 
      Server.new.delete_all # this is kind of circular testing here ... 
      Server.new.databases.size.should == 0
    end
      
    it 'should have a convenience method for creating databases' do 
      @server.database!('first')
      Aqua::Store::CouchDB::Database.new('first').should be_exists
    end
      
    it 'should show all_databases related to this server as an array' do
      @server.database!('second')
      dbs = @server.databases
      dbs.class.should == Array
      dbs.size.should == 2
      dbs.first.class.should == Aqua::Store::CouchDB::Database 
    end
    
    it 'should show default database in the list of databases' do
      Aqua::Store::CouchDB::Database.create!
      @server.databases.size.should == 3
    end  
      
    it 'should delete_all! databases for the namespace' do 
      @server.databases.size.should == 3
      @server.delete_all!
      @server.databases.size.should == 0
    end    
  end   
     
end  
