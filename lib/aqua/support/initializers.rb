# AQUA INITIALIZATION
# Some object store state in a fundamental way, not in instance variables, that needs to be initialized.
# Examples: Array, Numeric types, Hashes, Time ...
# You can make any object requiring this initialization savable to aqua by adding the following methods:
module Aqua
  module To
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
      self.to_s
    end
  end      
end 

[TrueClass, FalseClass, Time, Date, Fixnum, Bignum, Float, Rational, Hash, Array, OpenStruct].each do |klass|
  klass.class_eval do 
    include Aqua::To
  end
end     

class Rational
  def to_aqua_init( base_object ) 
    self.to_s.match(/(\d*)\/(\d*)/).to_a.slice(1,2)
  end
end

class Hash
  def to_aqua_init( base_object )
    return_hash = {}
    self.each do |raw_key, value|
      key_class = raw_key.class
      if key_class == Symbol
        key = ":#{raw_key.to_s}"
      elsif key_class == String
        key = raw_key
      else 
        index = base_object._build_object_key( raw_key )
        key = "/OBJECT_#{index}"
      end     
      return_hash[key] = base_object._pack_object( value ) 
    end
    return_hash  
  end
end

class Array
  def to_aqua_init( base_object )
    return_arr = []
    self.each do |obj|
      return_arr << base_object._pack_object( obj )
    end
    return_arr   
  end 
end

class OpenStruct
  def to_aqua_init( base_object )
    instance_variable_get("@table").to_aqua_init( base_object )
  end  
end    

    
  