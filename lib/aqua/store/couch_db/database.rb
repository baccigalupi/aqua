require "base64"

module Aqua 
  module Store
    module CouchDB
      class Database
        attr_reader :server, :host, :name, :uri, :path
        attr_accessor :bulk_cache
     
        # Create a database representation from a name. Does not actually create a database on couchdb
        # does not ensure that the database actually exists either. Just creates a ruby representation
        # of a possible database. 
        #  
        # ==== Parameters
        # server<Aqua::Store::CouchDB::Server>:: database host
        # name<String>:: database name
        #
        def initialize( name, opts={})
          opts = Mash.new( opts ) unless opts.empty?
          @name = name
          @server = (opts[:server] || CouchDB.server || Server.new)
          @host =   @server.uri
          @path =   "/#{namespaced(CouchDB.escape(@name))}"
          @uri =    @host + @path
          # @streamer = Streamer.new(self) # TODO: add this in
          @bulk_cache = []
        end 
    
        def namespaced( name ) 
          server.namespaced( name )
        end  
    
        def self.create( name, opts={} )
          db = new(name, opts)
          begin
            CouchDB.put( db.uri )
          rescue Exception => e # catch database already exists errors ... 
            raise e unless e.class == RequestFailed && e.message.match(/412/) 
          end
          db    
        end
    
        # checks to see if the database exists on the couchdb server
        def exists?
          begin 
            info 
            true
          rescue CouchDB::ResourceNotFound  
            false
          end  
        end  
    
        # returns the database's uri
        def to_s
          uri
        end
    
        # GET the database info from CouchDB
        def info
          CouchDB.get( uri )
        end
     
        # DELETE the database. Use with caution as it cannot be undone!
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
