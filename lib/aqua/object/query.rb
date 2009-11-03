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
      opts[:equals] = CGI.escape( equals.to_aqua( equals ).to_json ) if equals
      results = storage.query( index, opts )
    end    
  end
  
  module InstanceMethods
  end

end   