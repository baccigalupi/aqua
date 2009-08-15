require "base64"

module Persist
  class Database
    attr_reader :server, :host, :name, :uri, :path
    attr_accessor :bulk_cache
     
    # Create a database representation from a name. Does not actually create a database on couchdb
    # does not ensure that the database actually exists either. Just creates a ruby representation
    # of a possible database. 
    #  
    # ==== Parameters
    # server<Persist::Server>:: database host
    # name<String>:: database name
    #
    def initialize( name, opts={})
      opts = Mash.new( opts ) unless opts.empty?
      @name = name
      @server = (opts[:server] || Persist.server || Server.new)
      @host =   @server.uri
      @path =   "/#{namespaced(Persist.escape(@name))}"
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
        Persist.put( db.uri )
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
      rescue Persist::ResourceNotFound  
        false
      end  
    end  
    
    # returns the database's uri
    def to_s
      uri
    end
    
    # GET the database info from CouchDB
    def info
      Persist.get( uri )
    end
     
    # DELETE the database. Use with caution as it cannot be undone!
    def delete!
      Persist.delete( uri )
    end  
    
    # # Query the <tt>_all_docs</tt> view. Accepts all the same arguments as view.
    def documents(params = {})
      keys = params.delete(:keys)
      url = Persist.paramify_url( "#{uri}/_all_docs", params )
      if keys
        Persist.post(url, {:keys => keys})
      else
        Persist.get url
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
      Persist.post( "#{uri}/_bulk_docs", {:docs => docs} )
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
    #   url = Persist.paramify_url "#{@root}/_temp_view", params
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
    #   url = Persist.paramify_url "#{@root}/_design/#{dname}/_view/#{vname}", params
    #   if keys
    #     Persist.post(url, {:keys => keys})
    #   else
    #     if block_given?
    #       @streamer.view("_design/#{dname}/_view/#{vname}", params, &block)
    #     else
    #       Persist.get url
    #     end
    #   end
    # end
    # 
    # # GET a document from CouchDB, by id. Returns a Ruby Hash.
    # def get(id, params = {})
    #   slug = escape_docid(id)
    #   url = Persist.paramify_url("#{@root}/#{slug}", params)
    #   result = Persist.get(url)
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
    # # GET an attachment directly from CouchDB
    # def fetch_attachment(doc, name)
    #   uri = url_for_attachment(doc, name)
    #   HttpAbstraction.get uri
    # end
    # 
    # # PUT an attachment directly to CouchDB
    # def put_attachment(doc, name, file, options = {})
    #   docid = escape_docid(doc['_id'])
    #   name = CGI.escape(name)
    #   uri = url_for_attachment(doc, name)
    #   JSON.parse(HttpAbstraction.put(uri, file, options))
    # end
    # 
    # # DELETE an attachment directly from CouchDB
    # def delete_attachment(doc, name, force=false)
    #   uri = url_for_attachment(doc, name)
    #   # this needs a rev
    #   begin
    #     JSON.parse(HttpAbstraction.delete(uri))
    #   rescue Exception => error
    #     if force
    #       # get over a 409
    #       doc = get(doc['_id'])
    #       uri = url_for_attachment(doc, name)
    #       JSON.parse(HttpAbstraction.delete(uri))
    #     else
    #       error
    #     end
    #   end
    # end
    # 
    
    # # COPY an existing document to a new id. If the destination id currently exists, a rev must be provided.
    # # <tt>dest</tt> can take one of two forms if overwriting: "id_to_overwrite?rev=revision" or the actual doc
    # # hash with a '_rev' key
    # def copy_doc(doc, dest)
    #   raise ArgumentError, "_id is required for copying" unless doc['_id']
    #   slug = escape_docid(doc['_id'])        
    #   destination = if dest.respond_to?(:has_key?) && dest['_id'] && dest['_rev']
    #     "#{dest['_id']}?rev=#{dest['_rev']}"
    #   else
    #     dest
    #   end
    #   Persist.copy "#{@root}/#{slug}", destination
    # end
    # 
    # ### DEPRECATION NOTICE
    # def copy(doc, dest)
    #   puts "Persist::Database's copy method is being deprecated, please use copy_doc instead"
    #   copy_doc(doc, dest)
    # end
    # 
    # # Compact the database, removing old document revisions and optimizing space use.
    # def compact!
    #   Persist.post "#{@root}/_compact"
    # end
    # 
    # # Create the database
    # def create!
    #   bool = server.create_db(@name) rescue false
    #   bool && true
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
    #   raise ArgumentError, "must provide a CouchReset::Database" unless other_db.kind_of?(Persist::Database)
    #   Persist.post "#{@host}/_replicate", :source => other_db.root, :target => name
    # end
    # 
    # # Replicates via "pushing" to another database. Makes no attempt to deal with conflicts.
    # def replicate_to other_db
    #   raise ArgumentError, "must provide a CouchReset::Database" unless other_db.kind_of?(Persist::Database)
    #   Persist.post "#{@host}/_replicate", :target => other_db.root, :source => name
    # end
    # 
    # # DELETE the database itself. This is not undoable and could be rather
    # # catastrophic. Use with care!
    # def delete!
    #   clear_extended_doc_fresh_cache
    #   Persist.delete @root
    # end
    # 
    # private
    # 
    # def clear_extended_doc_fresh_cache
    #   ::Persist::ExtendedDocument.subclasses.each{|klass| klass.design_doc_fresh = false if klass.respond_to?(:design_doc_fresh=) }
    # end
    # 
    # def uri_for_attachment(doc, name)
    #   if doc.is_a?(String)
    #     puts "Persist::Database#fetch_attachment will eventually require a doc as the first argument, not a doc.id"
    #     docid = doc
    #     rev = nil
    #   else
    #     docid = doc['_id']
    #     rev = doc['_rev']
    #   end
    #   docid = escape_docid(docid)
    #   name = CGI.escape(name)
    #   rev = "?rev=#{doc['_rev']}" if rev
    #   "/#{docid}/#{name}#{rev}"
    # end
    # 
    # def url_for_attachment(doc, name)
    #   @root + uri_for_attachment(doc, name)
    # end
    # 
    # def escape_docid id      
    #   /^_design\/(.*)/ =~ id ? "_design/#{CGI.escape($1)}" : CGI.escape(id) 
    # end
    # 
    # def encode_attachments(attachments)
    #   attachments.each do |k,v|
    #     next if v['stub']
    #     v['data'] = base64(v['data'])
    #   end
    #   attachments
    # end
    # 
    # def base64(data)
    #   Base64.encode64(data).gsub(/\s/,'')
    # end  
  end
end
