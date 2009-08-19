require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require_fixtures

describe Aqua::Tank do 
  it 'should add the class method :aquatic to all objects' do
    Object.should respond_to( :aquatic )
    User.should respond_to(:aquatic)
  end
  
  it 'should add the class method :super_aquatic to all objects'
  
  describe 'declaring a class as aquatic' do
    it 'should add pack methods to the class and its instances' do 
      Log.should respond_to(:hide_attributes)
      Log.new.should respond_to(:commit)
    end
      
    it 'should add unpack methods to the class and its instances'
    
    it 'should add configuration methods to the class' do
      Log.should respond_to(:configure_aqua)
    end  
    
    it 'should add query methods to the class and its instances'
  end
  
  describe 'including Aqua::Pack on the class' do 
    it 'should add pack methods to the class and its instances' do 
      User.should respond_to(:hide_attributes)
      User.new.should respond_to(:commit)
    end
      
    it 'should add unpack methods to the class and its instances'
    
    it 'should add configuration methods to the class' do
      User.should respond_to(:configure_aqua)
    end  
    
    it 'should add query methods to the class and its instances' 
  end    
    
end  
      