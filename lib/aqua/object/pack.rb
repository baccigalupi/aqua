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
    
    # Reader method for accessing hidden attributes. 
    # @return [Array] containing strings representing instance variables
    def _hidden_attributes 
      @_hidden_attributes ||= []
    end 
          
  end # ClassMethods
  
  module InstanceMethods
    # TODO: option for transaction on children documents, all or nothing
    
    # Saves object; returns false on failure; returns self on success.
    def commit 
      _commit
    end
    
    # Saves object and raises an error on failure
    def commit!
      _commit( false )
    end
    
    # packs an object from it's Ruby state into a Hash-like object for storage. 
    # @return [Aqua::Storage]
    #
    # @api private
    def _pack
      class_name = self.class.to_s
      self.__pack = Aqua::Storage.new
      self.__pack[:class] = class_name
      _pack_properties
      _pack_singletons
      __pack
    end
    
    # Details from configuration options for the objects class about embedability. 
    # @return [true, false, Hash] If true then it should be embedded in the object at hand. 
    #   If false, then it should be saved externally. If a hash, with the key :stub and a related
    #   value that is an array of methods, then the object should be saved externally, 
    #   with a few cached methods as defined in the array.
    # 
    # @api private
    def _embed_me 
      self.class._aqua_opts[:embed]
    end 
    
    # An array of instance variables that are not hidden.
    # @return [Array] of names for instance variables
    # 
    # @api private
    def _storable_attributes
      (instance_variables||[]) - self.class._hidden_attributes
    end  
       
    
    # Private methods are all prefaced by an underscore to prevent
    # clogging the object instance space. Some of the public ones above are too!
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
       
      # Object packing methods ------------
      
      # Recursively examines each ivar and converts it to a hash, array, string combo
      # @api private
      def _pack_properties
        self.__pack[:data] = _pack_ivars( self ) 
      end
      
      # Examines an object for its ivars, packs each into a hash
      def _pack_ivars( obj )
        return_hash = {}
        vars = obj.aquatic? ? obj._storable_attributes : obj.instance_variables
        vars.each do |ivar_name|
          ivar = obj.instance_variable_get( ivar_name )
          return_hash[ivar_name] = _pack_object( ivar ) unless ivar.nil?       
        end
        return_hash
      end  
      
      def _pack_object( obj ) 
        klass = obj.class
        if klass == String
          obj
        elsif [TrueClass, FalseClass].include?( klass )
          { 'class' => klass.to_s }  
        elsif [Time, Date, Fixnum, Integer, Bignum, Float ].include?( klass )
          {
            'class' => klass.to_s,
            'data' => obj.to_s
          }
        elsif klass == Rational
          {
            'class' => klass.to_s,
            'data' => obj.to_s.match(/(\d*)\/(\d*)/).to_a.slice(1,2)
          } 
        else # a more complex object 
          return_hash = {}
          if (obj.aquatic? && obj._embed_me == true)
            return_hash = obj._pack    
          elsif !obj.aquatic?
            ancestors = klass.ancestors
            if ancestors.include?( Array )
              return_hash['initialization'] = _pack_array( obj )
            elsif ancestors.include?( Hash ) 
              return_hash['initialization'] = _pack_hash( obj )
            end
            data = _pack_ivars( obj )
            return_hash['data'] = data unless data.empty?
            return_hash['class'] = klass.to_s  
          elsif obj._embed_me.class == Hash
            return_hash['stub'] = _stub( obj )
          else
            return_hash['stub'] = _pack_to_external(obj)
          end
          return_hash        
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
  