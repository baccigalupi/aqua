module Persist::Store
  module CouchDB
    def self.escape( str )
      str.gsub!('::', '__')
      str.gsub!(/[^a-z0-9\-_]/, '')
      str
    end  
  end # CouchDb
end # Persist::Store    

require File.dirname(__FILE__) + '/couch_db/server'