# When the api using CouchDB is stable, an interface and tests need to be created so that aqua can be extended 
# to other storage engines.
module Aqua
  class Storage < Gnash 
    # auto loads the default store to CouchDB if Store is used without Aqua configuration of a store 
    def method_missing( method, *args )
      if respond_to?( :commit ) 
        raise NoMethodError, "#{method} undefined for #{self.inspect}"
      else
        Aqua.set_storage_engine # to default, currently CouchDB   
        send( method.to_sym, *args ) # resend!
      end  
    end 
  end # Storage    
end # Aqua 