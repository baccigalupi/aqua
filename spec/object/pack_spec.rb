require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require_fixtures

Aqua.set_storage_engine('CouchDB') # to initialize CouchDB
CouchDB = Aqua::Store::CouchDB unless defined?( CouchDB )

describe Aqua::Pack do
  
  def pack_grab_bag( value )
    @user.grab_bag = value
    @user._pack[:ivars][:@grab_bag]
  end  

  describe 'translator' do
    # the translator packs the object
    # then the translator passes back the attachments and the externals back to the pack/storage document
  end   
  
  describe 'hiding attributes' do
    before(:each) do
      build_user_ivars
    end  
      
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
      pack = @user._pack
      pack[:ivars].keys.should_not include("@password")
    end  
  end
  
  describe 'embed/stub reporting' do
    before(:each) do 
      build_user_ivars
    end
       
    describe '_embedded?' do
      it 'should be true for embedded objects' do 
        @log._embedded?.should == true
      end  
      it 'should be false for stubbed object with methods' do
        @user._embedded?.should == false
      end
        
      it 'should be false without stubbed methods, where :embed configuration is false' do
        p = Persistent.new
        p._embedded?.should == false 
      end 
    end
    
    describe '_stubbed_methods' do 
      it 'should be an empty for embedded objects (with no possible stubbed methods)' do
        @log._stubbed_methods.should == []
      end
      
      it 'should be an array the stub string or symbol method passed into configuration' do
        @user._stubbed_methods.should == [:username]
      end    
      
      it 'should be the array of the stub methods passed into configuration' do 
        User.configure_aqua :embed => { :stub => [:username, :name] }
        @user._stubbed_methods.should == [:username, :name]
        User.configure_aqua :embed => { :stub => :username } # resetting user model
      end   
    end
         
  end 
   
  # Most of the serious packing tests are in packer_spec
  # This is just to test/double-check that everything is working right withing an aquatic object
  describe "nesting" do
    before(:each) do 
      build_user_ivars
    end  
     
    describe 'embedded aquatics' do 
      it 'should pack an embedded object internally' do 
        @pack[:ivars]['@log'].should == {
          'class' => 'Log',
          'ivars' => {'@message' => @message, '@created_at' => Aqua::Translator.pack_object( @time ).pack }
        }
      end  
    end 
    
    describe 'externals' do 
      
      it 'should stub an external object' do 
        @pack[:ivars]['@other_user'].should == {
          'class' => 'Aqua::Stub',
          'init' => {'methods' => {'username' => 'strictnine' }, "class"=>"User", "id"=>""}
        }
      end
        
      it 'should commit the external when saving the base object' do
        @user.commit!
        @other_user.id.should_not be_nil
        @other_user.id.should_not == @other_user.object_id
      end  
      
      it 'should update the stubbed object id correctly' do
        @user.instance_eval "_commit_externals" 
        @other_user.id.should_not be_nil
        pack = @user._pack
        pack[:ivars]['@other_user']['init']['id'].should == @other_user.id
      end   
      
      describe 'transactions' do
        it 'should rollback all externals if an one external fails to commit'
        it 'should rollback all externals if the base object fails to commit'
      end  
    end 
  end 
  
  describe 'pack ids and revs' do 
    before(:each) do
      build_user_ivars
    end  
    
    it 'should have a _rev if it is present in the base object' do
      @user.instance_variable_set("@_rev", '1-2222222')
      pack = @user._pack 
      pack[:_rev].should == '1-2222222'
    end
    
    it 'should not have a _rev of nil if _rev is not provided in the base'  do 
      @pack[:_rev].should == nil
    end  
    
    it 'should initially have an id of nil' do 
      @pack[:_rev].should == nil
    end  
    
    it 'should pack the id if it exists in the base' do 
      @user.id = 'my_id'
      pack = @user._pack
      pack[:_id].should == 'my_id'
    end     
  end     
  
  describe 'commit' do 
    before(:each) do
      build_user_ivars 
      User::Storage.database.delete_all
    end
      
    it 'commit! should not raise errors on successful save' do  
      lambda{ @user.commit! }.should_not raise_error
    end 
    
    it 'commit! should raise error on failure' do
      CouchDB.should_receive(:put).at_least(:once).and_return( CouchDB::Conflict )
      lambda{ @user.commit! }.should raise_error
    end  
    
    it 'commit! should assign an id back to the object' do
      @user.commit!
      @user.id.should_not be_nil
      @user.id.should_not == @user.object_id
    end
    
    it 'commit! should assign the _rev to the parent object' do
      @user.commit!
      @user.instance_variable_get('@_rev').should_not be_nil
    end    
    
    it 'commit! should save the record to CouchDB' do  
      @user.commit!  
      lambda{ CouchDB.get( "http://127.0.0.1:5984/aqua/#{@user.id}") }.should_not raise_error
    end
    
    it 'commit should save the record and return self' do 
      @user.commit.should == @user
    end
    
    it 'commit should not raise an error on falure' do 
      CouchDB.should_receive(:put).at_least(:once).and_return( CouchDB::Conflict )
      lambda{ @user.commit }.should_not raise_error
    end 
    
    it 'commit should return false on failure' do
      CouchDB.should_receive(:put).at_least(:once).and_return( CouchDB::Conflict )
      @user.commit.should == false
    end
    
    it 'should be able to update and commit again without conflict' do
      @user.commit!
      @user.grab_bag = {'1' => '2'}
      lambda{ @user.commit! }.should_not raise_error
    end        
  end  
  
  describe 'classes' do
    it 'should have a separate database' 
  end 
 
end  
