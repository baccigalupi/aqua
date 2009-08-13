require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Persist::Store::CouchDB::Server do
  before(:each) do
    Server = Persist::Store::CouchDB::Server unless defined?( Server )
  end
  
  describe 'initialization' do 
    before(:each) do
      @server = Server.new 
    end  
    
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
     
end  
