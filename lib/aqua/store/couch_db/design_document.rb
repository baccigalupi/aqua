# Design documents are responsible for saving views. It is also the place that Aqua will
# be saving the Class code. There will be one design document per class. There may be additional
# design documents created without being tied to a class. Don't know yet. 
module Aqua
  module Store 
    module CouchDB
      class DesignDocument < Gnash
        
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
          hash = Gnash.new( hash ) unless hash.empty?
          self.id = hash.delete(:name) if hash[:name]
          document_initialize( hash )  # TODO: can't this just be a call to super?
        end 
        
        def do_rev( hash )
          # TODO: This is a temp hack to deal with loading the right revision number so a design doc
          # can be updated from the document. Without this hack, the rev is nil, and there is a conflict.
        
          hash.delete(:rev)   # This is omited to aleviate confusion
          # hash.delete(:_rev)  # CouchDB determines _rev attribute
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
          design = CouchDB.get( "#{database.uri}/_design/#{CGI.escape(name)}" )
          new( design )
        end
        
        # VIEWS --------------------
        
        # An array of indexed views for the design document.
        # @return [Array]
        # @api public
        def views
          self[:views] ||= Gnash.new
        end 
        
        # Adds or updates a view with the given options
        #
        # @param [String, Hash] Name of the view, or options hash
        # @option arg [String] :name The view name, required
        # @option arg [String] :map Javascript map function, optional
        # @option arg [String] :reduce Javascript reduce function, optional
        #
        # @return [Gnash] Map/Reduce mash of javascript functions
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
            opts = Gnash.new( arg )
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
            :map => map || build_map( view_name, opts[:class_constraint] ), 
          }
          self[:views][view_name][:reduce] = reduce if reduce
          self[:views][view_name]
        end
        
        alias :add :<<
        
        def add!( arg ) 
          self << arg 
          save!
        end  
        
        private
          # Builds a generic map assuming that the view_name is the name of a document attribute.
          # @param [String, Symbol] Name of document attribute
          # @param [Class, String] Optional constraint on to limit view to a given class
          # @return [String] Javascript map function
          #
          # @api private
          def build_map( view_name, class_constraint=nil )
            class_constraint = if class_constraint.class == Class
              " && doc['type'] == '#{class_constraint}'"
            elsif class_constraint.class == String
              " && #{class_constraint}"
            end    
            "function(doc) {
              if( doc['#{view_name}'] #{class_constraint}){
                emit( doc['#{view_name}'], 1 );
              }
            }"
          end 
        public
        
        # group=true Version 0.8.0 and forward
        # group_level=int
        # reduce=false Trunk only (0.9)
        
        def query( view_name, opts={} )
          opts = Gnash.new( opts ) unless opts.empty? 
          doc_class = opts[:document_class] 
          
          params = []
          params << 'include_docs=true' unless (opts[:select] && opts[:select] != 'all')
          # TODO: this is according to couchdb really inefficent with large sets of data.
          # A better way would involve, using start and end keys with limit. But this 
          # is a really hard one to figure with jumping around to different pages
          params << "skip=#{opts[:offset]}" if opts[:offset]
          params << "limit=#{opts[:limit]}" if opts[:limit]
          params << "key=#{opts[:equals]}" if opts[:equals] 
          if opts[:order].to_s == 'desc' || opts[:order].to_s == 'descending'
            desc = true
            params << "descending=true"
          end 
          if opts[:range] && opts[:range].size == 2
            params << "startkey=#{opts[:range][desc == true ? 1 : 0 ]}"  
            params << "endkey=#{opts[:range][desc == true ? 0 : 1]}"   
          end   
          
          query_uri = "#{uri}/_view/#{CGI.escape(view_name.to_s)}?"
          query_uri << params.join('&')
          
          result = CouchDB.get( query_uri )
          opts[:reduced] ? result['rows'].first['value'] : ResultSet.new( result, doc_class )
        end 
        
      end
    end
  end
end        