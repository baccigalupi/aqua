require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require_fixtures

Aqua.set_storage_engine('CouchDB') # to initialize CouchDB
CouchDB = Aqua::Store::CouchDB unless defined?( CouchDB )

describe Aqua::Pack do
  before(:each) do
    @time = Time.now
    @date = Date.parse('12/23/1969')
    @log = Log.new( :message => "Hello World! This is a log entry", :created_at => Time.now )
    @user = User.new(
      :username => 'kane',
      :name => ['Kane', 'Baccigalupi'],
      :dob => @date,
      :created_at => @time,
      :log => @log,
      :password => 'my secret!' 
    )
    
    def pack_grab_bag( value )
      @user.grab_bag = value
      @user._pack[:ivars][:@grab_bag]
    end 
  end
  
  describe 'packer' do
    # the packer packs the object
    # then the packer passes back the attachments and the externals back to the pack/storage document
  end   
  
  describe 'hiding attributes' do
    it 'should add a class method for designating hidden instance variables' do
      User.should respond_to( :hide_attributes )
    end
    
    it 'class method should hide instance variables designated by the user as hidden' do
      @user.visible_attr.should_not include('@password')
      @user.class._hidden_attributes.should include('@password')
    end 
      
    it 'should hide the @__pack variable' do
      @user.visible_attr.should_not include('@__pack') 
      @user.class._hidden_attributes.should include('@__pack')
    end    
  
    it 'should hide the @_store variable' do 
      @user.visible_attr.should_not include('@_store')
      @user.class._hidden_attributes.should include('@_store')
    end
    
    it 'should not pack hidden variables' do
      @pack = @user._pack
      @pack[:ivars].keys.should_not include("@password")
    end  
  end
   
  # Most of the serious packing tests are in packer_spec
  describe "nesting" do 
    describe 'embedded aquatics' do
      it 'should pack an embedded object internally' 
    end
    describe 'externals' do
      it 'should stub an external object'
      it 'should commit the external when saving the base object' 
      it 'should update the stubbed object id after the external is saved' 
      describe 'transactions' do
        it 'should rollback all externals if an one external fails to commit'
        it 'should rollback all externals if the base object fails to commit'
      end  
    end 
  end 
  
  describe 'ids and revs' do 
    before(:each) do
      @pack = @user._pack
    end  
    
    it 'should pack the _rev if it is present' do
      @user.instance_variable_set("@_rev", '1-2222222')
      pack = @user._pack 
      pack[:_rev].should == '1-2222222'
    end
    
    it 'should not have a _rev of nil if not _rev is provided' 
    
    it 'should generate an id if the id is not provided'
    
    it 'should pack the id provided'   
  end     
  
  
  describe 'commit' do 
    before(:each) do 
      User::Storage.database.delete_all
    end
      
    it 'commit! should not raise errors on successful save' do  
      pending
      lambda{ @user.commit! }.should_not raise_error
    end 
    
    it 'commit! should raise error on failure' do
      pending
      CouchDB.should_receive(:put).at_least(:once).and_return( CouchDB::Conflict )
      lambda{ @user.commit! }.should raise_error
    end  
    
    it 'commit! should assign an id back to the object' do
      pending
      @user.commit!
      @user.id.should_not be_nil
      @user.id.should_not == @user.object_id
    end
    
    it 'commit! should assign the _rev to the parent object' do
      pending
      @user.commit!
      @user.instance_variable_get('@_rev').should_not be_nil
    end    
    
    it 'commit! should save the record to CouchDB' do  
      pending
      @user.commit!  
      lambda{ CouchDB.get( "http://127.0.0.1:5984/aqua/#{@user.id}") }.should_not raise_error
    end
    
    it 'commit should save the record and return self' do 
      pending
      @user.commit.should == @user
    end
    
    it 'commit should not raise an error on falure' do 
      pending
      CouchDB.should_receive(:put).at_least(:once).and_return( CouchDB::Conflict )
      lambda{ @user.commit }.should_not raise_error
    end 
    
    it 'commit should return false on failure' do
      pending
      CouchDB.should_receive(:put).at_least(:once).and_return( CouchDB::Conflict )
      @user.commit.should == false
    end
    
    it 'should be able to update and commit again' do
      pending 
      @user.commit!
      @user.grab_bag = {'1' => '2'}
      lambda{ @user.commit! }.should_not raise_error
    end        
  end  
  
  
  describe 'packing classes' do 
    it 'should pack class variables'
    it 'should pack class level instance variables'
    it 'should pack class definition'
    it 'should save all the class details to the design document'
    it 'should package views/finds in the class and save them to the design document\'s view attribute'
    it 'should be saved into the design document' 
  end 
 
end  
