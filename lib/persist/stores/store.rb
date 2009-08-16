# This is the interface between an individual object and the Storage representation.
# The storage engine should provide a module that gets included into the Mash. The 
# module should minimally provide this interface to the object:
#
#   InstanceMethods
#     initialize
#       @params none, or optional arguments used internally; we don't care.
#       @return [Persist::Store] new storage object
#
#     commit
#       @params none, or optional arguments used internally; we don't care.
#       @return [Persist::Store] saved storage object
#       @raise [Persist::ResourceNotFound, Persist::RequestFailed, Persist::RequestTimeout, Persist::ServerBrokeConnection, Persist::Conflict] 
#         any of the Perist Exceptions 
#   
#    ClassMethods
#     load( id ) 
#       The'load'  
#       @params id
#       @return [Persist::Store]
#       @raise [Persist::ResourceNotFound, Persist::RequestFailed, Persist::RequestTimeout, Persist::ServerBrokeConnection, Persist::Conflict] 
#         any of the Perist Exceptions] 
#
# Other methods used for the storage engine can be added as needed by the engine. 
#
# If no storage engine is configured before this class is used, CouchDB will automatically be used
# as an engine.
class Persist::Store < Mash 
  # auto loads the default store to CouchDB if Store is used without Persist configuration of a store 
  def method_missing( method, *args )
    if respond_to?( :commit ) 
      raise NoMethodError
    else
      self.class.class_eval do   
        include Persist::CouchDB::Store
      end   
      send( method.to_sym, eval(args.map{|value| "'#{value}'"}.join(', ')) ) # resend!
    end  
  end  
end  