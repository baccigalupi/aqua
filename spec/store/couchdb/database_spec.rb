require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

Aqua.set_storage_engine('CouchDB') # to initialize the Aqua::Store namespace
# Conveniences for typing with tests ... 
CouchDB =   Aqua::Store::CouchDB unless defined?( CouchDB ) 
Database =  CouchDB::Database unless defined?( Database )
Server =    CouchDB::Server unless defined?( Server)

describe 'Aqua::Store::CouchDB::Database' do
  describe 'initialization' do 
    describe 'name' do
      it 'should not require name for initialization' do
        lambda{ Database.new }.should_not raise_error( ArgumentError )
      end
    
      it 'should escape the name, when one is provided' do
        db = Database.new('&not::kosher*%')
        db.name.should == 'not__kosher'
      end  
    end
    
    describe 'server' do
      it 'should default to CouchDB\'s default server if no server option is provided' do
        db = Database.new
        db.server.should_not be_nil
        db.server.class.should == Aqua::Store::CouchDB::Server
        db.server.uri.should == 'http://127.0.0.1:5984'
        db.server.namespace.should == 'aqua'
      end
      
      it 'a custom server held in CouchDB can be used' do 
        new_host = 'http://newhost.com:8888' 
        CouchDB.servers[:customized] = CouchDB::Server.new( :server => new_host )
        db = Database.new('things', :server => :customized )
        db.server.uri.should == new_host
      end   
    end        
    
    describe 'uri' do
      it 'should use the server namespace as the path when no name is provided' do
        db = Database.new
        db.name.should == nil
        db.uri.should == "http://127.0.0.1:5984/aqua"
      end
      
      it 'should use the default server namespace and the name in the path when a name is provided but server info is not' do
        db = Database.new('things')
        db.name.should == 'things'
        db.uri.should == 'http://127.0.0.1:5984/aqua_things'
      end
      
      it 'should use the server namespace provided and the name in the path when a name and server symbol are provided' do
        db = Database.new('things', :server => :not_so_aqua )
        db.uri.should == 'http://127.0.0.1:5984/not_so_aqua_things'
      end
      
      it 'should user a custome database\'s namespace along with the name in a path if both are provided' do 
        server = Server.new(:namespace => 'different')
        db = Database.new('things', :server => server )
        db.uri.should == 'http://127.0.0.1:5984/different_things'
      end      
    end      
  end
  
  describe 'create' do
    before(:each) do
      CouchDB.delete( Database.new('things').uri ) rescue nil
    end  
    
    it 'should create a couchdb database for this instance if it doesn\'t yet exist' do 
      db = Database.create('things')
      db.should be_exists
    end
      
    it 'create should not return false if the database already exists' do
      db = Database.create('things')
      db.should_not be( false ) 
    end
    
    it 'create should return false if an HTTP error occurs' do
      CouchDB.should_receive(:put).and_raise( CouchDB::RequestFailed )
      db = Database.create('things')
      db.should == false
    end  
    
    it 'create! should create and return a couchdb database if it doesn\'t yet exist' do
      Database.new('things').should_not be_exists
      db = Database.create!('things')
      db.should be_exists
    end
    
    it 'create! should not raise an error if the database already exists' do 
      Database.create('things') 
      lambda{ Database.create!('things') }.should_not raise_error
    end
    
    it 'create should raise an error if an HTTP error occurs' do
      CouchDB.should_receive(:put).and_raise( CouchDB::RequestFailed )
      lambda{ Database.create!('things') }.should raise_error
    end      
  end    
  
  describe 'misc managment stuff' do 
    before(:each) do
      CouchDB.delete( Database.new('things').uri ) rescue nil
    end
      
    it '#exists? should be false if the database doesn\'t yet exist in CouchDB land' do
      db = Database.new('things')
      db.should_not be_exists
    end
    
    it '#exists? should be true if the database does exist in CouchDB land' do
      db = Database.create('things')
      db.should be_exists
    end
     
    it '#info raise an error if the database doesn\'t exist' do 
      db = Database.new('things')
      db.delete
      lambda{ db.info }.should raise_error( CouchDB::ResourceNotFound )
    end
  
    it '#info should provide a hash of detail if it exists' do
      db = Database.create('things')
      info = db.info
      info.class.should == Hash
      info['db_name'].should == 'aqua_things'
    end 
  end
  
  describe 'deleting' do    
    it 'should #delete itself' do 
      db = Database.create('things')
      db.should be_exists
      db.delete 
      db.should_not be_exist
    end
    
    it '#delete should return nil if it doesn\'t exist' do 
      db = Database.new('things')
      db.should_not be_exists
      lambda{ db.delete }.should_not raise_error
      db.delete.should be_nil 
    end  
  
    it 'should #delete! itself' do 
      db = Database.create('things')
      db.should be_exists
      db.delete! 
      db.should_not be_exist
    end
    
    it '#delete! should raise an error if the database doesn\'t exist' do 
      db = Database.new('things')
      db.should_not be_exists
      lambda{ db.delete! }.should raise_error
    end
  end   
  
end  
