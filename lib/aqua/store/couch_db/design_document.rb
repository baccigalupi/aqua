# Design documents are responsible for saving views. It is also the place that Aqua will
# be saving the Class code. There will be one design document per class. There may be additional
# design documents created without being tied to a class. Don't know yet. 
module Aqua
  module Store 
    module CouchDB
      class DesignDocument < Mash
        
        # the DesignDocument is essentially a special type of Document.
        include Aqua::Store::CouchDB::StorageMethods
        
        # In the design document the name is the same as the id. That way initialization can 
        # include a name parameter, which will change the id, and therefore the address of the 
        # document. This method returns the id.
        # @return [String] id for document
        # @api public
        def name
          id
        end
        
        # Sets the id and is an alias for id=.
        # @param [String] Unique identifier
        # @return [String] Escaped identifier 
        # @api public
        def name=( n )
          self.id = ( n )
        end
        
        alias :document_initialize :initialize
        
        def initialize( hash={} )
          hash = Mash.new( hash ) unless hash.empty?
          self.id = hash.delete(:name) if hash[:name]
          document_initialize( hash )
        end      
        
        # couchdb database url for the design document
        # @return [String] representing CouchDB uri for document 
        # @api public
        def uri
          raise ArgumentError, 'DesignDocument must have a name' if name.nil? || name.empty?
          database.uri + '/_design/' + name
        end 
        
        # Updates the id and rev after a design document is successfully saved. The _design/ 
        # portion of the id has to be stripped. 
        # @param [Hash] Result returned by CouchDB document save
        # @api private
        def update_version( result ) 
          self.id     = result['id'].gsub(/\A_design\//, '')
          self.rev    = result['rev']
        end 
        
      end
    end
  end
end        