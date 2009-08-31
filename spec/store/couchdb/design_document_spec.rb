require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

Aqua.set_storage_engine('CouchDB') # to initialize the Aqua::Store namespace

# Conveniences for typing with tests ... 
CouchDB =   Aqua::Store::CouchDB unless defined?( CouchDB ) 
Database =  CouchDB::Database unless defined?( Database )
Server =    CouchDB::Server unless defined?( Server )
Design =    CouchDB::DesignDocument unless defined?( Design )

describe CouchDB::DesignDocument do 
  before(:each) do
    CouchDB.server.delete_all  
  end  
    
  describe 'new and create' do
    before(:each) do
      @name = 'User'
      @design = Design.new(:name => @name)
    end
      
    it 'should require a name to build the uri' do
      design = Design.new
      lambda{ design.uri }.should raise_error
      lambda{ @design.uri }.should_not raise_error
    end
      
    it 'should build the correct uri' do
      @design.uri.should == 'http://127.0.0.1:5984/aqua/_design/User'
    end
      
    it 'should save' do 
      lambda{ @design.save! }.should_not raise_error
      lambda{ CouchDB.get( @design.uri ) }.should_not raise_error
    end  
  end
  
  describe 'views' do
    
  end    
  
  
end  