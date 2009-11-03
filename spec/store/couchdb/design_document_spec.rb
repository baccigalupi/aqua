require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

Aqua.set_storage_engine('CouchDB') # to initialize the Aqua::Store namespace

# Conveniences for typing with tests ... 
CouchDB =   Aqua::Store::CouchDB unless defined?( CouchDB ) 
Database =  CouchDB::Database unless defined?( Database )
Server =    CouchDB::Server unless defined?( Server )
Design =    CouchDB::DesignDocument unless defined?( Design )
ResultSet =    CouchDB::ResultSet unless defined?( ResultSet ) 

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
    before(:each) do
      ResultSet.document_class = Document
    end
      
    it 'should be a Hash-like object' do 
      @design.views.should == Mash.new
    end
    
    describe '<<, add, add!' do
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
        
        it 'should autogenerate a generic map with class constraints' do
          @design << {:name => 'my_docs', :class_constraint => Document}
          @design.views[:my_docs][:map].should match(/doc\['type'\] == 'Document'/)
        end
        
        it 'should autogenerate a generic map and insert preformed class constraints' do
          @design << {:name => 'user', :class_constraint => "doc['class'] == 'User'" }
          @design.views[:user][:map].should match(/doc\['class'\] == 'User'/)
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
      
      it 'add should act like <<' do
        @design.add :name => 'my_attribute', :map => 'not the generic'
        @design.views[:my_attribute][:map].should == 'not the generic'
      end
      
      it 'add! should save after adding the view' do
        @design.add! :name => 'my_attribute', :map => 'not the generic'
        lambda{ Design.get( @design.name ) }.should_not raise_error
        design = Design.get( @design.name )
        design.views.keys.should include( 'my_attribute' )
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
        @docs.size.should == 10
      end
      
      it 'should return the documents themselves by default' do
        @docs = @design.query( :index )
        @docs.first.keys.should include( 'index' )
        @docs.first.class.should == Document
      end
      
      it 'should limit query results' do
        @docs = @design.query( :index, :limit => 2 )
        @docs.size.should == 2
      end
      
      it 'should offset query results' do
        @docs = @design.query( :index, :limit => 2, :offset => 2)
        @docs.size.should == 2
        @docs.first[:index].should == 3
      end
      
      it 'should put in descending order' do
        @docs = @design.query( :index, :order => :desc )
        @docs.first[:index].should == 10
      end
      
      it 'should select a range' do
        @docs = @design.query( :index, :range => [2,4])
        @docs.size.should == 3
        @docs.first[:index].should == 2
      end
      
      it 'should select a range with descending order' do
        @docs = @design.query( :index, :range => [2,4], :order => :descending )
        @docs.size.should == 3
        @docs.first[:index].should == 4
        @docs[2][:index].should == 2 
      end
      
      it 'should select by exact key' do 
        @docs = @design.query( :index, :equals => 3 )
        @docs.size.should == 1
        @docs.first[:index].should == 3
      end                 
    end  
  end     
end  