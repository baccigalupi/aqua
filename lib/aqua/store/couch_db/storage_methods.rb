require 'cgi'
require 'base64'

module Aqua
  module Store
    module CouchDB
      # This module of storage methods was built to be flexible enough to step in as a replacement 
      # for CouchRest core or another super lite CouchDB library. A lot of the methods are added for that
      # convenience, and not for the needs of Aqua. Adding the module to a Mash/Hash class is sufficient
      # to get the full core access library.
      #
      # @see Aqua::Storage for details on the require methods for a storage library.
      module StorageMethods
        
        def self.included( klass ) 
          klass.class_eval do 
            include InstanceMethods
            extend ClassMethods
          end
        end 
        
        module ClassMethods 
          # Initializes a new storage document and saves it without raising any errors
          # 
          # @param [Hash, Mash]
          # @return [Aqua::Storage, false] On success it returns an aqua storage object. On failure it returns false.
          # 
          # @api public
          def create( hash )
            doc = new( hash )
            doc.save
          end
    
          # Initializes a new storage document and saves it raising any errors.
          # 
          # @param [Hash, Mash]
          # @return [Aqua::Storage] On success it returns an aqua storage object. 
          # @raise Any of the CouchDB exceptions
          # 
          # @api public
          def create!( hash )
            doc = new( hash )
            doc.save!
          end
          
          # Sets default database for class. This can be overwritten by individual documents
          # @todo Look to CouchDB database strategy to determine if there is a database per class
          #   or just one big database for all classes
          # 
          # @return [Aqua::Database]
          #
          # @api public
          def database
            @database ||= Database.create # defaults to 'aqua' 
          end 
          
          # Setter for the database per class. Used to override default per class or default strategy. 
          #
          # @return [Aqua::Database]
          #
          # @api public
          def database=( db )
            db = Database.create( db ) if db.class == String
            @database = db
          end
          
          # Gets a document from the database based on id
          # @param [String] id 
          # @return [Hash] representing the CouchDB data
          # @api public
          def get( id )
            resource = begin # this is just in case the developer has already escaped the name
              CouchDB.get( "#{database.uri}/#{CGI.escape(id)}" )
            rescue
              CouchDB.get( "#{database.uri}/#{id}" )  
            end
            new( resource )
          end 
          
          # Will find a document by id, or create it if it doesn't exist. Alias is :get!
          # @param [String] id
          # @return [Hash] representing the CouchDB resource
          # @api public
          def find_or_create( id )
            begin
              get( id )
            rescue
              create!( :id => id )
            end    
          end  
          
          alias :get! :find_or_create
          
          # Retrieves an attachment when provided the document id and attachment id, or the combined id 
          #
          # @return [Tempfile]
          #
          # @api public
          def attachment( document_id, attachment_id )
            new( :id => document_id ).attachments.get!( attachment_id )
          end
          
          # Accessor for maintaining connection to aquatic class
          # @api private
          attr_accessor :parent_class
          alias :design_name=  :parent_class=
          alias :design_name   :parent_class 
          
          # Finds or creates design document based on aqua parent class name
          # @api semi-private 
          def design_document( reload=false )
            @design_document = nil if reload 
            @design_document ||= design_name ? DesignDocument.find_or_create( design_name ) : nil
          end  
          
          # Stores stores a map name for a given index, allowing the same map 
          # to be used for various reduce functions. This means only one index is created.
          # @param [String] field being indexed, or the sub field
          # @param [Hash, Mash] Hash of functions used to create views
          # @option opts [String] :map Javascript/CouchDB map function
          # @option opts [String] :reduce Javascript/CouchDB reduce function
          # 
          # @api public 
          def index_on( field, opts={} )
            opts = Mash.new( opts )
            design_document(true).add!( opts.merge!(:name => field) )
            unless indexes.include?( field )
              indexes << field.to_sym  
              indexes << field.to_s 
            end  
            self     
          end
          
          # A list of index names that can be used to build other reduce functions.
          # @api semi-private
          def indexes
            @indexes ||= []
          end
          
          # @api public
          def query( index, opts={} )
            raise ArgumentError, 'Index not found' unless views.include?( index.to_s )
            opts = Mash.new(opts)
            opts.merge!(:document_class => self) unless opts[:document_class]
            opts.merge!(:reduced => design_document.views[index][:reduce] ? true : false )
            design_document.query( index, opts )
          end 
          
          def reduced_query( reduce_type, index, opts)
            view =  "#{index}_#{reduce_type}" 
            unless views.include?( view )
              design_document(true).add!(
                :name => view, 
                :map => design_document.views[ index.to_s ][:map],
                :reduce => opts[:reduce]
              )
            end  
            query( view, opts.merge!( :select => "index only" ) )
          end  
          
          # @api semi-private
          def views
            design_document.views.keys
          end
          
          # @api public
          def count( index, opts={} )
            opts = Mash.new(opts)
            opts[:reduce] = "
              function (key, values, rereduce) {
                  return sum(values);
              }" unless opts[:reduce]
            reduced_query(:count, index, opts)
          end
          
          # @api public
          def sum( index, opts={} )
            opts = Mash.new(opts)
            opts[:reduce] = "
              function (keys, values, rereduce) {
                var key_values = []
                keys.forEach( function(key) {
                  key_values[key_values.length] = key[0]
                });
                return sum( key_values );
              }" unless opts[:reduce]
            reduced_query(:sum, index, opts)
          end
          
          def average( index, opts={} )
            sum(index, opts) / count(index, opts).to_f
          end 
          
          alias :avg :average
          
          def min( index, opts={} )
            opts = Mash.new(opts)
            opts[:reduce] = "
              function (keys, values, rereduce) {
                var key_values = []
                keys.forEach( function(key) {
                  key_values[key_values.length] = key[0]
                });
                return Math.min.apply( Math, key_values ); ;
              }" unless opts[:reduce]
            reduced_query(:min, index, opts)
          end
          
          alias :minimum :min
          
          def max( index, opts={} )
            opts = Mash.new(opts)
            opts[:reduce] = "
              function (keys, values, rereduce) {
                var key_values = []
                keys.forEach( function(key) {
                  key_values[key_values.length] = key[0]
                });
                return Math.max.apply( Math, key_values ); ;
              }" unless opts[:reduce]
            reduced_query(:max, index, opts)
          end 
          
          alias :maximum :max
               
             
        end     
        
        module InstanceMethods
          # Initializes a new storage document. 
          # 
          # @param [Hash, Mash]
          # @return [Aqua::Storage] a Hash/Mash with some extras
          #
          # @api public
          def initialize( hash={} )
            hash = Mash.new( hash ) unless hash.empty?
            self.id = hash.delete(:id) if hash[:id]
          
            do_rev( hash )
            hash.delete(:_id)   # this is set via by the id=(value) method 
            
            # feed the rest of the hash to the super 
            super( hash )      
          end
          
          # Temporary hack to allow design document refresh from within a doc.
          # @todo The get method has to handle rev better!!!
          def do_rev( hash )
            hash.delete(:rev)   # This is omited to aleviate confusion
            hash.delete(:_rev)  # CouchDB determines _rev attribute
          end   
        
          # Saves an Aqua::Storage instance to CouchDB as a document. Save can be deferred for bulk saving.
          #
          # @param [optional true, false] Determines whether the document is cached for bulk saving later. true will cause it to be defered. Default is false.
          # @return [Aqua::Storage, false] Will return false if the document is not saved. Otherwise it will return the Aqua::Storage object.
          #
          # @api public
          def save( defer=false )
            save_logic( defer )  
          end 
        
          # Saves an Aqua::Storage instance to CouchDB as a document. Save can be deferred for bulk saving from the database.
          # Unlike #save, this method will raise an error if the document is not saved.
          # 
          # @param [optional true, false] Determines whether the document is cached for bulk saving later. true will cause it to be defered. Default is false.
          # @return [Aqua::Storage] On success.
          #
          # @api public
          def commit( defer=false )
            save_logic( defer, false )
          end
          alias :save! :commit 
        
          # Internal logic used by save, save! and commit to save an object.
          #
          # @param [optional true, false] Determines whether a object cached for save in the database in bulk. By default this is false.
          # @param [optional true, false] Determines whether an exception is raised or whether false is returned.
          # @return [Aqua::Storage, false] Depening on the type of execption masking and also the outcome
          # @raise Any of the CouchDB execptions.
          #
          # @api private
          def save_logic( defer=false, mask_exception = true )
            ensure_id
            self[:_attachments] = attachments.pack unless attachments.empty?
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
        
          # Internal logic used by save_logic to save an object immediately instead of deferring for bulk save.
          #
          # @param [optional true, false] Determines whether an exception is raised or whether false is returned.
          # @return [Aqua::Storage, false] Depening on the type of execption masking and also the outcome
          # @raise Any of the CouchDB execptions.
          #
          # @api private
          def save_now( mask_exception = true ) 
            begin
              result = CouchDB.put( uri, self )
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
        
          # couchdb database url for this document
          # @return [String] representing CouchDB uri for document 
          # @api public
          def uri
            database.uri + '/' + ensure_id
          end 
          
          # retrieves self from CouchDB database
          # @return [Hash] representing the CouchDB data
          # @api public
          def retrieve
            self.class.get( id )
          end 
          
          alias :reload :retrieve
          
          # reloads self from CouchDB database
          # @return [Hash] representing CouchDB data
          # @api public
          def reload
            self.replace( CouchDB.get( uri ) )
          end   
        
          # Deletes an document from CouchDB. Delete can be deferred for bulk saving/deletion.
          #
          # @param [optional true, false] Determines whether the document is cached for bulk saving later. true will cause it to be defered. Default is false.
          # @return [String, false] Will return a json string with the response if successful. Otherwise returns false.
          #
          # @api public
          def delete(defer = false)
            delete_logic( defer )
          end
        
          # Deletes an document from CouchDB. Delete can be deferred for bulk saving/deletion. This version raises an exception if an error other that resource not found is raised.
          #
          # @param [optional true, false] Determines whether the document is cached for bulk saving later. true will cause it to be defered. Default is false.
          # @return [String, false] Will return a json string with the response if successful. It will return false if the resource was not found. Other exceptions will be raised.
          # @raise Any of the CouchDB exceptions
          #
          # @api public
          def delete!(defer = false)
            delete_logic( defer, false ) 
          end
        
          # Internal logic used by delete and delete! to delete a resource.
          #
          # @param [optional true, false] Determines whether resource is deleted immediately or saved for bulk processing.
          # @param [optional true, false] Determines whether an exception is raised or whether false is returned.
          # @return [String, false] Depening on the type of execption masking and also the outcome
          # @raise Any of the CouchDB execptions.
          #
          # @api private
          def delete_logic( defer = false, mask_exceptions = true )
            if defer
              database.add_to_bulk_cache( { '_id' => self['_id'], '_rev' => rev, '_deleted' => true } )
            else
              begin
                delete_now
              rescue Exception => e
                if mask_exceptions || e.class == CouchDB::ResourceNotFound
                  false
                else 
                  raise e
                end    
              end  
            end 
          end  
        
          # Internal logic used by delete_logic delete a resource immediately.
          #
          # @return [String, false] Depening on the type of execption masking and also the outcome
          # @raise Any of the CouchDB execptions.
          #
          # @api private
          def delete_now
            revisions.each do |rev_id| 
              CouchDB.delete( "#{uri}?rev=#{rev_id}" )
            end
            true   
          end
          
          # Gets revision history, which is needed by Delete to remove all versions of a document
          # 
          # @return [Array] Containing strings with revision numbers
          # 
          # @api semi-private
          def revisions
            active_revisions = []
            begin
              hash = CouchDB.get( "#{uri}?revs_info=true" )
            rescue
              return active_revisions
            end    
            hash['_revs_info'].each do |rev_hash|
              active_revisions << rev_hash['rev'] if ['disk', 'available'].include?( rev_hash['status'] )
            end
            active_revisions  
          end  
             
        
          # sets the database
          # @param   [Aqua::Store::CouchDB::Database]
          # @return [Aqua::Store::CouchDB::Database]
          # @api private
          attr_writer :database 
        
          # retrieves the previously set database or sets the new one with a default value
          # @return [Aqua::Store::CouchDB::Database]
          # @api private
          def database
            @database ||= determine_database
          end  
        
          # Looks to class for database information about how the CouchDB store has generally
          # been configured to store its data across databases and/or servers. In some cases the class for
          # the parent object has configuration details about the database and server to use.
          # @todo Build the strategies in CouchDB. Use them here
          # @api private
          def determine_database
            self.class.database    
          end  
        
          # setters and getters couchdb document specifics -------------------------
          
          # Gets the document id. In this engine id and _id are different data. The main reason for this is that
          # CouchDB needs a relatively clean string as the key, where as the user can assign a messy string to
          # the id. The user can continue to use the messy string since the engine also has access to the _id.
          # 
          # @return [String]
          #
          # @api public 
          def id
            self[:id]
          end
          
          # Allows the id to be set. If the id is changed after creation, then the CouchDB document for the old
          # id is deleted, and the _rev is set to nil, making it a new document. The id can only be a string (right now).
          #
          # @return [String, false] Will return the string it received if it is indeed a string. Otherwise it will
          # return false.
          #
          # @api public 
          def id=( str )
            if str.respond_to?(:match)
              escaped = CGI.escape( str )
              
              # CLEANUP: do a bulk delete request on the old id, now that it has changed
              delete(true) if !new? && escaped != self[:_id]
              
              self[:id] = str
              self[:_id] = escaped 
              str 
            end  
          end  
    
          # Returns CouchDB document revision identifier.
          # 
          # @return [String]
          #
          # @api semi-public
          def rev
            self[:_rev]
          end
    
          protected 
            def rev=( str )
              self[:_rev] = str
            end   
          public 
          
          # Updates the id and rev after a document is successfully saved.
          # @param [Hash] Result returned by CouchDB document save
          # @api private
          def update_version( result ) 
            self.id     = result['id']
            self.rev    = result['rev']
          end  
    
          # Returns true if the document has never been saved or false if it has been saved.
          # @return [true, false]
          # @api public
          def new?
            !rev
          end
          alias :new_document? :new? 
        
          # Returns true if a document exists at the CouchDB uri for this document. Otherwise returns false
          # @return [true, false]
          # @api public
          def exists?
            begin 
              CouchDB.get uri
              true
            rescue
              false
            end    
          end  
        
          # gets a uuid from the server if one doesn't exist, otherwise escapes existing id.
          # @api private
          def ensure_id
            self[:_id] = ( id ? escape_doc_id : database.server.next_uuid )
          end 
          
          # Escapes document id. Different strategies for design documents and normal documents.
          # @api private
          def escape_doc_id 
            CGI.escape( id )
          end
          
          # Hash of attachments, keyed by name
          # @params [Document] Document object that is self
          # @return [Hash] Attachments keyed by name
          # 
          # @api public
          def attachments
            @attachments ||= Attachments.new( self )
          end  
            
        end # InstanceMethods           
        
      end # StoreMethods
    end # CouchDB
  end # Store
end # Aqua     