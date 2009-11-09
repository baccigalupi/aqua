# require this file if you want to use sets with your Aquatic objects
require 'set'

class Set 
  include Aqua::Initializers 
  hide_attributes :hash 
  
  def to_aqua_init( path='' )
    Aqua::Packer.pack_object( instance_variable_get("@hash").keys )
  end    
end  