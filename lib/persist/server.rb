# This has been ripped in part from CouchRest: http://github.com/mattetti/couchrest/tree/master
# License information is in LICENSE_COUCHREST, modifications are covered under the persist license


module Persist
  class Server
    attr_accessor :uri, :uuid_batch_count, :http_client, :uuids
    attr_reader :namespace, :uuids
    
    def initialize(opts={})
      opts = Mash.new(opts) unless opts.empty?
      self.uri =              opts[:server] || 'http://127.0.0.1:5984'
      self.uuid_batch_count = opts[:uuid_batch_count] || 1000 
      self.namespace =        opts[:namespace] 
    end 
    
    def namespace=( name )
      default = 'persist_'
      name ||= default
      name = Persist.escape( name )
      name = default if name.empty? 
      @namespace = name
    end
    
    # DATABASE MANAGMENT -----------------
    
    # Lists all databases on the server
    def databases
      Persist.get "#{@uri}/_all_dbs"
    end
    
    def namespaced_name( name ) 
      "#{namespace}#{name}"
    end  

    # Returns a CouchRest::Database for the given name
    def database(name)
      Persist::Database.new( namespaced_name(name), :server => self )
    end

    # Creates the database if it doesn't exist
    def database!(name)
      create_db(namespaced_name(name)) rescue nil
      database(namespaced_name(name))
    end

    # GET the welcome message
    def info
      Persist.get "#{@uri}/"
    end

    # Create a database
    def create_db(name)
      Persist.put "#{@uri}/#{namespaced_name(name)}"
      database(namespaced_name(name))
    end

    # Restart the CouchDB instance
    def restart!
      Persist.post "#{@uri}/_restart"
    end
    
    # counts the number of uuids available, used by Database to limit bulk save
    def uuid_count
      if uuids 
        uuids.count 
      else
        load_uuids  
        uuid_batch_count
      end  
    end  

    # Retrive an unused UUID from CouchDB. Server instances manage caching a list of unused UUIDs.
    def next_uuid(count = @uuid_batch_count)
      @uuids ||= []
      if uuids.empty?
        load_uuids(count)
      end
      uuids.pop
    end
    
    def load_uuids( count=@uuid_batch_count ) 
      @uuids = Persist.get("#{@uri}/_uuids?count=#{count}")["uuids"]
    end  
    
    
  end # Server 
end # Persist
