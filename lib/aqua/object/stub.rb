module Aqua
  class Stub
    attr_accessor :delegate, :delegate_class, :delegate_id, 
      :parent_object, :path_from_parent
    
    # Builds a new stub object which returns cached/stubbed methods until such a time as a non-cached method 
    # is requested.
    #
    # @param [Hash]
    # @option opts [Array] :methods A hash of method names and values
    # @option opts [String] :class The class of the object being stubbed
    # @option opts [String] :id The id of the object being stubbed
    #
    # @todo pass in information about parent, and path to the stub such that method missing replaces stub
    #         with actual object being stubbed and delegated to.
    # @api semi-public
    def initialize(opts)
      stub_methods( opts[:methods] || {} )
      
      self.delegate_class     = opts[:class]
      self.delegate_id        = opts[:id]
      self.parent_object      = opts[:parent]
      self.path_from_parent   = opts[:path] 
    end 
    
    def self.aqua_init( init, opts=Unpacker::Opts.new )
      new( init )
    end 
             
    protected 
      
      def stub_methods( stubbed_methods ) 
        stubbed_methods.each do |method_name, value|
          self.class.class_eval("
            def #{method_name}
              #{value.inspect}
            end  
          ")
        end
      end
               
      def method_missing( method, *args, &block )
        load_delegate if delegate.nil?
        delegate.send( method, *args, &block )
      end
      
      def load_delegate 
        self.delegate = delegate_class.constantize.load( delegate_id )
      end   
  end

  class FileStub < Stub 
    attr_accessor :base_object, :attachment_id 
      
    def initialize( opts )
      super( opts )
      self.base_object = opts[:base_object]
      self.attachment_id = opts[:id]
    end
    
    # This is what is actually called in the Aqua unpack process
    def self.aqua_init( init, opts )
      init['base_object'] = opts.base_object
      super
    end
      
    protected 
      def load_delegate
        self.delegate = base_object.class::Storage.attachment( base_object.id, attachment_id )
      end   
  end            
  
end  