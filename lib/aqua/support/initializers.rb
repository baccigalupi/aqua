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
        rat = Rat.new( { 'class' => to_aqua_class } ) 
        
        init_rat = to_aqua_init( path )
        rat.hord(init_rat, 'init')  
        
        ivar_rat = _pack_instance_vars( path )
        rat.eat( ivar_rat ) if ivar_rat && ivar_rat.pack['ivars'] && !ivar_rat.pack['ivars'].empty?
          
        rat
      end
      
      def to_aqua_class
        self.class.to_s
      end  
      
      def _pack_instance_vars( path )
        rat = Rat.new
        ivar_rat = Packer.pack_ivars( self )
        ivar_rat.pack.empty? ? rat : rat.hord( ivar_rat, 'ivars' ) 
      end  
  
      def to_aqua_init( path )
        Rat.new( self.to_s ) 
      end 
    end # InstanceMethods
    
    module ClassMethods 
      def aqua_init( init ) 
        new( init )
      end    
    end # ClassMethods   
    
  end # Initializers
         
end  

[ TrueClass, FalseClass, Symbol, Time, Date, Fixnum, Bignum, Float, Rational, Hash, Array, OpenStruct, Range, File, Tempfile, String, NilClass].each do |klass|
  klass.class_eval { include Aqua::Initializers }
end 

class String
  def to_aqua( path='' )
    Aqua::Rat.new( self )
  end 
end 

class TrueClass
  def self.aqua_init( init )
    true
  end
  
  def to_aqua( path='')
    Aqua::Rat.new( true )
  end 
end

class FalseClass
  def self.aqua_init( init )
    false
  end
  
  def to_aqua( path='' )
    Aqua::Rat.new( false )
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
    Aqua::Rat.new( self.to_s.match(/(\d*)\/(\d*)/).to_a.slice(1,2) )
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
    rat = Aqua::Rat.new
    self.each do |raw_key, value|
      key_class = raw_key.class
      if key_class == String
        key = raw_key
      else # key is an object 
        index = next_object_index( rat.pack )  
        key = self.class.aqua_object_key_index( index )
        key_rat = Aqua::Packer.pack_object( raw_key, path+"['#{self.class.aqua_key_register}'][#{index}]")
        rat.hord( key_rat, [self.class.aqua_key_register, index] )
      end
      obj_rat = Aqua::Packer.pack_object( value, path+"['#{key}']" )
      rat.hord( obj_rat, key )
    end
    rat 
  end
  
  def self.aqua_key_register
    "/_OBJECT_KEYS".freeze
  end
  
  def self.aqua_object_key_index( index ) 
    "/_OBJECT_#{index}"
  end    
  
  def next_object_index( hash )
    hash[self.class.aqua_key_register] ||= []
    hash[self.class.aqua_key_register].size
  end  
  
  def self.aqua_init( init )
    new.replace( init )
  end 
end

class Array
  def to_aqua_init( path = '' )
    rat = Aqua::Rat.new([])
    self.each_with_index do |obj, index|
      local_path = path + "[#{index}]" 
      obj_rat = Aqua::Packer.pack_object( obj, local_path )
      rat.eat( obj_rat )  
    end
    rat   
  end
  
  def self.aqua_init( init )
    new.replace( init )
  end 
end

class OpenStruct
  hide_attributes :table
  
  def to_aqua_init( path='' ) 
    instance_variable_get("@table").to_aqua_init( path )
  end  
end 

module Aqua
  module FileInitializations 
    def to_aqua( path='' )
      rat = Aqua::Rat.new(
        { 
          'class' => to_aqua_class,
          'init' => filename, 
          'methods' => {
            'content_type' => content_type,
            'content_length' => content_length
          } 
        }, {}, [self]
      )
        
      ivar_rat = _pack_instance_vars( path )
      rat.eat( ivar_rat ) if ivar_rat && ivar_rat.pack['ivars'] && !ivar_rat.pack['ivars'].empty?
          
      rat 
    end
    
    def content_length 
      if len = stat.size
        rat = Aqua::Packer.pack_object( len )
        rat.pack
      else
        ''
      end  
    end 
    
    def content_type 
      mime = MIME::Types.type_for( self.path )
      mime && mime.first ? mime.first.to_s : ''
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