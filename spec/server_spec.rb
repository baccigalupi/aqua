require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Persist::Server do
  before(:each) do
    Persist.set_http_adapter
    Server = Persist::Server unless defined?( Server )
    @server = Server.new 
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
      @server.namespace.should == 'persist_'
    end
    
    it 'should have a settable namespace' do
      server = Server.new(:namespace => 'not_persist') 
      server.namespace.should == 'not_persist'
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
      Persist.should_receive(:get).and_return({'uuids' => []}) # because we have run out of uuids on the last request
      @server.next_uuid
    end   
    
    it 'should get couchdb info' do
      info = @server.info #{"couchdb"=>"Welcome", "version"=>"0.9.0"}
      info.class.should == Hash  
      info['couchdb'].should == 'Welcome'
    end  
    
    it 'should restart the couchdb server' do
      Persist.should_receive(:post).with("#{@server.uri}/_restart" ) 
      @server.restart!
    end  
  end   
  
  describe 'managing databases' do 
    it 'should create databases'
    it 'should show all_databases as an array'
    it 'should only show databases for the namespace of the server'
    it 'should delete_all! databases for the namespace'  
  end   
     
end  
