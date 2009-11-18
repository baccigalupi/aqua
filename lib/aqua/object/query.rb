module Aqua::Query
  
  def self.included( klass ) 
    klass.class_eval do
      extend ClassMethods
      include InstanceMethods
      
      klass.class_eval " 
        def self.storage 
          #{klass}::Storage
        end  
       " 
    end  
  end 
  
  module ClassMethods
    def index_on( *ivars )
      ivars.each do |var|
        storage.index_on_ivar( var )
      end  
    end
    
    def query( index, opts={} )
      opts = Mash.new( opts )
      equals = opts.delete(:equals)
      opts[:equals] = _encode_query( equals ) if equals
      _build_results( storage.query( index, opts ) )
    end
    
    def _encode_query( object ) 
      CGI.escape( Aqua::Translator.pack_object( object ).pack.to_json )
    end
    
    def _build_results( docs )
      if docs.is_a? Array
        docs.map{ |doc| build( doc ) }
      else
        build( doc )
      end    
    end        
  end
  
  module InstanceMethods
  end

end   