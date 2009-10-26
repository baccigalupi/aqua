require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

Aqua.set_storage_engine('CouchDB') # to initialize the Aqua::Store namespace
require File.dirname(__FILE__) + '/fixtures_and_data/document_fixture' # Document ... a Mash with the collection of methods

# Conveniences for typing with tests ... 
CouchDB =     Aqua::Store::CouchDB    unless defined?( CouchDB ) 
Database =    CouchDB::Database       unless defined?( Database )
Server =      CouchDB::Server         unless defined?( Server)
Attachments = CouchDB::Attachments    unless defined?( Attachments )

describe 'CouchDB::StorageMethods' do
  before(:each) do
    @params = {
      :id => 'my_slug/thaz-right',
      :rev => "shouldn't change yo!",
      :more => "my big stuff"
    }
    @doc = Document.new( @params ) 
    @doc.class.database.delete_all
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
  end 
  
  describe 'core attributes' do
    
    describe 'revisions' do
      before(:each) do
        @doc.delete if @doc.exists?  
      end  
    
      it 'should be an empty array for a new record' do 
        @doc.revisions.should == []
      end 
    
      it 'should have one value after the document is saved' do
        @doc.save!
        @doc.revisions.size.should == 1
        @doc.revisions.first.should == @doc[:_rev]
      end
    
      it 'should continue adding revisions with each save' do
        @doc.save!
        @doc['new_attr'] = 'my new attribute, yup!'
        @doc.save!
        @doc.revisions.size.should == 2
      end     
    end    
    
    it 'rev should not be publicly settable' do 
      lambda{ @doc.rev = 'my_rev' }.should raise_error
    end 
    
    describe 'changing the id, post save' do
      before(:each) do
        @doc.database.delete_all
        @doc.save!
        @doc.id = 'something/new_and_fresh'
      end  
      
      it 'should change the id' do 
        @doc.id.should == 'something/new_and_fresh'
      end
        
      it 'should change the _id' do
        @doc[:_id].should == 'something%2Fnew_and_fresh'
      end
        
      it 'should successfully save' do
        lambda{ @doc.save! }.should_not raise_error
        @doc.retrieve['id'].should == 'something/new_and_fresh'
      end
        
      it 'should delete earlier versions on save' do 
        @doc.save!
        lambda{ CouchDB.get( "#{@doc.database.uri}/aqua/my_slug%2Fthaz-right") }.should raise_error
      end  
    end   
  
  end  
  
  describe 'database' do 
    before(:each) do
      @doc.delete  
    end
    
    it 'should have a database per class' do
      Document.database.should_not be_nil
      Document.database.uri.should == 'http://127.0.0.1:5984/aqua'
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
      @doc.delete if @doc.exists?  
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
  
  describe 'save/create' do 
    it 'saving should create a document in the database' do 
      @doc.save
      lambda{ Aqua::Store::CouchDB.get( @doc.uri ) }.should_not raise_error
    end
    
    it 'save should return itself if it worked' do
      return_value = @doc.save
      return_value.class.should == Document 
      return_value.id.should == @doc.id
    end
    
    it 'saving should return false if it did not work' do
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
    
    it 'should reload' do
      @doc.save!
      @doc[:noodle] = 'spaghetti'
      @doc.reload
      @doc[:noodle].should be_nil
    end
    
    it 'should create using find_or_create' do 
      lambda{ Document.get( @params[:id] ) }.should raise_error
      doc = Document.find_or_create( @params[:id] )
      lambda{ Document.get( @params[:id] ) }.should_not raise_error
    end      
  end 
  
  describe 'getting' do
    it 'should get a document from its id' do 
      @doc.save
      lambda{ Document.get( @doc.id ) }.should_not raise_error
    end  
  end  
  
  describe 'deleting' do
    before(:each) do
      @doc.delete if @doc.exists?  
    end  
    
    it 'should #delete a record' do
      @doc.save!
      @doc.delete
      @doc.should_not be_exists
    end
    
    it 'should return true on successful #delete' do
      @doc.save!
      @doc.delete.should == true
    end  
      
    it 'should return false when it fails' do 
      @doc.save!
      CouchDB.should_receive(:delete).and_raise( CouchDB::Conflict )
      @doc.delete.should == false
    end
      
    it 'should raise an error on failure when #delete! is used' do 
      @doc.save!
      CouchDB.should_receive(:delete).and_raise( CouchDB::Conflict )
      lambda { @doc.delete! }.should raise_error
    end  
  end  
  
  describe 'updating' do
    before(:each) do
      @doc.delete if @doc.exists?
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
      @doc.retrieve['more'].should == 'less ... really'
    end  
  end
  
  describe 'attachments' do
    before(:each) do
      @file = File.new( File.dirname( __FILE__ ) + '/fixtures_and_data/image_attach.png' )
    end
       
    it 'should have an accessor for storing attachments' do 
      @doc.attachments.should == Attachments.new( @doc )
    end
    
    it 'should add attachments' do 
      @doc.attachments.add(:my_file, @file)
      @doc.attachments[:my_file].should == @file
    end
    
    it 'should pack attachments' do
      @doc.attachments.add(:my_file, @file)
      @doc.attachments.add("dup.png", @file)
      pack = @doc.attachments.pack
      pack.keys.should include('my_file', 'dup.png')
    end
    
    it 'should pack attachments to key _attachments on save' do 
      @doc.delete! if @doc.exists?
      @doc.attachments.add(:my_file, @file)
      @doc.attachments.add("dup.png", @file)
      pack = @doc.attachments.pack
      @doc.save!
      @doc[:_attachments].should == pack
    end   
    
    it 'should pack attachments before save' do 
      @doc.delete! if @doc.exists?
      
      @doc.attachments.add(:my_file, @file)
      @doc.attachments.add("dup.png", @file)
      pack = @doc.attachments.pack
       
      @doc.attachments.should_receive( :pack ).and_return( pack )
      @doc.commit
    end 
    
    it 'should pack attachments before save' do 
      @doc.delete! if @doc.exists?
      
      @doc.attachments.add(:my_file, @file)
      @doc.attachments.add("dup.png", @file)
      pack = @doc.attachments.pack
       
      @doc.attachments.should_receive( :pack ).and_return( pack )
      @doc.commit
    end 
    
    it 'should be correctly formed in database' do
      @doc.delete! if @doc.exists?
      
      @doc.attachments.add(:my_file, @file)
      @doc.attachments.add("dup.png", @file)
      @doc.commit
      @doc.reload
      
      @doc[:_attachments]['dup.png']['content_type'].should == 'image/png'
      @doc[:_attachments]['dup.png']['stub'].should == true
      (@doc[:_attachments]['my_file']['length'] > 0).should == true
      @doc[:_attachments]['my_file']['content_type'].should == 'image/png'
      @doc[:_attachments]['my_file']['stub'].should == true
      (@doc[:_attachments]['my_file']['length'] > 0).should == true
    end 
    
    it 'should be retrievable by a url' do
      @doc.delete! if @doc.exists?
      
      @doc.attachments.add(:my_file, @file)
      @doc.attachments.add("dup.png", @file)
      @doc.commit
      
      url = @doc.attachments.uri_for('dup.png')
      lambda{ CouchDB.get( url, true ) }.should_not raise_error
    end  
    
    it 'should save and retrieve the data correctly' do 
      @doc.delete! if @doc.exists?
      
      @doc.attachments.add(:my_file, @file)
      @doc.attachments.add("dup.png", @file)
      @doc.commit
      
      data = @file.read
      data.should_not be_nil
      data.should_not be_empty
      
      file = @doc.attachments.get!( :my_file ) 
      file.read.should == data
    end
    
    it 'should save and stream the data correctly' do 
      @doc.delete! if @doc.exists?
      
      @doc.attachments.add(:my_file, @file)
      @doc.attachments.add("dup.png", @file)
      @doc.commit
      
      data = @file.read
      data.should_not be_nil
      data.should_not be_empty
      
      streamed = @doc.attachments.get!( :my_file, true ) 
      streamed.should == data
    end
    
    it 'should have a class accessor for attachments' do 
      @doc.delete! if @doc.exists?
      
      @doc.attachments.add(:my_file, @file)
      @doc.attachments.add("dup.png", @file)
      @doc.commit 
      
      data = @file.read
      data.should_not be_nil
      data.should_not be_empty
      
      attachment = Document.attachment( @doc.id, 'my_file' ) 
      attachment.read.should == data
    end  
    
  end  
  
  describe 'design document' do
    it 'should not have a design document if there is no design_name' do
      Document.design_name.should be_nil
      Document.design_document.should be_nil
    end  
     
    it 'should create a design document if there is a design_name but the design document exists' do
      Document.design_name = 'User'
      lambda{ CouchDB::DesignDocument.get( 'User' ) }.should raise_error
      Document.design_document.should_not be_nil
      lambda{ CouchDB::DesignDocument.get( 'User') }.should_not raise_error 
    end
      
    it 'should retrieve a design document if there is a design_name and the design document exists' do
      CouchDB::DesignDocument.create!( :name => 'User' )
      # ensures that the record exists, before the real test
      lambda{ CouchDB::DesignDocument.get( 'User') }.should_not raise_error 
      Document.design_document.should_not be_nil
    end  
  end  
  
  describe 'indexing & queries' do
    Document.class_eval { attr_accessor( :my_field ) }
    
    it 'should have a class method "indexes" that stores map names related to the class' do
      Document.indexes.should == []
    end
    
    describe 'index_on' do
      before(:each) do
        Document.index_on(:my_field)
      end
        
      it 'should add text and symbol entries to indexes' do
        Document.indexes.size.should == 2
        Document.indexes.should include( :my_field )
        Document.indexes.should include( 'my_field' )
      end 
      
      it 'should not duplicate an index name' do
        # previous tests have already added it to the array 
        Document.indexes.size.should == 2 
      end 
      
      it 'should add a view to the design document' do
        design = Document.design_document(true)
        design.views.should include( :my_field )
      end  
    end
    
    describe 'queries' do
      # average/avg, minimum/mis, and maximum/max 
      
      before(:each) do
        Document.index_on(:my_field)
        (1..5).each do |number|
          Document.create!( :my_field => number * 5 )
        end  
      end 
       
      it 'should query full documents for an index' do
        docs = Document.query(:my_field) 
        docs.each{ |r| r.class.should == Document }
        docs.size.should == 5
      end
      
      it 'should query only the index value for an index' do 
        docs = Document.query(:my_field, :select => 'index only')
        docs.each{ |r| r.class.should == Fixnum }
      end
      
      it 'should generate a calculated/reduced view for an index the first time it is called' do
        Document.count(:my_field) 
        Document.design_document.views.should include( :my_field_count )
      end
      
      it 'should count an index' do 
        Document.count(:my_field).should == 5
      end 
      
      it 'should sum an index' do
        Document.sum(:my_field).should == 75
      end
      
      it 'should average an index' do 
        Document.average(:my_field).should == 15
      end 
      
      it 'should get the minimum of an index' do 
        Document.min(:my_field).should == 5
      end
      
      it 'should get the maximum of an index' do 
        Document.max(:my_field).should == 25
      end        
    
    end       
  end  

end