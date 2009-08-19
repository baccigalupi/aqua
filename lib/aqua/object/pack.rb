# This module is responsible for packing objects into Storage Objects
# The Storage Object is expected to be a Mash-Like thing (Hash with indifferent access).
# It is the job of the storage engine to convert the Mash into the actual storage data.
module Aqua::Pack
  
  def self.included( klass ) 
    klass.class_eval do
      extend ClassMethods
      include InstanceMethods
      
      # TODO: these should probably be protected as well as hidden
      attr_accessor   :_store, :__pack
      hide_attributes :_store, :__pack 
    end  
  end 
  
  module ClassMethods 
    # Used in class declaration to assign certain instance variables as not for persistance
    # @params [Symbol] or [Array of Symbols] ivars 
    # 
    # @example
    # class User 
    #   include Aqua::Object
    #   attr_accessor :username, :email, :password, :password_confirmation, :cryped_password, :salt
    #   hide_instance_variables :password, :password_confirmation 
    #   # ... lots more user code ...
    # end
    # In this case it is useful for omitting sensitive information while persisting the object, but 
    # maintaining the password and confirmation temporarily requires the use of instance variables.
    def hide_attributes( *ivars )
      ivars.each do |ivar|
        raise ArgumentError, '' unless ivar.class == Symbol
        _hidden_attributes << "@#{ivar}"
      end  
    end
    
    def _hidden_attributes 
      @_hidden_attributes ||= []
    end 
          
  end # ClassMethods
  
  module InstanceMethods
    # Saves object; returns false on failure; returns self on success.
    # option for transaction on children documents, all or nothing
    def commit(opts={}) 
      _commit
    end
    
    # Saves object and raises an error on failure
    def commit!
      _commit( false )
    end
    
    # these needs to be public so that nested objects can report on their specs during pack
    def _pack
      class_name = self.class.to_s
      self.__pack = Aqua::Storage.new
      self.__pack[:class] = class_name
      _pack_properties
      _pack_singletons
      __pack
    end
    
    def _embed_me 
      self.class._aqua_opts[:embed]
    end 
    
    def _storable_attributes
      (instance_variables||[]) - self.class._hidden_attributes
    end  
       
      
    
    # Private methods are all prefaced by an underscore to prevent
    # clogging the object instance space.
    private
      def _commit( mask_exception = true ) 
        result = true
        begin
          _pack
          _save_to_store
          _clear__pack 
        rescue Exception => e
          if mask_exception
            result = false
          else
            raise e
          end    
        end
        result ? self : result    
      end    
      
      def _pack_properties
        self.__pack[:properties] = _pack_ivars( self ) 
      end
      
      def _pack_ivars( obj )
        return_hash = {}
        obj._storable_attributes.each do |ivar_name|
          ivar = instance_variable_get( ivar_name ) 
          return_hash[ivar_name] = _pack_object( ivar ) unless ivar.nil?       
        end
        return_hash
      end  
      
      def _pack_object( obj ) 
        klass = obj.class
        if klass == String
          obj
        elsif [Time, Date, Integer, Bignum, Float, Fixnum].include?( klass )
          {
            'class' => klass,
            'value' => obj.to_s
          }
        elsif klass == Rational
          {
            'class' => klass,
            'value' => obj.to_s.match(/(\d*)\/(\d*)/).to_a.slice(1,2)
          } 
        elsif [Hash, Mash, HashWithIndifferentAccess].include?( klass )
          _pack_hash( obj )
        elsif klass == Array
          _pack_array( obj )
        else # a more complex object
          if (obj.aquatic? && obj._embed_me == true) || !obj.aquatic? 
            _pack_ivars( obj )  
          elsif obj._embed_me.class == Hash
            _stub( obj )
          else
            _store_to_external(obj)
          end       
        end           
      end   
      
      def _pack_hash( hash )
        return_hash = {}
        hash.each do |key, value|
          raise ArgumentError, 'Currently Hash keys must be either strings or symbols' unless [Symbol, String].include?( key.class )
          return_hash[key.to_s] = _pack_object( value )
        end
        return_hash  
      end
      
      def _pack_array( arr )
        return_arr = []
        arr.each do |obj|
          return_arr << _pack_object( obj )
        end
        return_arr   
      end    
      
      
      def _pack_singletons
        # TODO: figure out 1.8 and 1.9 compatibility issues. Also learn the library usage, without any docs :(
      end    
      
      def _save_to_store 
        # self._doc = Aqua::Document.new ...
        # _doc.commit # with exception catching et. al.
      end
      
      def _clear__pack
        self.__pack = nil
      end
              
    public  
  end # InstanceMethods     
  
end # Aqua::Pack 
  