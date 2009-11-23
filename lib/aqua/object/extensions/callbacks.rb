require File.dirname(__FILE__) + '/../../support/active_support/callbacks'

module Aqua
  module Callbacks
    def self.extended( klass )
      klass.class_eval do
        include ActiveSupport::Callbacks
      end
    end
    
    def build_callback( method_sym )
      self.class_eval "
        alias_method :#{method_sym}_core, :#{method_sym}
        def #{method_sym}
          run_callbacks :#{method_sym} do
            #{method_sym}_core
          end
        end  
      "
      define_callbacks method_sym
    end   
    
    def add_callback( base_method, kind, callback_method, block )
      build_callback base_method unless instance_methods.include?( "#{base_method}_core" )
      callback = callback_method ? callback_method : block
      set_callback base_method, kind, callback    
    end   
    
    def before( base_method, callback_method=nil, &block )
      add_callback( base_method, :before, callback_method, block )
    end 
    
    def after( base_method, callback_method=nil, &block )
      add_callback( base_method, :after, callback_method, block ) 
    end
    
    def around( base_method, callback_method=nil, &block )
      add_callback( base_method, :around, callback_method, block ) 
    end         
  end
end    