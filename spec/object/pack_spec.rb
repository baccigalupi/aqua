require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require_fixtures

describe Aqua::Pack do 
  describe 'packing classes' do 
    it 'should pack class variables'
    it 'should pack class level instance variables'
    it 'should pack class definition'
    it 'should save all the class details to the design document'
    it 'should package views/finds in the class and save them to the design document\'s view attribute'
  end 
  
  describe 'packing up instances' do
    before(:each) do
      @user = User.new
      @user.name = ['Kane', 'Baccigalupi']
      @user.dob = Date.parse('12/23/69')
    end  

    it 'should pack all instance variables' do
      pack = @user.to_store
      pack[:properties].should_not be_nil
    end  

    it 'should save its class name as an attribute'
    it 'should determine the database a'
  end
  
  describe 'instances' do
    it 'simple attributes should be saved in record by default'
    it 'more complex attributes should be saved to their own database by default'
    it 'non-collection attributes should have options for saving internally, externally or stubbed'
    it 'should save singleton methods'
  end
  
  describe 'collections' do
    it 'collection attributes should have options for saving internally, externally or stubbed'
  end 
  
  it 'should recursively save complex objects'
  
  describe 'classes' do
    it 'should be saved into the design document' 
    it 'class declaration "persist" should take options for namespacing ... and other configuration options'
  end  
   
   
end  
