require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require_fixtures

describe Aqua::Config do
  it 'should add a class method used in class declaration for configuring called "configure_aqua"' do 
    User.should respond_to( :configure_aqua )
  end 
  
  describe 'storage class' do
    it 'should be establish on aquatic declaration' do 
      lambda{ User::Storage }.should_not raise_error 
    end
    
    it 'should store the parent class' do
      User::Storage.parent_class.should == 'User'
    end     
  end 
  
  it 'should set default configuration options on module load' do 
    opts = Persistent.aquatic_options
    opts.should_not be_nil
    Persistent::Storage.database.uri.should == "http://127.0.0.1:5984/aqua" # default when database option is nil
    opts[:embed].should be_false
  end
  
  it 'should be able to add to the default configurations' do 
    User.class_eval do
      configure_aqua :database => 'someplace_else', :embed => { :stub => [:username] } 
    end
    opts = User.aquatic_options 
    User::Storage.database.name.should == 'someplace_else'
    opts[:embed].should_not be_false
    opts[:embed][:stub].class.should == Array
  end
  
  it 'should be able to add to already custom configured options' do
    opts = User.aquatic_options 
    User::Storage.database.name.should == 'someplace_else' # make sure it is held over from the last test
    User.class_eval do
      configure_aqua :database => 'newer_than_that' 
    end 
    opts = User.aquatic_options 
    User::Storage.database.name.should == 'newer_than_that'
    opts[:embed].should_not be_false
    opts[:embed][:stub].class.should == Array 
  end 
  
  it 'should receive options passed to the class "aquatic" declaration' do
    opts = Log.aquatic_options
    opts[:embed].should == true
  end 
  
  it 'each class should have different Storage class options' do
    Persistent::Storage.database.should_not == User::Storage.database
  end  
   
end  
   
