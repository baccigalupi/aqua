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
      doc = _get_store( id )
      translator = Aqua::Translator.new( new, id )
      translator.unpack_object( doc ) 
    end
    
    # Retrieves objects storage from its engine.
    # @return [Storage]
    # 
    # @api private 
    def _get_store( id )
      doc = self::Storage.get( id )
      raise ArgumentError, "#{self} with id of #{doc_id} was not found" unless doc
      doc 
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
        self
      end
      
      # Retrieves objects storage from its engine.
      # @return [Storage]
      # 
      # @api private
      def _get_store
        self._store = self.class._get_store( id )
      end
      
      # Unpacks an object from hash representation of data and metadata
      # @return [Storage]
      # @todo Refactor to move more of this into individual classes
      #
      # @api private
      def _unpack
        _translator.unpack_object( self )    
      end 
            
    public  
  end

end       