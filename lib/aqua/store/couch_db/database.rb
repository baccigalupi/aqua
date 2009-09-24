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
        # @param [String] Name that the database is initialized with, if any.
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
    
        # # Query the <tt>documents</tt> view. Accepts all the same arguments as view.
        def documents(params = {})
          keys = params.delete(:keys)
          url = CouchDB.paramify_url( "#{uri}/_all_docs", params )
          if keys
            CouchDB.post(url, {:keys => keys})
          else
            CouchDB.get url
          end
        end 
        
        # Deletes all the documents in a given database
        def delete_all
          documents['rows'].each do |doc|
            CouchDB.delete( "#{uri}/#{CGI.escape( doc['id'])}?rev=#{doc['value']['rev']}" ) #rescue nil
          end  
        end    
    
        # BULK ACTIVITIES ------------------------------------------
        def add_to_bulk_cache( doc ) 
          if server.uuid_count/2.0 > bulk_cache.size
            self.bulk_cache << doc 
          else
            bulk_save
            self.bulk_cache << doc
          end    
        end
    
        def bulk_save
          docs = bulk_cache
          self.bulk_cache = []
          CouchDB.post( "#{uri}/_bulk_docs", {:docs => docs} )
        end
          
      end # Database       
    end # CouchDB
  end # Store  
end # Aqua
