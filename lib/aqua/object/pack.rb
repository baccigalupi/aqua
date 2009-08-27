# This module is responsible for packing objects into Storage Objects
# The Storage Object is expected to be a Mash-Like thing (Hash with indifferent access).
# It is the job of the storage engine to convert the Mash into the actual storage ivars.
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
      #self.__pack[:class] = class_name
      self.__pack[:keys] = []
      self.__pack[:stubs] = []
      #_pack_properties
      self.__pack.merge!( _pack_object( self ) )
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
      elsif obj.respond_to?(:to_aqua) # Types requiring initialization
        obj.to_aqua( self )
      elsif obj.aquatic? && obj != self
        if obj._embed_me == true
          obj._pack
        else
          _build_stub( obj ) 
        end   
      else # other object without initializations
        _pack_vanilla( obj )
      end     
      # elsif obj.aquatic? # aquatic objects
      #   if obj == self
      #     if obj.respond_to?(:to_aqua)
      #       obj.to_aqua( self )
      #     else
      #       _pack_vanilla( obj )
      #     end    
      #   elsif obj._embed_me == true
      #     obj._pack
      #   else
      #     
      #   end 
      # end           
    end
    
    def _pack_ivars( obj )
      return_hash = {}
      vars = obj.aquatic? ? obj._storable_attributes : obj.instance_variables
      vars.each do |ivar_name|
        ivar = obj.instance_variable_get( ivar_name )
        return_hash[ivar_name] = _pack_object( ivar ) unless ivar.nil?       
      end
      return_hash
    end
    
    def _build_object_key( obj )
      index = self.__pack[:keys].length
      self.__pack[:keys] << _pack_object( obj )
      index # return key
    end    
           
    
    attr_accessor :_warnings 
       
    # Private/protected methods are all prefaced by an underscore to prevent
    # clogging the object instance space. Some of the public ones above are too!
    protected
      
      # __pack is an Aqua::Storage object into which the object respresentation is packed
      #
      # _store is the current state of the storage of the object on CouchDB. It is used lazily
      # and will be empty unless it is needed for unpacking or checking for changed data.
      #
      # _rev is needed for CouchDB store, since updates require the rev information. We could
      # do without this accessor, but it would mean that an extra get request would have to be
      # made with each PUT request so that the latest _rev could be obtained. 
      #
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
      
      def _pack_vanilla( obj ) 
        {
          'class' => obj.class.to_s,
          'ivars' => _pack_ivars( obj )
        }
      end
      
      def _build_stub( obj )
        index = self.__pack[:stubs].length 
        stub = { :class => obj.class.to_s, :id => obj } 
        # deal with cached methods
        if obj._embed_me.keys && stub_methods = obj._embed_me[:stub]
          stub[:methods] = {}
          if stub_methods.class == Symbol || stub_methods.class == String
            stub_method = stub_methods.to_sym 
            stub[:methods][stub_method] = obj.send( stub_method )
          else # is an array of values
            stub_methods.each do |meth|
              stub_method = meth.to_sym
              stub[:methods][stub_method] = obj.send( stub_method )
            end  
          end    
        end
        # add the stub  
        self.__pack[:stubs] << stub
        # return a hash  
        {'class' => 'Aqua::Stub', 'init' => "/STUB_#{index}"}
      end 
      
      def _pack_singletons
        # TODO: figure out 1.8 and 1.9 compatibility issues. 
        # Also learn the library usage, without any docs :(
      end    
      
      def _save_to_store
        self._warnings = []
        _commit_externals 
        __pack.commit
      end
      
      def _commit_externals 
        __pack[:stubs].each_with_index do |obj_hash, index|
          obj = obj_hash[:id]
          if obj.commit
            obj_hash[:id] = obj.id
          else
            if obj.id
              self._warnings << "Unable to save latest version of #{obj.inspect}, stubbed at index #{index}"
              obj_hash[:id] = obj.id if obj.id 
            else  
              self._warnings << "Unable to save #{obj.inspect}, stubbed at index #{index}" 
            end  
          end    
        end  
      end 
      
      def _clear_accessors
        self.__pack = nil
        self._store = nil
      end
              
    public  
  end # InstanceMethods     
  
end # Aqua::Pack 
  