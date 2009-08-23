# This module is responsible for packing objects into Storage Objects
# The Storage Object is expected to be a Mash-Like thing (Hash with indifferent access).
# It is the job of the storage engine to convert the Mash into the actual storage data.
module Aqua::Pack
  
  def self.included( klass ) 
    klass.class_eval do
      extend ClassMethods
      include InstanceMethods
      
      unless instance_methods.include?( 'id=' ) || new.instance_variables.include?( '@id' )
        attr_accessor :id
      end
      
      hide_attributes :_store, :__pack, :id, :_rev 
    end  
  end 
  
  module ClassMethods 
    # Used in class declaration to assign certain instance variables as not for persistance
    # @param [Symbol] or [Array of Symbols] ivars 
    # 
    # @example
    # class User 
    #   include Aqua::Object
    #   attr_accessor :username, :email, :password, :password_confirmation, :cryped_password, :salt
    #   hide_instance_variables :password, :password_confirmation 
    #   # ... lots more user code here ...
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
    # @api private
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
      self.__pack.id = @id if @id
      self.__pack[:_rev] = _rev if _rev 
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
       
    # Private/protected methods are all prefaced by an underscore to prevent
    # clogging the object instance space. Some of the public ones above are too!
    protected
      
      # __pack is an Aqua::Storage object into which the object respresentation is packed
      
      # _store is the current state of the storage of the object on CouchDB. It is used lazily
      # and will be empty unless it is needed for unpacking or checking for changed data.
      
      # _rev is needed for CouchDB store, since updates require the rev information. We could
      # do without this accessor, but it would mean that an extra get request would have to be
      # made with each PUT request so that the latest _rev could be obtained. 
      
      attr_accessor :_store, :__pack, :_rev
      
    private
      
      def _commit( mask_exception = true ) 
        result = true
        begin
          _pack
          _save_to_store
        rescue Exception => e
          if mask_exception
            result = false
          else
            raise e
          end    
        end
        if result
          self.id =   __pack.id
          self._rev = __pack.rev
          _clear_accessors
          self
        else
          result
        end    
      end    
       
      # Object packing methods ------------
      
      # Examines each ivar and converts it to a hash, array, string combo
      # @api private
      def _pack_properties
        self.__pack[:data] = _pack_ivars( self )
        initializations = _pack_initializations( self )
        self.__pack[:initialization] = initializations unless initializations.empty? 
      end
      
      def _pack_initializations( obj )
        ancestors = obj.class.ancestors
        initializations = {}
        if ancestors.include?( Array )
          initializations = _pack_array( obj )
        elsif ancestors.include?( Hash )  
          initializations = _pack_hash( obj )
        elsif ancestors.include?( OpenStruct )
          initializations = _pack_struct( obj )  
        end
        initializations 
      end  
      
      # Examines an object for its ivars, packs each into a hash 
      # @api private
      def _pack_ivars( obj )
        return_hash = {}
        vars = obj.aquatic? ? obj._storable_attributes : obj.instance_variables
        vars.each do |ivar_name|
          ivar = obj.instance_variable_get( ivar_name )
          return_hash[ivar_name] = _pack_object( ivar ) unless ivar.nil?       
        end
        return_hash
      end  
      
      # Packs an object into data and meta data. Works recursively sending out to array, hash, etc.  
      # object packers, which send their values back to _pack_object
      #
      # @param Object to pack
      # @return [Mash] Indifferent hash that is the data/metadata deconstruction of an object.
      #
      # @api private
      def _pack_object( obj ) 
        klass = obj.class
        if klass == String
          obj
        elsif [TrueClass, FalseClass].include?( klass )
          { 'class' => klass.to_s, 'initialization' => obj.to_s }  
        elsif [Time, Date, Fixnum, Bignum, Float ].include?( klass )
          {
            'class' => klass.to_s,
            'initialization' => obj.to_s
          }
        elsif klass == Rational
          {
            'class' => klass.to_s,
            'initialization' => obj.to_s.match(/(\d*)\/(\d*)/).to_a.slice(1,2)
          } 
        else # a more complex object, including an array or a hash like thing 
          return_hash = {}
          if obj.aquatic? # TODO distinguish between internal storage, stubbing and external (obj.aquatic? && obj._embed_me == true)
            return_hash = obj._pack    
          elsif !obj.aquatic?
            initialization = _pack_initializations( obj )
            return_hash['initialization'] = initialization unless initialization.empty?
            data = _pack_ivars( obj )
            return_hash['data'] = data unless data.empty?
            return_hash['class'] = klass.to_s  
          # TODO: distinguish between internal storage, stubbing and external (obj.aquatic? && obj._embed_me == true) 
          # elsif obj._embed_me.class == Hash
          #   return_hash = _stub( obj )
          # else
          #   return_hash = _pack_to_external(obj)
          end
          return_hash        
        end           
      end   
      
      # The portion of the recursive mechanism that packs up hashes
      # @param [Hash] or Hash derived object
      # @return [Hash] The parsed Hash representation of the argument Hash
      # 
      # @api private
      def _pack_hash( hash )
        return_hash = {}
        hash.each do |raw_key, value|
          key_class = raw_key.class
          if key_class == Symbol
            key = ":#{raw_key.to_s}"
          elsif key_class == String
            key = raw_key
          else 
            raise ArgumentError, 'Currently Hash keys must be either strings or symbols' unless [Symbol, String].include?( key.class )
          end     
          return_hash[key] = _pack_object( value )
        end
        return_hash  
      end
      
      def _pack_struct( struct )
        _pack_hash( struct.instance_variable_get("@table") ) 
      end
      
      # The portion of the recursive mechanism that packs up arrays
      # @param [Array] or Array derived object
      # @return [Array] The parsed Array representation of the argument Array
      # 
      # @api private
      def _pack_array( arr )
        return_arr = []
        arr.each do |obj|
          return_arr << _pack_object( obj )
        end
        return_arr   
      end    
      
      
      def _pack_singletons
        # TODO: figure out 1.8 and 1.9 compatibility issues. 
        # Also learn the library usage, without any docs :(
      end    
      
      def _save_to_store 
        __pack.commit
      end
      
      def _clear_accessors
        self.__pack = nil
        self._store = nil
      end
              
    public  
  end # InstanceMethods     
  
end # Aqua::Pack 
  