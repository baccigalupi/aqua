# This is the interface between an individual object and the Storage representation.
# The storage engine should provide a module that gets included into the Mash. The 
# module should minimally provide this interface to the object:
#
#   InstanceMethods
#     initialize
#       @params none, or optional arguments used internally; we don't care.
#       @return [Aqua::Storage] new storage object
#
#     commit
#       @params none, or optional arguments used internally; we don't care.
#       @return [Aqua::Storage] saved storage object
#       @raise [Aqua::ObjectNotFound] if another error occurs in the engine, that should be raised instead 
#         any of the Aqua Exceptions 
#   
#    ClassMethods
#     load( id ) 
#       The'load'  
#       @params id
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