require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

Aqua.set_storage_engine('CouchDB') # to initialize the Aqua::Store namespace
require File.dirname(__FILE__) + '/document_fixture' # Document ... a Mash with the collection of methods

# Conveniences for typing with tests ... 
CouchDB =   Aqua::Store::CouchDB unless defined?( CouchDB ) 
Database =  CouchDB::Database unless defined?( Database )
Server =    CouchDB::Server unless defined?( Server)

describe 'CouchDB::StorageMethods' do
  before(:each) do
    @params = {
      :id => 'my_slug/thaz-right',
      :rev => "shouldn't change yo!",
      :more => "my big stuff"
    }
    @doc = Document.new( @params )
  end  
  
  describe 'initialization' do
    it 'should initialize with a hash of values accessible by symbol or string' do 
      @doc[:more].should == 'my big stuff'
      @doc['more'].should == 'my big stuff'
    end
    
    it 'should set the id with the initialization hash' do 
      @doc.id.should == 'my_slug/thaz-right' 
    end
    
    it 'should escape the id' do  
      @doc[:_id].should == 'my_slug%2Fthaz-right'
    end
    
    it 'should not set the rev and it should discard those keys' do
      @doc.rev.should == nil 
      @doc[:rev].should == nil  
    end
    
    it 'rev should not be publicly settable' do 
      lambda{ @doc.rev = 'my_rev' }.should raise_error
    end  
  end
  
  describe 'database' do 
    before(:each) do
      CouchDB.server.delete_all  
    end  
    
    it 'should not be nil' do
      @doc.database.should_not be_nil
    end
    
    it 'should have the default database uri by default'  do 
      @doc.database.uri.should == 'http://127.0.0.1:5984/aqua'
    end
    
    it 'should be settable' do
      @doc.database = Database.create('my_class')
      @doc.database.uri.should == 'http://127.0.0.1:5984/aqua_my_class'
    end
    
    it 'should depend on database strategies set for storage\'s parent class' do
      pending( 'Have to create some CouchDB database strategies. Also have to make parent classes configurable.')
    end       
  end 
  
  describe 'uri' do 
    before(:each) do
      CouchDB.server.delete_all  
    end  
    
    it 'should have use the default database uri by default with the document id'  do 
      @doc.uri.should == 'http://127.0.0.1:5984/aqua/my_slug%2Fthaz-right'
    end
    
    it 'should reflect the non-default database name' do
      @doc.database = Database.create('my_class')
      @doc.uri.should == 'http://127.0.0.1:5984/aqua_my_class/my_slug%2Fthaz-right'
    end
    
    it 'should use a server generated uuid for the id if an id is not provided' do
      params = @params.dup
      params.delete(:id)
      doc = Document.new( params )
      doc.uri.should match(/\A#{doc.database.uri}\/[a-f0-9]*\z/)
    end  
           
  end  
  
  describe 'revisions' do
    before(:each) do
      CouchDB.server.delete_all  
    end  
    
    it 'should be an empty array for a new record' do 
      @doc.revisions.should == []
    end 
    
    it 'should have one value after the document is saved' do
      @doc.save!
      @doc.revisions.size.should == 1
      @doc.revisions.first.should == @doc[:_rev]
    end   
  end  
  
  describe 'save/create' do 
    before(:each) do
      CouchDB.server.delete_all  
    end  
    
    it 'saving should create a document in the database' do 
      @doc.save
      lambda{ Aqua::Store::CouchDB.get( @doc.uri ) }.should_not raise_error
    end
    
    it 'save should return itself if it worked' do
      return_value = @doc.save
      return_value.class.should == Document 
      return_value.id.should == @doc.id
    end
    
    it 'save should return false if it did not work' do
      @doc.save
      @doc[:_rev] = nil # should cause a conflict error HTTP 409 in couchdb
      lambda{ @doc.save }.should_not raise_error
      @doc.save.should == false
    end
    
    it 'saving should update the "id" and "rev"' do
      doc_id = @doc.id
      doc_rev = @doc.rev
      @doc.save
      @doc[:_id].should_not == doc_id
      @doc.rev.should_not == doc_rev
    end      
     
    it 'save! should raise an error on failure when creating' do
      @doc.save
      @doc[:_rev] = nil # should cause a conflict error HTTP 409 in couchdb
      lambda{ @doc.save! }.should raise_error
    end
    
    it 'create should return itself when successful' do
      doc = Document.create(@params)
      doc.class.should == Document
      doc.rev.should_not be_nil
    end
    
    it '#new? should be true for unsaved documents' do
      @doc.should be_new
    end
    
    it '#new? should be false after a document has been saved' do
      @doc.save!
      @doc.should_not be_new
    end
    
    it 'should #exists? if it has been saved to CouchDB' do 
      @doc.save!
      @doc.should be_exists
    end
    
    it 'should not #exists? if the document is new' do
      @doc.should_not be_exists
    end    
  end 
  
  describe 'deleting' do
    before(:each) do
      CouchDB.server.delete_all  
    end  
    
    it 'should #delete a record'
    it 'should return false'
    it 'should raise an error on failure when #delete! is used'
  end  
  
  describe 'updating' do
    before(:each) do
      CouchDB.server.delete_all!
    end  
    
    it 'saving after a change should change the revision number' do 
      @doc.save 
      rev = @doc.rev
      _id = @doc[:_id]
      id = @doc[:id] 
      @doc['more'] = 'less ... really'
      @doc['newness'] = 'overrated'
      @doc.save
      @doc.id.should == id
      @doc[:_id].should == _id
      @doc.rev.should_not == rev
    end
      
    it 'saving after a change should retain changed data' do
      @doc.save 
      @doc['more'] = 'less ... really'
      @doc['newness'] = 'overrated'
      @doc.save
        
      @doc['more'].should == 'less ... really'
      @doc['newness'].should == 'overrated'
    end  
  end
          
      
end