module Aqua::Unpack
  
  def self.included( klass ) 
    klass.class_eval do
      extend ClassMethods
      include InstanceMethods
    end  
  end 
  
  module ClassMethods
    # Creates a new object with the class of the base class and loads it with data saved from the database.
    # @param [String] Object id 
    # @return [Object] 
    # 
    # @api public 
    def load( id ) 
      instance = new
      instance.id = id
      instance.reload
      instance
    end
  end
  
  module InstanceMethods
    # Reloads database information into the object.
    # @param [optional true, false] Default is true. If true the exceptions will be swallowed and 
    #   false will be returned. If false, then any exceptions raised will stop the show.
    # @return [Object, false] Will return false or raise error on failure and self on success.
    #
    # @api public
    def reload( mask_exceptions = true ) 
      if id.nil?
        if mask_exceptions
          false
        else
          raise ObjectNotFound, "#{self.class} instance must have an id to be reloaded"
        end    
      else
        begin
          _reload
        rescue Exception => e 
          if mask_exceptions
            false
          else 
            raise e
          end    
        end      
      end  
    end 
    
    # Reloads database information into the object, and raises an error on failure.
    # @return [Object] Will return raise error on failure and return self on success.
    #
    # @api public
    def reload!
      reload( false )
    end  
    
    private 
      # Actual mechanism for reloading an object from stored data.
      # @return [Object] Will return raise error on failure and return self on success.
      #
      # @api private
      def _reload
        _get_store
        _unpack
        _clear_store
        self
      end
      
      # Retrieves objects storage from its engine.
      # @return [Storage]
      # 
      # @api private
      def _get_store
        # todo: this is kind of klunky, should refactor
        self._store = self.class::Storage.new(:id => self.id).retrieve 
      end
      
      # Unpacks an object from hash representation of data and metadata
      # @return [Storage]
      # @todo Refactor to move more of this into individual classes
      #
      # @api private
      def _unpack
        if init = _unpack_initialization( _store )
          replace( init ) 
        end
        if ivars = _store[:ivars]
          _unpack_ivars( self, ivars )
        end    
      end 
      
      # Makes @_store nil to converve on memory
      #
      # @api private
      def _clear_store
        @_store = nil
      end  
      
      # Unpacks an object's instance variables
      # @todo Refactor to move more of this into individual classes
      #
      # @api private
      def _unpack_ivars( obj, data ) 
        data.each do |ivar_name, data_package|
          unpacked = if data_package.class == String
            data_package
          else
            _unpack_object( data_package )
          end
          obj.instance_variable_set( ivar_name, unpacked )
        end  
      end    
      
      # Unpacks an the initialization object from a hash into a real object.
      # @return [Object] Generally a hash, array or string
      # @todo Refactor to move more of this into individual classes
      #
      # @api private
      def _unpack_initialization( obj )
        if init = obj[:init] 
          init_class = init.class
          if init_class == String
            if init.match(/\A\/STUB_(\d*)\z/)
              _unpack_stub( $1.to_i )
            elsif init.match(/\A\/FILE_(.*)\z/) 
              _unpack_file( $1, obj )
            else    
              init
            end  
          elsif init.class == Array 
            _unpack_array( init )
          else
            _unpack_hash( init )
          end    
        end 
      end
      
      # Retrieves and unpacks a stubbed object from its separate storage area
      # @return [Aqua::Stub] Delegate object for externally saved class
      # @param [Fixnum] Array index for the stub details, garnered from the key name
      #
      # @api private
      def _unpack_stub( index ) 
        hash = _store[:stubs][index] 
        Aqua::Stub.new( hash ) 
      end 
      
      # Retrieves and unpacks a stubbed object from its separate storage area
      # @param [String] File name, and attachment id
      # @return [Aqua::FileStub] Delegate object for file attachments
      #
      # @api private
      def _unpack_file( name, obj )
        hash = { 
          :parent => self, 
          :id => name,
          :methods => obj[:methods] 
        } 
        Aqua::FileStub.new( hash ) 
      end    
       
      # Unpacks an Array. 
      # @return [Object] Generally a hash, array or string
      # @todo Refactor ?? move more of this into support/initializers Array
      #
      # @api private
      def _unpack_array( obj ) 
        arr = [] 
        obj.each do |value|
          value = _unpack_object( value ) unless value.class == String
          arr << value
        end  
        arr
      end
      
      # Unpacks a Hash. 
      # @return [Object] Generally a hash, array or string
      # @todo Refactor ?? move more of this into support/initializers Hash
      #
      # @api private
      def _unpack_hash( obj )
        hash = {}
        obj.each do |raw_key, value|
          value = _unpack_object( value ) unless value.class == String
          if raw_key.match(/\A(:)/)
            key = raw_key.gsub($1, '').to_sym
          elsif raw_key.match(/\A\/OBJECT_(\d*)\z/) 
            key = _unpack_object( self._store[:keys][$1.to_i] )
          else 
            key = raw_key
          end  
          hash[key] = value
        end
        hash  
      end    
      
      # The real workhorse behind object construction: it recursively rebuilds objects based on 
      # whether the passed in object is an Array, String or a Hash (true/false too now). 
      # A hash that has the class key 
      # is an object representation. If it does not have a hash key then it is an ordinary hash.
      # An array will either have strings or object representations values.
      #
      # @param [Hash, Mash] Representation of the data in the aqua meta format
      # @return [Object] The object represented by the data
      # 
      # @api private
      def _unpack_object( store_pack )
        package_class = store_pack.class 
        if package_class == String || store_pack == true || store_pack == false
          store_pack
        elsif package_class == Array 
          _unpack_array( store_pack )  
        else # package_class == Hash -or- Mash
          if store_pack['class']
            # Constantize the objects class
            obj_class = store_pack['class'].constantize rescue nil
            
            # build from initialization 
            init = _unpack_initialization( store_pack )
            return_object = if init
              [Aqua::Stub, Aqua::FileStub].include?( obj_class ) ? init : obj_class.aqua_init( init )
            end
            
            # Build uninitialized object
            if return_object.nil?
              if obj_class
                return_object = obj_class.new
              else 
                # should log an error internally
                return_object = OpenStruct.new
              end
            end
            
            # add the ivars
            if ivars = store_pack['ivars'] 
              ivars.delete('@table') if obj_class.ancestors.include?( OpenStruct )
              _unpack_ivars( return_object, ivars )
            end
                   
            return_object 
          else # not a packaged object, just a hash, so unpack
            _unpack_hash( hash )
          end    
        end    
             
      end  
            
    public  
  end

end       