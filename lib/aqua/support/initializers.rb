# AQUA INITIALIZATION
# Some object store state in a fundamental way, not in instance variables, that needs to be initialized.
# Examples: Array, Numeric types, Hashes, Time ...
# You can make any object requiring this initialization savable to aqua by
#  * including the Aqua::To module and extending the Aqua::From module
#  * building your own methods for #to_aqua, #to_aqua_init, MyClass.aqua_init
# See set.rb in this file for more an example
module Aqua
  module Initializers 
    def self.included( klass ) 
      klass.class_eval do
        include InstanceMethods
        extend ClassMethods
        
        unless methods.include?( :hide_attributes )
          include Aqua::Pack::HiddenAttributes
        end
      end
    end
    
    module InstanceMethods 
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
    end # InstanceMethods
    
    module ClassMethods 
      def aqua_init( init ) 
        new( init )
      end    
    end # ClassMethods   
    
  end # Initializers
         
end  

[ TrueClass, FalseClass, Time, Date, Fixnum, Bignum, Float, Rational, Hash, Array, OpenStruct, Range].each do |klass|
  klass.class_eval { include Aqua::Initializers }
end 

class TrueClass
  def self.aqua_init( init )
    true
  end
  
  def to_aqua( base_object )
    true
  end 
end

class FalseClass
  def self.aqua_init( init )
    false
  end
  
  def to_aqua( base_object )
    false
  end
end   

class Date
  hide_attributes :sg, :of, :ajd
  
  def self.aqua_init( init )
    parse( init )
  end
end

class Time 
  def self.aqua_init( init )
    parse( init )
  end
end

class Fixnum
  def self.aqua_init( init )
    init.to_i
  end
end

class Bignum
  def self.aqua_init( init )
    init.to_i
  end
end  
   
class Float
  def self.aqua_init( init )
    init.to_f
  end
end 

class Range
  def self.aqua_init( init ) 
    eval( init )
  end
end     

class Rational
  def to_aqua_init( base_object ) 
    self.to_s.match(/(\d*)\/(\d*)/).to_a.slice(1,2)
  end 
  
  def self.aqua_init( init )
    Rational( init[0].to_i, init[1].to_i )
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
  
  def self.aqua_init( init )
    new.replace( init )
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
  
  def self.aqua_init( init )
    new.replace( init )
  end 
end

class OpenStruct
  hide_attributes :table
  
  def to_aqua_init( base_object )
    instance_variable_get("@table").to_aqua_init( base_object )
  end  
end    