require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

Aqua.set_storage_engine('CouchDB') # to initialize the Aqua::Store namespace

# Conveniences for typing with tests ... 
CouchDB =   Aqua::Store::CouchDB unless defined?( CouchDB ) 
Database =  CouchDB::Database unless defined?( Database )
Server =    CouchDB::Server unless defined?( Server )
Design =    CouchDB::DesignDocument unless defined?( Design )

require File.dirname(__FILE__) + '/fixtures_and_data/document_fixture' # Document ... a Mash with the collection of methods

describe CouchDB::DesignDocument do 
  before(:each) do
    Aqua::Storage.database.delete_all
    @name = 'User'
    @design = Design.new(:name => @name)
  end  
    
  describe 'new and create' do
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
  
  it 'should get a design document by name' do
    @design.save!
    lambda{ Design.get( @name ) }.should_not raise_error
  end  
  
  describe 'views' do
    it 'should be a Hash-like object' do 
      @design.views.should == Mash.new
    end
    
    describe '<<' do
      describe 'string as argument' do
        it 'should add a view with the right name' do
          @design << 'my_attribute'
          @design.views.keys.should == ['my_attribute']
        end
      
        it 'should autogenerate a generic map' do
          @design << 'my_attribute'
          @design.views[:my_attribute][:map].should match(/function\(doc\)/)
          @design.views[:my_attribute][:map].should match(/emit/)
        end
      
        it 'should not autogenerate a reduce function' do
          @design << 'my_attribute'
          @design.views[:my_attribute][:reduce].should be_nil
        end 
      end
      
      describe 'hash options as argument' do 
        it 'should add a view named with the options name key' do 
          @design << {:name => 'my_attribute'}
          @design.views.keys.should == ['my_attribute']
        end
        
        it 'should autogenerate a generic map' do
          @design << {:name => 'my_attribute'}
          @design.views[:my_attribute][:map].should match(/function\(doc\)/)
          @design.views[:my_attribute][:map].should match(/emit/)
        end
        
        it 'should not autogenerate a reduce function' do
          @design << {:name => 'my_attribute'}
          @design.views[:my_attribute][:reduce].should be_nil
        end
        
        it 'should apply a map option when provided' do
          @design << {:name => 'my_attribute', :map => 'not the generic'}
          @design.views[:my_attribute][:map].should == 'not the generic'
        end
        
        it 'should apply a reduce option when provided' do
          @design << {:name => 'my_attribute', :reduce => 'I exist!'}
          @design.views[:my_attribute][:map].should match(/function\(doc\)/)
          @design.views[:my_attribute][:map].should match(/emit/) 
          @design.views[:my_attribute][:reduce].should == 'I exist!'
        end      
      end    
    end 
  
    describe 'query' do
      before(:each) do
        (1..10).each do |num| 
          Document.create!( :index => num )
        end
        @design << :index
        @design.save!  
      end
         
      it 'should query by saved view' do
        lambda{ @design.query( :index ) }.should_not raise_error
      end 
      
      it 'should return a number of rows corresponding to all the documents in the query' do
        @docs = @design.query( :index )
        @docs[:rows].size.should == 10
      end
      
      it 'should return the documents themselves by default' do
        @docs = @design.query( :index )
        @docs[:rows].first[:doc].keys.should include( 'index' )
      end     
    end  
  end    
  
  
end  