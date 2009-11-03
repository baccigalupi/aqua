module Aqua
  module Store 
    module CouchDB
      class ResultSet < Array
        
        def self.document_class
          @document_class
        end
        
        def self.document_class=( klass )
          @document_class = klass
        end    
        
        attr_accessor :offset, :total, :rows, :document_class
        
        def initialize( response, doc_class=nil )
          self.document_class = doc_class || self.class.document_class
          self.total    = response['total_rows']
          self.offset   = response['offset']
          self.rows     = response['rows']
          results = if rows && rows.first && rows.first['doc']
            if document_class
              rows.collect{ |h| document_class.new( h['doc'] ) }
            else
              rows.collect{ |h| h['doc'] }
            end    
          else
            rows.collect{ |h| h['key'] } 
          end    
          super( results )
        end
           
      end
    end
  end
end    