# NOTES: I just checked and Delegator does all its delegation through method missing, so 
# it probably makes sense to make this all one class, with method_missing doing the work. 

module Aqua 
  class TempStub
    def initialize( method_hash ) 
      method_hash.each do |method_name, value|
        self.class.class_eval("
          def #{method_name}
            #{value.inspect}
          end  
        ")  
      end  
    end   
  end
    
  class Stub < Delegator
    
    # Builds a new stub object which returns cached/stubbed methods until such a time as a non-cached method 
    # is requested.
    #
    # @param [Hash]
    # @option opts [Array] :methods A hash of method names and values
    # @option opts [String] :class The class of the object being stubbed
    # @option opts [String] :id The id of the object being stubbed
    #
    # @api semi-public
    def initialize( opts )
      meths = opts[:methods] || {}
      temp_stub = TempStub.new( meths )
      super( temp_stub )
      @_sd_obj = temp_stub
      self.delegate_class = opts[:class]
      self.delegate_id = opts[:id]
    end
      
    protected 
      attr_accessor :delegate_class, :delegate_id
    
      def method_missing( method, *args )
        if __getobj__.class.to_s != delegate_class.to_s
          load_delegate
          # resend! 
          if (args.size == 1 && !args.first.nil?) 
            __getobj__.send( method.to_sym, eval(args.map{|value| "'#{value}'"}.join(', ')) )
          else
            __getobj__.send( method.to_sym )
          end    
        else
          raise NoMethodError
        end
      end
      
      def __getobj__
         @_sd_obj          # return object we are delegating to, required
       end

       def __setobj__(obj)
         @_sd_obj = obj    # change delegation object, a feature we're providing
       end
      
      def load_delegate
        __setobj__( delegate_class.constantize.load( delegate_id ) )
      end   
    public
        
  end  
end  