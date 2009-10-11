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
        
        # Gets a design document by name.
        # @param [String] Id/Name of design document
        # @return [Aqua::Store::CouchDB::DesignDocument]
        # @api public
        def self.get( name ) 
          CouchDB.get( "#{database.uri}/_design/#{CGI.escape(name)}" )
        end
        
        # VIEWS --------------------
        
        # An array of indexed views for the design document.
        # @return [Array]
        # @api public
        def views
          self[:views] ||= Mash.new
        end 
        
        # Adds or updates a view with the given options
        #
        # @param [String, Hash] Name of the view, or options hash
        # @option arg [String] :name The view name, required
        # @option arg [String] :map Javascript map function, optional
        # @option arg [String] :reduce Javascript reduce function, optional
        #
        # @return [Mash] Map/Reduce mash of javascript functions
        #
        # @example 
        #   design_doc << 'attribute_name'
        #   design_doc << {:name => 'attribute_name', :map => 'function(doc){ ... }'}
        #  
        # @api public
        def <<( arg )
          # handle different argument options
          if [String, Symbol].include?( arg.class )
            view_name = arg
            opts = {}
          elsif arg.class.ancestors.include?( Hash )
            opts = Mash.new( arg )
            view_name = opts.delete( :name )
            raise ArgumentError, 'Option must include a :name that is the view\'s name' unless view_name
          else
            raise ArgumentError, "Must be a string or Hash like object of options"    
          end
          
          # build the map/reduce query  
          map =     opts[:map]
          reduce =  opts[:reduce]
          views # to initialize self[:views]
          self[:views][view_name] = { 
            :map => map || build_map( view_name ), 
          }
          self[:views][view_name][:reduce] = reduce if reduce
          self[:views][view_name]
        end
        
        private
          # Builds a generic map assuming that the view_name is the name of a document attribute.
          # @param [String, Symbol] Name of document attribute
          # @return [String] Javascript map function
          #
          # @api private
          def build_map( view_name )
            "function(doc) {
              if( doc['#{view_name}'] ){
                emit( doc['#{view_name}'], null );
              }
            }"
          end 
        public
        
        def query( view_name, opts={} )
          opts = Mash.new( opts ) unless opts.empty?
          query_uri = "#{uri}/_view/#{CGI.escape(view_name.to_s)}?"
          query_uri += 'include_docs=true' unless opts[:select] && opts[:select] != 'all' 
          ResultSet.new( CouchDB.get( query_uri ) )
        end 
        
      end
    end
  end
end        