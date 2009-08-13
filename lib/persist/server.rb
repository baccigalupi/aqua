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
    
    # Lists all database names on the server
    def database_names
      dbs = Persist.get( "#{@uri}/_all_dbs" )
      dbs.select{|name| name.match(/\A#{namespace}/)}
    end
    
    def databases
      dbs = [] 
      database_names.each do |db_name|
        dbs << Database.new( db_name.gsub(/\A#{namespace}/, ''), :server => self )
      end
      dbs  
    end  
    
    # Deletes all databases named for this namespace (i.e. this server)
    # Use with caution ... it is a permanent and undoable change
    def delete_all! 
      databases.each{|db| db.delete! }
    end  
    
    def namespaced( name ) 
      "#{namespace}#{name}"
    end  

    # Returns a CouchRest::Database for the given name
    def database(name)
      db = Persist::Database.new( name, :server => self )
      db.exists? ? db : nil
    end

    # Creates the database if it doesn't exist
    def database!(name)
      Database.create( name, :server => self )  
    end

    # GET the welcome message
    def info
      Persist.get "#{@uri}/"
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
