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
      def to_aqua( path = '' )
        hash = { 'class' => to_aqua_class }
        externals = {}
        attachments = []
        
        if init = to_aqua_init( path )
          hash.merge!( 'init' => init[0] )
          externals.merge!(init[1]) unless init[1].empty?
          attachments += init[2]
        end
             
        ivar_arr = _pack_instance_vars( path )
        if ivar_arr && ivar_arr.first.size > 0
          hash.merge!( ivar_arr[0] ) 
          externals.merge!( ivar_arr[1] ) unless ivar_arr[1].empty?
          attachments += ivar_arr[2]
        end
          
        [hash, externals, attachments]
      end
      
      def to_aqua_class
        self.class.to_s
      end  
      
      def _pack_instance_vars( path )
        arr = Packer.pack_ivars( self ) 
        arr && arr.first.size > 0 ? [{ 'ivars' => arr[0] }, arr[1], arr[2]] : [{}, [], []]
      end  
  
      def to_aqua_init( path ) 
        [self.to_s, {}, []]
      end 
    end # InstanceMethods
    
    module ClassMethods 
      def aqua_init( init ) 
        new( init )
      end    
    end # ClassMethods   
    
  end # Initializers
         
end  

[ TrueClass, FalseClass, Symbol, Time, Date, Fixnum, Bignum, Float, Rational, Hash, Array, OpenStruct, Range, File, Tempfile, String].each do |klass|
  klass.class_eval { include Aqua::Initializers }
end 

class String
  def to_aqua( path='' )
    [ self, {} , [] ]
  end 
end 

class TrueClass
  def self.aqua_init( init )
    true
  end
  
  def to_aqua( path='')
    [true,{},[]]
  end 
end

class FalseClass
  def self.aqua_init( init )
    false
  end
  
  def to_aqua( path='' )
    [false,{},[]]
  end
end   

class Symbol 
  def self.aqua_init( init )
    init.to_sym
  end
  
  def _pack_instance_vars( path='')
    nil
  end 
end  

class Date
  hide_attributes :sg, :of, :ajd
  
  def self.aqua_init( init )
    parse( init )
  end 
  
  def _pack_instance_vars( path='')
    nil
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
  def to_aqua_init( path='') 
    [self.to_s.match(/(\d*)\/(\d*)/).to_a.slice(1,2), {}, []]
  end 
  
  def self.aqua_init
    Rational( init[0].to_i, init[1].to_i )
  end
  
  def _pack_instance_vars( path='')
    nil
  end       
end

class Hash
  def to_aqua_init( path='')
    return_hash = {}
    externals = {}
    attachments = []
    self.each do |raw_key, value|
      key_class = raw_key.class
      if key_class == Symbol
        key = ":#{raw_key.to_s}"
      elsif key_class == String
        key = raw_key
      else # key is an object
        key = Packer.build_object_key( raw_key ) 
        index = next_object_index(return_hash)  
        return_hash["/_OBJECT_KEYS"][index] = key
        key = "/_OBJECT_#{index}"
      end     
      return_hash[key] = Aqua::Packer.pack_object( value ) 
    end
    [return_hash, externals, attachments]  
  end
  
  def next_object_index( hash )
    hash["/_OBJECT_KEYS"] ||= []
    hash["/_OBJECT_KEYS"].size
  end  
  
  def self.aqua_init( init )
    new.replace( init )
  end 
end

class Array
  def to_aqua_init( path = '' )
    return_arr = []
    externals = {}
    attachments = []
    self.each_with_index do |obj, index|
      local_path = path + "[#{index}]" 
      pack_arr = Aqua::Packer.pack_object( obj, local_path )
      if pack_arr
        return_arr  << pack_arr[0]
        externals.merge!( pack_arr[1] ) unless pack_arr[1].empty?
        attachments += pack_arr[2]
      end  
    end
    [return_arr, externals, attachments]   
  end
  
  def self.aqua_init( init )
    new.replace( init )
  end 
end

class OpenStruct
  hide_attributes :table
  
  def to_aqua_init
    [instance_variable_get("@table").to_aqua_init, {}, []]
  end  
end 

module Aqua
  module FileInitializations 
    def to_aqua( base_object )
      hash = { 
        'class' => to_aqua_class, 
        'init' => to_aqua_init,
        'methods' => {
          'content_type' => MIME::Types.type_for( path ).first,
          'content_length' => stat.size
        } 
      }
      ivars = _pack_instance_vars( base_object )
      hash.merge!( ivars ) if ivars
      hash
    end  
    
    def to_aqua_class
      'Aqua::FileStub'
    end   
       
    def filename
      path.match(/([^\/]*)\z/).to_s
    end
    
    def to_aqua_init
      name = filename
      base_object._pack_file(name, self)
      "/FILE_#{name}"      
    end  
  end # FileInitializations
end # Aqua
   
class File
  include Aqua::FileInitializations        
end

class Tempfile
  include Aqua::FileInitializations
  
  hide_attributes :clean_proc, :data, :tmpname, :tmpfile, :_dc_obj
  
  def filename
    path.match(/([^\/]*)\.\d*\.\d*\z/).captures.first
  end
end       