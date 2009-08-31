require 'mime/types'
require 'tempfile'

module Aqua
  module Store
    module CouchDB 
      # Attachments is a Hash-like container with keys that are attacment names and values that are file-type
      # objects. Initializing and adding to the collection assures the types of both keys and values. The 
      # collection implements a lazy-loading scheme, such that when an attachment is requested and not found,
      # it will try to load it from CouchDB.
      class Attachments < Mash
        attr_reader :document
        attr_reader :stub
        
        # Creates a new attachment collection with keys that are attachment names and values that are
        # file-type objects. The collection manages both the key and the value types.
        # 
        # @param [String] Document uri; used to save and retrieve attachments directly
        # @param [Hash] Initialization values
        #
        # @api public 
        def initialize( doc, hash={} )
          raise ArgumentError, "must be initialized with a document" unless doc.respond_to?( :retrieve ) 
          @document = doc
          self.class.validate_hash( hash ) unless hash.empty?
          super( hash )
        end  
        
        # Adds an attachment to the collection, checking for type. Does not add directly to the database.
        #
        # @param [String, Symbol] Name of the attachment as a string or symbol
        # @param [File] The attachment
        #
        # @api public
        def add( name, file )
          self.class.validate_hash( name => file )
          self[name] = file
        end 
        
        # Adds an attachment to the collection and to the database. Document doesn't have to be saved, 
        # but it does need to have an id.
        #
        # @param [String, Symbol] Name of the attachment as a string or symbol
        # @param [File] The attachment
        #
        # @api public
        def add!( name, file )
          add( name, file )
          content_type = MIME::Types.type_for(file.path) 
          content_type = content_type.empty? ? 'text\/plain' : content_type
          data = {
            'content-type' => content_type,
            'data'         => Base64.encode64( file.read ).gsub(/\s/,'') 
          }
          response = CouchDB.put( uri_for( name ), data )
          update_doc_rev( response )
          file
        end  
        
        # Deletes an attachment from the collection, and from the database. Use #delete (from Hash) to just
        # delete the attachment from the collection.
        # 
        # @param [String, Symbol] Name of the attachment as a string or symbol
        # @return [File, nil] File at that location or nil if no file found
        # 
        # @api public
        def delete!( name )
          if self[name]
            file = delete( name ) 
            unless document.new?
              CouchDB.delete( uri_for( name ) )
            end 
            file 
          end  
        end
        
        # Gets an attachment from the collection first. If not found, it will be requested from the database.
        #
        # @param [String, Symbol] Name of the attachment
        # @return [File, nil] File for that name, or nil if not found in hash or in database
        #
        # @api public
        def get( name, stream=false )
          file = self[name] 
          unless file
            file = get!( name, stream )
          end
          file  
        end  
        
        # Gets an attachment from the database. Stores it in the hash.
        #
        # @param [String, Symbol] Name of the attachment
        # @param [true, false] Stream boolean flag indicating whether the data should be converted to 
        #   a file or kept as a stream
        # @return [File, nil] File for that name, or nil if not found in the database 
        # @raise Any error encountered on retrieval of the attachment, json, http_client, Aqua etc
        # 
        # @todo make this more memory favorable, maybe streaming/saving in a max number of bytes
        # @api public
        def get!( name, stream=false ) 
          file = nil
          response = CouchDB.get( uri_for( name, false ) ) rescue nil
          data = Base64.decode64( response['data'] ) if response 
          if data
            file = Tempfile.new( CGI.escape( name.to_s ) ) 
            file.binmode if file.respond_to?( :binmode )
            file.write( data )
            file.rewind 
            self[name] = file
          end  
          stream ? file.read : file
        end  
        
        # Constructs the standalone attachment uri for PUT and DELETE actions.
        # 
        # @param [String] Name of the attachment as a string or symbol
        # 
        # @api private
        def uri_for( name, include_rev = true )
          raise ArgumentError, 'Document must have id in order to save an attachment' if document.id.nil? || document.id.empty?
          document.uri + "/#{CGI.escape( name.to_s )}" + ( document.rev && include_rev ? "?rev=#{document.rev}" : "" )
        end
        
        
        # Validates and throws an error on a hash, insisting that the key is a string or symbol, 
        # and the value is a file. 
        #
        # @param [Hash]
        #
        # @api private
        def self.validate_hash( hash )
          hash.each do |name, file|
            raise ArgumentError, "Attachment name, #{name.inspect}, must be a Symbol or a String" unless [Symbol, String ].include?( name.class )
            raise ArgumentError, "Attachment file, #{file.inspect}, must be a File-like object"  unless file.respond_to?( :read ) 
          end  
        end 
        
        # Goes into the document and updates it's rev to match the returned rev. That way #new? will return false
        # when an attachment is created before the document is saved. It also means that future attempts to save 
        # the doc won't fail with a conflict.
        #
        # @param [Hash] response from the put request
        # @api private
        def update_doc_rev( response )
          document[:_rev] = response['rev']
        end  
         
      end # Attachments
    end # CouchDB
  end # Store
end # Aqua        