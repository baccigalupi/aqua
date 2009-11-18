# This module is responsible for packing objects into Storage Objects
# The Storage Object is expected to be a Mash-Like thing (Hash with indifferent access).
# It is the job of the storage engine to convert the Mash into the actual storage ivars.
module Aqua
  module Pack
  
    def self.included( klass ) 
      klass.class_eval do
        extend HiddenAttributes::ClassMethods
        include HiddenAttributes::InstanceMethods
        extend ClassMethods
        include InstanceMethods
      
        unless instance_methods.include?( 'id=' ) # || new.instance_variables.include?( '@id' )
          attr_accessor :id
        end
      
        hide_attributes :_store, :__pack, :id, :_rev, :_translator 
      end  
    end
  
    module HiddenAttributes
      def self.included( klass ) 
        klass.class_eval do
          extend ClassMethods
          include InstanceMethods
        end
      end
          
      module ClassMethods
        # Reader method for accessing hidden attributes. 
        # @return [Array] containing strings representing instance variables
        # @api private
        def _hidden_attributes 
          @_hidden_attributes ||= []
        end
      
        # Used in class declaration to assign certain instance variables as not for persistance
        # @param [Symbol] or [Array of Symbols] ivars 
        # 
        # @example
        # class User 
        #   include Aqua::Object
        #   attr_accessor :username, :email, :password, :password_confirmation, :cryped_password, :salt
        #   hide_attributes :password, :password_confirmation 
        #   # ... lots more user code here ...
        # end
        # In this case it is useful for omitting sensitive information while persisting the object, but 
        # maintaining the password and confirmation temporarily requires the use of instance variables.
        def hide_attributes( *ivars )
          ivars.each do |ivar|
            raise ArgumentError, '' unless ivar.class == Symbol
            _hidden_attributes << "@#{ivar}" unless _hidden_attributes.include?( "@#{ivar}" )
          end  
        end 
      end # ClassMethods  
     
      module InstanceMethods 
        # An array of instance variables that are not hidden.
        # @return [Array] of names for instance variables
        # 
        # @api private
        def _storable_attributes
          (instance_variables||[]) - self.class._hidden_attributes
        end 
      end # InstanceMethods     
    end   
    
    module ClassMethods  
    end # ClassMethods
  
    module InstanceMethods
      # TODO: option for transaction on children documents, all or nothing
    
      # Saves object; returns false on failure; returns self on success.
      def commit 
        _commit
      end
    
      # Saves object and raises an error on failure
      def commit!
        _commit( false )
      end
    
      # packs an object from it's Ruby state into a Hash-like object for storage. 
      # @return [Storage]
      #
      # @api private
      def _pack
        class_name = self.class.to_s
        self.__pack = Storage.new
        self.__pack.id = @id if @id
        self.__pack[:_rev] = _rev if _rev 
        self.__pack.merge!( _translator.pack_object( self ) ) 
        _pack_attachments
        __pack
      end
      
      def _pack_attachments 
        _translator.attachments.each do |file|
          self.__pack.attachments.add( file.filename, file )
        end  
      end   
      
      # Translator object responsible for packing the object and keeping track of externally
      # stored records and also attachments
      # @return [Translator]
      # 
      # @api private
      def _translator
        @_translator ||= Translator.new( self )
      end  
    
      # Details from configuration options for the objects class about embedability. 
      # @return [true, false, Hash] If true then it should be embedded in the object at hand. 
      #   If false, then it should be saved externally. If a hash, with the key :stub and a related
      #   value that is an array of methods, then the object should be saved externally, 
      #   with a few cached methods as defined in the array.
      # 
      # @api private
      def _stubbed_methods 
        meths = !_embedded? && self.class._aqua_opts[:embed] && self.class._aqua_opts[:embed][:stub]
        meths ? [meths].flatten : []
      end 
      
      # Details from configuration options for the objects class about embedability. 
      # @return [true, false] If true then it should be embedded in the base object. 
      #   If false, then it should be saved externally. 
      # 
      # @api private
      def _embedded? 
        self.class._aqua_opts[:embed] == true
      end 
      
      attr_accessor :_warnings, :_rev 
       
      # Private/protected methods are all prefaced by an underscore to prevent
      # clogging the object instance space. Some of the public ones above are too!
      protected
      
        # __pack is an Storage object into which the object respresentation is packed
        #
        # _store is the current state of the storage of the object on CouchDB. It is used lazily
        # and will be empty unless it is needed for unpacking or checking for changed data.
        #
        # _rev is needed for CouchDB store, since updates require the rev information. We could
        # do without this accessor, but it would mean that an extra get request would have to be
        # made with each PUT request so that the latest _rev could be obtained. 
        #
        attr_accessor :_store, :__pack
      
      private
      
        def _commit( mask_exception = true ) 
          result = true
          begin
            _pack
            _save_to_store
          rescue Exception => e
            if mask_exception
              result = false
            else
              raise e
            end    
          end
          if result
            self.id =   __pack.id
            self._rev = __pack.rev
            _clear_aqua_accessors
            self
          else
            result
          end    
        end    
       
        # Saves all self and nested object requiring independent saves
        # 
        # @return [Object, false] Returns false on failure and self on success.
        #
        # @api private
        def _save_to_store
          self._warnings = []
          _commit_externals 
          __pack.commit # TODO: need to add some error catching and roll back the external saves where needed
        end
      
        # Saves nested object requiring independent saves. Adds warning messages to _warnings, when a save fails.
        #
        # @api private
        def _commit_externals 
          _translator.externals.each do |obj, path|
            if obj.commit
              _update_external_id( path, obj.id )
            else
              self._warnings << ( obj.id ? 
                 "Unable to save latest version of #{obj.inspect}, stubbed at #{path}" :
                 "Unable to save #{obj.inspect}, stubbed at #{path}" 
              )
            end    
          end  
        end 
        
        # When external objects are saved to the base object, ids need to be updated after save
        # This is the method used to locate the original id and updated it
        # 
        # @param [String] path to external
        # @param [String] id to save
        # 
        # @api private
        def _update_external_id( path, new_id )
          __pack.instance_eval "self#{path}['init']['id'] = '#{new_id}'"
        end    

      
        # clears the __pack and _store accessors to save on memory after each pack and unpack
        # 
        # @api private
        def _clear_aqua_accessors
          self.__pack = nil
          self._store = nil
          @_translator = nil
        end
              
      public  
    end # InstanceMethods     
  end # Pack
  

end # Aqua 
  