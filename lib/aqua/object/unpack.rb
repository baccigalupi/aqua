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
      build( doc )
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
     
    # Creates a new object from the doc; It is used by queries which return a set of docs.
    # Also used by load to do the same thing ...
    # @param [Document, Hash, Mash] converted object
    def build( doc )
      translator = Aqua::Translator.new( new, id )
      translator.unpack_object( doc ) 
    end    
  end
  
  module InstanceMethods
    # Reloads database information into the object, and raises an error on failure.
    # @return [Object] Will return raise error on failure and return self on success.
    #
    # @api public
    def reload 
      doc = self.class._get_store( id )
      _translator.reload_object( self, doc )
      self
    end 
  end

end       