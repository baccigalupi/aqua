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
      db.uri.should == 'http://127.0.0.1:5984/persist_things__for_us'
    end    
  end
  
  describe 'create' do
    before(:each) do
      Persist.delete( Database.new('things').uri ) rescue nil
    end  
    
    it '#exists? should be false if the database doesn\'t yet exist in CouchDB land' do
      db = Database.new('things')
      db.should_not be_exists
    end
    
    it 'should create a couchdb database for this instance if it doesn\'t yet exist' do 
      db = Database.create('things')
      db.should be_exists
    end
      
    it 'create should not raise an error if the database already exists' do
      db = Database.create('things')
      db.should be_exists
      lambda{ Database.create('things')}.should_not raise_error 
    end  
  end    
  
  describe 'misc managment stuff' do 
    it '#to_s should display the uri' do
      db = Database.new('things')
      db.to_s.should == db.uri
    end  
  
    it '#info raise an error if the database doesn\'t exist' do 
      db = Database.new('things')
      db.delete! if db.exists?
      lambda{ db.info }.should raise_error( Persist::ResourceNotFound )
    end
  
    it '#info should provide a hash of detail if it exists' do
      db = Database.create('things')
      info = db.info
      info.class.should == Hash
      info['db_name'].should == 'persist_things'
    end   
  
    it 'should #delete! itself' do 
      db = Database.create('things')
      db.should be_exists
      db.delete! 
      db.should_not be_exist
    end
  end   
  
  describe 'document managment' do
    before(:each) do
      @db = Database.create('docs_are_us')
    end
    
    it '#documents should return a hash' do 
      @db.documents.class.should == Hash
    end  
    
    it 'should get all documents' do
      pending
    end  
  end  

end  
