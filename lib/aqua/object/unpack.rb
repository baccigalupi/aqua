module Aqua::Unpack
  
  def self.included( klass ) 
    klass.class_eval do
      extend ClassMethods
      include InstanceMethods
    end  
  end 
  
  module ClassMethods
  end
  
  module InstanceMethods 
    # repacking notes for numbers
    # Integer:  Integer( value )
    # Fixnum:   eval( value )
    # Bignum:   eval( value )
    # Float:    Float( value )
    # Rational: Rational( value[0], value[1])
  end

end       