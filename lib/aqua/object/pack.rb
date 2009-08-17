# This module is responsible for packing objects into Storage Objects
# The Storage Object is expected to be a Mash-Like thing (Hash with indifferent access).
# It is the job of the storage engine to convert the Mash into the actual storage data.
module Aqua::Pack
  
  def self.included( klass ) 
    klass.class_eval do
      extend ClassMethods
      include InstanceMethods
      
      # TODO: these should be protected as well as hidden
      attr_accessor :_store, :__pack
      hide_instance_variables :_store, :__pack 
    end  
  end 
  
  module ClassMethods 
    # Used in class declaration to assign certain instance variables as not for persistance
    # @params [Symbol] or [Array of Symbols] ivars 
    # 
    # @example
    # class User 
    #   include Aqua::Object
    #   attr_accessor :username, :email, :password, :password_confirmation, :cryped_password, :salt
    #   hide_instance_variables :password, :password_confirmation 
    #   # ... lots more user code ...
    # end
    # In this case it is useful for omitting sensitive information while persisting the object, but 
    # maintaining the password and confirmation temporarily requires the use of instance variables.
    def hide_instance_variables( *ivars )
      ivars.each do |ivar|
        raise ArgumentError, '' unless ivar.class == Symbol
        _unsaved_instance_variables << ivar
      end  
    end
    
    def _unsaved_instance_variables 
      @_unsaved_instance_variables ||= []
    end 
          
  end # ClassMethods
  
  module InstanceMethods
    # Saves object; returns false on failure; returns self on success.
    def commit 
      _commit
    end
    
    # Saves object and raises an error on failure
    def commit!
      _commit( false )
    end
    
    # Private methods are all prefaced by an underscore to prevent
    # clogging the object instance space.
    private
      def _commit( mask_exception = true ) 
        result = true
        begin
          _pack
          _save_to_store
          _clear__pack 
        rescue Exception => e
          if mask_exception
            result = false
          else
            raise e
          end    
        end
        result ? self : result    
      end    
      
      def _pack
        class_name = self.class.to_s
        self.__pack = Aqua::Storage.new
        self.__pack[:class] = class_name
        _pack_properties
        _pack_singletons
      end
      
      def _pack_properties
        self.__pack[:properties] = {}
        ( (instance_variables||[]) - self.class._unsaved_instance_variables ).each do |ivar| 
          value = instance_variable_get( ivar ) 
          puts ivar.inspect
          puts value.inspect
          # TODO more logic should be here to determine whether 
          # a variable is appropriate for internal storage
          self.__pack[:properties][ivar] = value
        end  
      end
      
      def _pack_singletons
      end    
      
      def _save_to_store 
        # self._doc = Aqua::Document.new ...
        # _doc.commit # with exception catching et. al.
      end
      
      def _clear__pack
        self.__pack = nil
      end    
    public  
  end # InstanceMethods     
  
end # Aqua::Pack 
  