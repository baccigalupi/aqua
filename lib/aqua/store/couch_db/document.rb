# This is around for easy testing and also in case there is use for this core CouchDB library 
module Aqua
  module Store
    module CouchDB
      class Document < Mash
        include Aqua::Store::CouchDB::StorageMethods
      end # Document
    end # CouchDB
  end # Store    
end # Aqua 