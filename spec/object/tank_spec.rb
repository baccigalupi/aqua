require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require_fixtures

describe Aqua::Tank do 
  it 'should add the class method :aquatic to all objects' do
    Object.should respond_to( :aquatic )
    User.should respond_to(:aquatic)
  end
  
  it 'should add an instance method :aquatic? that identifies whether an object is aquatic' do 
    Object.new.should respond_to( :aquatic? )
    Object.new.should_not be_aquatic
    User.new.should be_aquatic
  end
  
  it 'should add class method :aquatic? that identifies whether a class is aquatic' do
    Object.should respond_to( :aquatic? )
    Object.should_not be_aquatic
    User.should be_aquatic
  end    
  
  it 'should add the class method :super_aquatic to all objects'
  
  describe 'declaring a class as aquatic' do
    it 'should add pack methods to the class and its instances' do 
      Log.should respond_to(:transient_attr)
      Log.new.should respond_to(:commit)
    end
      
    it 'should add unpack methods to the class and its instances' do 
      Log.should respond_to( :load )
      Log.new.should respond_to( :reload )
    end  
    
    it 'should add configuration methods to the class' do
      Log.should respond_to(:configure_aqua)
    end  
    
    it 'should add query methods to the class and its instances'
  end
  
  describe 'including Aqua::Pack on the class' do 
    it 'should add pack methods to the class and its instances' do 
      Persistent.should respond_to(:transient_attr)
      Persistent.new.should respond_to(:commit)
    end
      
    it 'should add unpack methods to the class and its instances' do 
      Persistent.should respond_to( :load )
      Persistent.new.should respond_to( :reload )
    end  
    
    it 'should add configuration methods to the class' do
      Persistent.should respond_to( :configure_aqua )
    end  
    
    it 'should add query methods to the class and its instances' 
  end    
    
end  
      