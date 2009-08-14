require 'cgi'
require 'base64'

module Persist
  class Document < Mash
    attr_reader :database 
    # not sure what the performance and memory hit of storing the whole database object will be :(
    
    def initialize( database, hash={} )
      if database.class == Database
        @database = database
      else
        raise ArgumentError, 'First argument must be Persist::Database, whatcha doin?'
      end 
      hash = Mash.new( hash ) unless hash.empty?
      self.id = hash.delete(:id)
      hash.delete(:rev) # and don't save it anywhere, thank you! 
      hash.delete(:_rev)
      hash.delete(:_id)
      super( hash )      
    end 
     
    def self.create( db, hash )
      doc = new( db, hash )
      doc.save
    end
    
    def self.create!( db, hash )
      doc = new( db, hash )
      doc.save!
    end  
    
    # Saves a document to CouchDB. This will use the <tt>_id</tt> field from
    # the document as the id for PUT, or request a new UUID from CouchDB, if
    # no <tt>_id</tt> is present on the document. IDs are attached to
    # documents on the client side because POST has the curious property of
    # being automatically retried by proxies in the event of network
    # segmentation and lost responses.
    #
    # If <tt>defer</tt> is true (false by default) the document is cached for bulk-saving later.
    # The Database object handles timing on bulk saves, see more details there
    def save( defer=false )
      save_logic( defer )  
    end
    
    def save!( defer=false )
      save_logic( defer, false )
    end
    
    def save_logic( defer=false, mask_exception = true )
      encode_attachments if self[:_attachment] 
      ensure_id
      if defer
        database.add_to_bulk_cache( self )
      else
        # clear any bulk saving left over ...
        database.bulk_save if database.bulk_cache.size > 0
        if mask_exception
          save_now
        else
          save_now( false )
        end       
      end 
    end     
    
    def save_now( mask_exception = true ) 
      begin 
        result = Persist.put( uri, self )
      rescue Exception => e
        if mask_exception
          result = false
        else
          raise e
        end    
      end
          
      if result && result['ok']
        update_version( result )
        self
      else    
        result 
      end 
    end   
    
    # setters and getters couchdb document specifics -------------------------
    def id
      self[:_id]
    end
    
    def id=( str )
      self[:_id] = str
    end  
    
    def rev
      self[:_rev]
    end
    
    protected 
      def rev=( str )
        self[:_rev] = str
      end   
    public 
    
    def update_version( result ) 
      self.id  = result['id']
      self.rev = result['rev']
    end  
    
    # returns true if the document has never been saved
    def new_document?
      !rev
    end
    
    # couchdb database url for this document
    def uri
      database.uri + '/' + escape_doc_id
    end
    
    # gets a uuid from the server if one doesn't exist, otherwise escapes existing uuid
    def ensure_id
      self[:_id] = id ? escape_doc_id : database.server.next_uuid
    end 
    
    def escape_doc_id
      self[:_id].match(/^_design\/(.*)/) ? "_design/#{CGI.escape($1)}" : CGI.escape(id)
    end  

    def encode_attachments(attachments)
      attachments.each do |key, value|
        next if value['stub']
        value['data'] = base64(value['data'])
      end
      attachments
    end

    def base64(data)
      Base64.encode64(data).gsub(/\s/,'')
    end       
    
  end # Document
end # Persist 