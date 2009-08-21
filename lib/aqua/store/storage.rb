# This is the interface between an individual object and the Storage representation.
# The storage engine should provide a module that gets included into the Mash. The 
# module should minimally provide this interface to the object:
#
#   InstanceMethods
#     @inteface_level optional If no initialization is included. Then the Mash initialization will be used.
#     initialize( hash )
#       @param [optional Hash]
#       @return [Aqua::Storage] the new storage instance
#     
#     @interface_level mandatory
#     commit
#       @return [Aqua::Storage] saved storage object
#       @raise [Aqua::ObjectNotFound] if another error occurs in the engine, that should be raised instead 
#         any of the Aqua Exceptions 
# 
#     @interface_level mandatory
#     id
#       @param none
#       @return id object, whether String, Fixnum or other object as the store chooses
# 
#     @interface_level mandatory
#     id=( custom_id )
#       The library expects to save an object with a custom id. Id= method can set limits on the 
#       types of objects that can be used as an id. Minimally it should support Strings. 
#       @param String, Fixnum, or any other reasonable class
#
#     @interface_level mandatory
#     new?
#       The equivalent of AR's new_record? and can be used to set create hooks or determine how to handle
#       object queries about whether it has changed. 
#       @return [true, false]
#   
#    ClassMethods
#     @interface_level mandatory
#     load( id, class ) 
#       The'load'  
#       @param [String, Fixnum] The id used by the system to 
#       @return [Aqua::Storage]
#       @raise [Aqua::ResourceNotFound] if another error occurs in the engine, that should be raised instead 
#         any of the Aqua Exceptions 
#
# Other methods used for the storage engine can be added as needed by the engine. 
#
# If no storage engine is configured before this class is used, CouchDB will automatically be used
# as an engine.
module Aqua
  class Storage < Mash 
    # auto loads the default store to CouchDB if Store is used without Aqua configuration of a store 
    def method_missing( method, *args )
      if respond_to?( :commit ) 
        raise NoMethodError
      else
        Aqua.set_storage_engine # to default, currently CouchDB   
        send( method.to_sym, eval(args.map{|value| "'#{value}'"}.join(', ')) ) # resend!
      end  
    end 
  end # Storage    
end # Aqua 