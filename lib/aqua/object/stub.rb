#require 'delegate'

module Aqua
  class Stub < Delegator
    
    # Builds a new stub object which returns cached/stubbed methods until such a time as a non-cached method 
    # is requested.
    # @param [Hash]
    # @option opts [Array] :methods An array of of symbol/strings representing methods to be implemented
    # @option opts [String] :class The class of the object being stubbed
    # @option opts [String] :id The id of the object being stubbed
    #
    # @api semi-public
    def initialize( opts )
      meths = opts[:methods] || {}
      stub = OpenStruct.new( meths )
      super( stub )
      @_sd_obj = stub
      self.delegate_class = opts[:class]
      self.delegate_id = opts[:id]
    end
      
    protected 
      attr_accessor :delegate_class, :delegate_id
    
      def method_missing( method, *args )
        if @_sd_obj.class == delegate_class
          load_delegate
        else
          raise NoMethodError
        end
      end
      
      def 
      
      def load_delegate
        __setobj__( delegate_class.constantize.load( delegate_id ) )
      end   
    public
        
  end  
end  