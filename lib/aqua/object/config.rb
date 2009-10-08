module Aqua::Config
  
  def self.included( klass ) 
    klass.class_eval do
      extend ClassMethods
      configure_aqua
      
      hide_attributes :_aqua_opts
    end  
  end
  
  # This is used to maintain the storage specific options
  # for a given class, such as a particular database for the class.
  # Otherwise, appeals directly to Storage for class methods will loose 
  # this information.
  class Storage < Aqua::Storage 
  end  
     
  
  module ClassMethods 
    def configure_aqua(opts={})
      database = opts.delete(:database)
      Storage.database = database
      @_aqua_opts = Mash.new( _aqua_opts ).merge!(opts)
    end
    
    def _aqua_opts
      @_aqua_opts ||= _aqua_config_defaults
    end   
    
    private
      def _aqua_config_defaults
        {
          :database => nil, # Default is the same as the server. Everything is saved to the same db
          :embed => false,  # options false, true, or :stub => [:attributes, :to_save, :in_the_other_object]
        }
      end
    public   
  end

end   