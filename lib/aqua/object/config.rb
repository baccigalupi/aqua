module Aqua::Config
  def self.included( klass ) 
    # This per aquatic class storage class is used to maintain the storage specific options, 
    # such as a particular database for the class. Otherwise, appeals directly to Aqua::Storage 
    # for class methods will loose database and other class specific storage options
    klass.class_eval "
      class Storage < Aqua::Storage
      end
      
      Storage.parent_class = '#{klass}'
    "
    
    klass.class_eval do
      extend ClassMethods
      configure_aqua
      
      hide_attributes :_aqua_opts
    end   
  end
  
  module ClassMethods 
    def configure_aqua(opts={}) 
      database = opts.delete(:database)
      self::Storage.database = database
      @_aqua_opts = Gnash.new( _aqua_opts ).merge!(opts)
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