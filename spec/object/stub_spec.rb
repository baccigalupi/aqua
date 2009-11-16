require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require_fixtures
 
Aqua.set_storage_engine('CouchDB') # to initialize CouchDB
CouchDB = Aqua::Store::CouchDB unless defined?( CouchDB )

describe Aqua::Stub do
  before(:each) do 
    @params = {
      :id => 'my_great_id',
      :class => 'Gerbilmiester',
      :methods => {
        :gerbil => true,
        :bacon => 'chunky'
      }
    }
    @stub = Aqua::Stub.new( @params )
  end  
    
  describe 'initialization' do
    it 'should initialize the delegate id' do
      @stub.instance_eval('delegate_id').should == 'my_great_id'
    end
      
    it 'should initialize the delegate class' do  
      @stub.instance_eval('delegate_class').should == 'Gerbilmiester'
    end
    
    # This stuff is just scoped out for future use. I would like to have a stub know where it exists
    # in its parent object and be able to replace itself instead of loading a delegate. 
    it 'should have a parent object'
    it 'should have a path from parent to self'   
  end
  
  describe 'delegation' do 
    it 'should return correct values for initialized methods' do
      Gerbilmiester.should_not_receive(:load) 
      @stub.gerbil.should == true
      @stub.bacon.should == 'chunky'
    end
    
    it 'should try to retrieve an object if an unspecified method is called' do 
      Gerbilmiester.should_receive(:load).and_return( Gerbilmiester.new )
      @stub.herd
    end 
    
    it 'should return correct values for new delegate' do 
      Gerbilmiester.should_receive(:load).and_return( Gerbilmiester.new )
      @stub.herd.should == 'Yah, yah, little gerbil'
    end   
  end     
end 