require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require_fixtures

describe Aqua::Config do
  it 'should add a class method used in class declaration for configuring called "configure_aqua"' do 
    User.should respond_to( :configure_aqua )
  end  
   
end  
   
