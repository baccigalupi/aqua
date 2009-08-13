# This has been mostly ripped from CouchRest: http://github.com/mattetti/couchrest/tree/master
# License information is in LICENSE_COUCHREST, modifications are covered under the persist license

module Persist::Store::CouchDB
  class Server
    attr_accessor :uri, :uuid_batch_count
    attr_reader :namespace
    
    def initialize(opts={})
      opts = Mash.new(opts) unless opts.empty?
      self.uri =              opts[:server] || 'http://127.0.0.1:5984'
      self.uuid_batch_count = opts[:uuid_batch_count] || 1000 
      self.namespace =        opts[:namespace]
    end 
    
    def namespace=( name )
      default = 'persist_'
      name ||= default
      name.gsub!('::', '__')
      name.gsub!(/[^a-z0-9\-_]/, '')
      name = default if name.empty? 
      @namespace = name
    end  
  
    # Lists all databases on the server
    def databases
      CouchRest.get "#{@uri}/_all_dbs"
    end

    # Returns a CouchRest::Database for the given name
    def database(name)
      CouchRest::Database.new(self, name)
    end

    # Creates the database if it doesn't exist
    def database!(name)
      create_db(name) rescue nil
      database(name)
    end

    # GET the welcome message
    def info
      CouchRest.get "#{@uri}/"
    end

    # Create a database
    def create_db(name)
      CouchRest.put "#{@uri}/#{name}"
      database(name)
    end

    # Restart the CouchDB instance
    def restart!
      CouchRest.post "#{@uri}/_restart"
    end

    # Retrive an unused UUID from CouchDB. Server instances manage caching a list of unused UUIDs.
    def next_uuid(count = @uuid_batch_count)
      @uuids ||= []
      if @uuids.empty?
        @uuids = CouchRest.get("#{@uri}/_uuids?count=#{count}")["uuids"]
      end
      @uuids.pop
    end

  end # Server 
end # Persist::Store
