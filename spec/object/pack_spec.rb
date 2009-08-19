require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require_fixtures

describe Aqua::Pack do
  before(:each) do
    @user = User.new
    @user.username = 'kane'
    @user.name = ['Kane', 'Baccigalupi']
    @user.dob = Date.parse('12/23/69')
    @pack = @user.to_store
  end   
  
  describe 'packing classes' do 
    it 'should pack class variables'
    it 'should pack class level instance variables'
    it 'should pack class definition'
    it 'should save all the class details to the design document'
    it 'should package views/finds in the class and save them to the design document\'s view attribute'
    it 'should be saved into the design document' 
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
  end    
  
  describe 'packing up instances' do
    it 'should save its class name as an attribute on the pack document' do
      @pack[:class].should == 'User'
    end
    
    describe 'instance variables' do
      it 'should be in a hash-like object with the key :properties' do 
        @pack[:properties].should_not be_nil
        @pack[:properties].should respond_to(:keys)
      end 
        
      describe 'simple conversions' do 
        it 'should pack strings as strings' do 
          @pack[:properties][:@username].should == 'kane'
        end  
    
        it 'should pack an array of strings an Array of String objects' do
          @pack[:properties][:@name].should == ['Kane', 'Baccigalupi']
        end  
    
        it 'should pack hashes as a Hash of keys and' 
      end
      
      describe 'packing objects'  
    end
    
  end
   
end  
