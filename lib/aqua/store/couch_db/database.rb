require "base64"

module Aqua 
  module Store
    module CouchDB
      class Database
        attr_reader :server, :name, :uri 
        attr_accessor :bulk_cache
     
        # Create a CouchDB database representation from a name. Does not actually create a database on couchdb.
        # It does not ensure that the database actually exists either. Just creates a ruby representation
        # of a ruby database interface.
        # 
        # @param [optional String] Name of database. If not provided server namespace will be used as database name. 
        # @param [optional Hash] Options for initialization. Currently the only option is :server which must be either a CouchDB server object or a symbol representing a server stored in the CouchDB module.
        # @return [Database] The initialized object
        # 
        # @api public
        def initialize( name=nil, opts={})
          name = nil if name && name.empty?
          opts = Mash.new( opts ) unless opts.empty?
          @name = name if name
          initialize_server( opts[:server] )
          @uri = "#{server.uri}/#{namespaced( name )}" 
          self.bulk_cache = []
        end
        
        # Initializes the database server with the option provided. If not option is provided the default CouchDB
        # server is used instead.
        #
        # @param [Symbol, Server]
        #   If server_option argument is a Symbol then the CouchDB server stash will be queried for a matching 
        #   server. CouchDB manages the creation of that server in the stash, if not found. 
        #   If server_option argument is a Server object then then it is added directly to the database object.
        #   No management of the server will be done with CouchDB's server stash.
        # @raise [ArgumentError] Raised if a server_option is passed in and if that option is neither a Hash nor a Symbol.
        # @return [Server]
        #
        # @api private
        def initialize_server( server_option ) 
          if server_option
            if server_option.class == Symbol
              @server = CouchDB.server( server_option )
            elsif server_option.class == Aqua::Store::CouchDB::Server
              @server = server_option # WARNING: this won't get stashed in CouchDB for use with other database.
            else
              raise ArgumentError, ":server option must be a symbol identifying a CouchDB server, or a Server object"
            end
          else        
            @server = CouchDB.server
          end 
          @server  
        end
        
        # Namespaces the database path for the given server. If no name is provided, then the database name is
        # just the Server's namespace.
        # 
        # @params [String] Name that the database is initialized with, if any.
        # @return [String] Namespaced database for use as a http path
        # 
        # @api private
        def namespaced( name )
          if name 
            "#{server.namespace}_#{CouchDB.escape(@name)}"
          else
            server.namespace
          end     
        end  
    
        # Creates a database representation and PUTs it on the CouchDB server. 
        # If successfull returns a database object. If not successful in creating
        # the database on the CouchDB server then, false will be returned.
        #
        # @see Aqua::Store::CouchDB#initialize for option details
        # @return [Database, false] Will return the database on success, and false if it did not succeed. 
        #
        # @api pubilc
        def self.create( name=nil, opts={} )
          db = new(name, opts)
          begin
            CouchDB.put( db.uri )
          rescue Exception => e # catch database already exists errors ... 
            unless e.message.match(/412/)
              db = false
            end   
          end
          db    
        end 
        
        # Creates a database representation and PUTs it on the CouchDB server. 
        # This version of the #create method raises an error if the PUT request fails. 
        # The exception on this, is if the database already exists then the 412 HTTP code will be ignored.
        #
        # @see Aqua::Store::CouchDB#initialize for option details
        # @return [Database] Will return the database on success. 
        # @raise HttpAdapter Exceptions depending on the reason for failure.
        #
        # @api pubilc
        def self.create!( name=nil, opts={} ) 
          db = new( name, opts )
          begin
            CouchDB.put( db.uri )
          rescue Exception => e # catch database already exists errors ... 
            raise e unless e.class == RequestFailed && e.message.match(/412/) 
          end 
          db
        end  
    
        # Checks to see if the database exists on the couchdb server.
        #
        # @return [true, false] depending on whether the database already exists in CouchDB land
        #
        # @api public
        def exists?
          begin 
            info 
            true
          rescue CouchDB::ResourceNotFound  
            false
          end  
        end  
        
        # GET the database info from CouchDB
        def info
          CouchDB.get( uri )
        end
     
        # Deletes a database; use with caution as this isn't reversible.
        # 
        # @return A JSON response on success. nil if the resource is not found. And raises an error if another exception was raised
        # @raise Exception related to request failure that is not a ResourceNotFound error.
        def delete
          begin 
            CouchDB.delete( uri )
          rescue CouchDB::ResourceNotFound
            nil
          end    
        end  
        
        # Deletes a database; use with caution as this isn't reversible. Similar to #delete, 
        # except that it will raise an error on failure to find the database.
        # 
        # @return A JSON response on success. 
        # @raise Exception related to request failure or ResourceNotFound.
        def delete!
          CouchDB.delete( uri )
        end  
    
        # # Query the <tt>_all_docs</tt> view. Accepts all the same arguments as view.
        def documents(params = {})
          keys = params.delete(:keys)
          url = CouchDB.paramify_url( "#{uri}/_all_docs", params )
          if keys
            CouchDB.post(url, {:keys => keys})
          else
            CouchDB.get url
          end
        end   
    
        # BULK ACTIVITIES ------------------------------------------
        def add_to_bulk_cache( doc ) 
          if server.uuid_count/2.0 > bulk_cache.count
            self.bulk_cache << doc 
          else
            bulk_save
            self.bulk_cache << doc
          end    
        end
    
        def bulk_save
          docs = bulk_cache
          self.bulk_save_cache = []
          CouchDB.post( "#{uri}/_bulk_docs", {:docs => docs} )
        end
    
        # # load a set of documents by passing an array of ids
        # def get_bulk(ids)
        #   documents(:keys => ids, :include_docs => true)
        # end
        # alias :bulk_load :get_bulk
        #   
        # # POST a temporary view function to CouchDB for querying. This is not
        # # recommended, as you don't get any performance benefit from CouchDB's
        # # materialized views. Can be quite slow on large databases.
        # def slow_view(funcs, params = {})
        #   keys = params.delete(:keys)
        #   funcs = funcs.merge({:keys => keys}) if keys
        #   url = CouchDB.paramify_url "#{@root}/_temp_view", params
        #   JSON.parse(HttpAbstraction.post(url, funcs.to_json, {"Content-Type" => 'application/json'}))
        # end
        # 
        # # backwards compatibility is a plus
        # alias :temp_view :slow_view
        #   
        # # Query a CouchDB view as defined by a <tt>_design</tt> document. Accepts
        # # paramaters as described in http://wiki.apache.org/couchdb/HttpViewApi
        # def view(name, params = {}, &block)
        #   keys = params.delete(:keys)
        #   name = name.split('/') # I think this will always be length == 2, but maybe not...
        #   dname = name.shift
        #   vname = name.join('/')
        #   url = CouchDB.paramify_url "#{@root}/_design/#{dname}/_view/#{vname}", params
        #   if keys
        #     CouchDB.post(url, {:keys => keys})
        #   else
        #     if block_given?
        #       @streamer.view("_design/#{dname}/_view/#{vname}", params, &block)
        #     else
        #       CouchDB.get url
        #     end
        #   end
        # end
        # 
        # # GET a document from CouchDB, by id. Returns a Ruby Hash.
        # def get(id, params = {})
        #   slug = escape_docid(id)
        #   url = CouchDB.paramify_url("#{@root}/#{slug}", params)
        #   result = CouchDB.get(url)
        #   return result unless result.is_a?(Hash)
        #   doc = if /^_design/ =~ result["_id"]
        #     Design.new(result)
        #   else
        #     Document.new(result)
        #   end
        #   doc.database = self
        #   doc
        # end
        # 
        # # Compact the database, removing old document revisions and optimizing space use.
        # def compact!
        #   CouchDB.post "#{@root}/_compact"
        # end
        # 
        # # Delete and re create the database
        # def recreate!
        #   delete!
        #   create!
        # rescue HttpAbstraction::ResourceNotFound
        # ensure
        #   create!
        # end
        # 
        # # Replicates via "pulling" from another database to this database. Makes no attempt to deal with conflicts.
        # def replicate_from other_db
        #   raise ArgumentError, "must provide a CouchReset::Database" unless other_db.kind_of?(CouchDB::Database)
        #   CouchDB.post "#{@host}/_replicate", :source => other_db.root, :target => name
        # end
        # 
        # # Replicates via "pushing" to another database. Makes no attempt to deal with conflicts.
        # def replicate_to other_db
        #   raise ArgumentError, "must provide a CouchReset::Database" unless other_db.kind_of?(CouchDB::Database)
        #   CouchDB.post "#{@host}/_replicate", :target => other_db.root, :source => name
        # end
        # 
        # 
        # private
        # 
        # def clear_extended_doc_fresh_cache
        #   ::CouchDB::ExtendedDocument.subclasses.each{|klass| klass.design_doc_fresh = false if klass.respond_to?(:design_doc_fresh=) }
        # end
          
      end # Database       
    end # CouchDB
  end # Store  
end # Aqua
