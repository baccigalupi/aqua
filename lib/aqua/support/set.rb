# require this file if you want to use sets with your Aquatic objects
require 'set'

class Set 
  # implements initialization in a way that works provided that init is an array 
  extend Aqua::From
  
  # implements #to_aqua correctly, we will have to rewrite #to_aqua_init to return an array
  include Aqua::From 
  
  def to_aqua( base_object )
    hash = { 
      'class' => self.class.to_s, 
      'init' => to_aqua_init( base_object ) 
    }
    if instance_variables.size > 0 
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