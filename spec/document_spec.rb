require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Persist::Document do
  before(:each) do 
    Document = Persist::Document unless defined?( Document )
    @db = Persist::Database.create('my_class')
  end
  
  after(:each) do 
    @db.delete!
  end    
  
  describe 'initialization' do
    before(:each) do  
      @params = {
        :id => 'my_slug/thaz-right',
        :rev => "shouldn't change yo!",
        :more => "my big stuff"
      }
      @doc = Document.new( @db, @params )
    end
       
    it 'should require a database to initialize' do 
      lambda{ Document.new }.should raise_error( ArgumentError )
      lambda{ Document.new( @db ) }.should_not raise_error
    end
  
    it 'should initialize with a hash of values' do 
      @doc[:more].should == 'my big stuff'
      @doc['more'].should == 'my big stuff'
    end
    
    it 'should set the id with the initialization hash' do 
      @doc.id.should == 'my_slug/thaz-right'
      @doc[:id].should == nil
    end
    
    it 'should not set the rev and it should discard those keys' do
      @doc.rev.should == nil 
      @doc[:rev].should == nil  
    end  
  end
  
  describe 'couch base attributes setter and getters' do
    before(:each) do  
      @params = {
        :id => 'my_slug/thaz-right',
        :rev => "shouldn't change yo!",
        :more => "my big stuff"
      }
      @doc = Document.new( @db, @params )
    end  
    
    it 'should have a settable id' do
      @doc.id = 'something/else'
      @doc.id.should == 'something/else'
    end
      
    it 'rev should not be publicly settable' do 
      lambda{ @doc.rev = 'my_rev' }.should raise_error
    end
    
    it '#new_doc should be true for unsaved documents' do
      @doc.should be_new_document
    end
    
    it '#new_doc should be false after a document has been saved' do
      @doc.save
      @doc.should_not be_new_document
    end    
  end
  
  describe 'save/create' do 
    before(:each) do  
      @params = {
        :id => 'my_slug/thaz-right',
        :rev => "shouldn't change yo!",
        :more => "my big stuff"
      } 
      @doc = Document.new( @db, @params )
    end  
    
    it 'saving should create a document in the database' do 
      @doc.save
      lambda{ Persist.get( @doc.uri ) }.should_not raise_error
    end
    
    it 'save should return itself if it worked' do
      return_value = @doc.save
      return_value.class.should == Persist::Document 
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
      @doc.id.should_not == doc_id
      @doc.rev.should_not == doc_rev
    end      
     
    it 'save! should raise an error on failure when creating' do
      @doc.save
      @doc[:_rev] = nil # should cause a conflict error HTTP 409 in couchdb
      lambda{ @doc.save! }.should raise_error
    end
    
    it 'create should return itself when successful' do
      doc = Document.create(@db, @params)
      doc.class.should == Persist::Document
      doc.rev.should_not be_nil
    end
          
  end   
  
  describe 'attachments' do 
    it 'nothing to see here yet, move along'
  end       
          
      
end