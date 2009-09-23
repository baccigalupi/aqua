# require this file if you want to use sets with your Aquatic objects
require 'set'

class Set 
  include Aqua::Initializers  
  
  def to_aqua( base_object )
    hash = { 
      'class' => self.class.to_s, 
      'init' => to_aqua_init( base_object ) 
    }
    if (instance_variables - ['@hash']).size > 0 
      hash.merge!({ 'ivars' => base_object._pack_ivars( self ) })
    end
    hash
  end   

  def to_aqua_init( base_object )
    # keys returns an array
    # to_aqua_init will ensure that each of the objects is unpacked to aqua 
    instance_variable_get("@hash").keys.to_aqua_init( base_object )
  end    
end  