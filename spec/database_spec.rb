require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Persist::Database do
  before(:each) do
    Database = Persist::Database unless defined?( Database )
  end
     
  describe 'initialization' do 
    it 'should require only a name for initialization' do
      lambda{ Database.new }.should raise_error( ArgumentError )
      lambda{ Database.new('things')}.should_not raise_error
    end
    
    it 'should escape the name' do
      db = Database.new('&not::kosher*%')
      db.name.should == 'not__kosher'
    end  
      
    it 'should default to Server.new when no server supplied' do
      db = Database.new('things')
      db.server.should_not be_nil
      db.server.uri.should == Persist::Server.new.uri
    end
      
    it 'if a server is supplied it will be used instead' do 
      # this can save you some memory, so there isn't an instance of the server for each class
      new_host = 'http://newhost.com:8888' 
      Persist.server = Persist::Server.new( :server => new_host )
      db = Database.new('things')
      db.server.uri.should == new_host
      Persist.server = nil # reset for future runs
    end
    
    it 'should put together a database uri from the server and name' do 
      db = Database.new('&&things::for_us')
      db.uri.should == 'http://127.0.0.1:5984/things__for_us'
    end    
  end
  
  describe 'create' do
    it 'should create a couchdb database for this instance if it doesn\'t yet exist'
    it 'create should not raise an error if the database already exists'
  end    
  
  it '#to_s should display the uri'
  
  it '#info raise an error if the database doesn\'t exist' do 
    Persist.set_http_adapter
    db = Database.new('things')
    lambda{ db.info }.should raise_error( Persist::ResourceNotFound )
  end  
  
  
end  
