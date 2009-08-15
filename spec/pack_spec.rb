require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
# require_fixtures

describe Persist::Pack do 
  describe 'packing classes' do 
    it 'should pack class variables'
    it 'should pack class level instance variables'
    it 'should pack class definition'
    it 'should save all the class details to the design document'
    it 'should package views/finds in the class and save them to the design document\'s view attribute'
  end 
  
  describe 'packing up instances' do
    describe 'database' do 
      it 'should determine the database from the class name'
      it 'should save the class name'
    end  
    it 'should pack all instance variables'
    it 'should save its class name as an attribute'
    it 'should determine the database a'
  end 
   
end  
