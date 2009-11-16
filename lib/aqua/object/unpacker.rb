module Aqua
  class Unpacker
    # Base object is needed by the FileStub to find the attachments.
    # At present files have to be saved in an aquatic object, which could be done by inheritance
    attr_accessor :base_object
    
    class Opts 
      attr_accessor :base_object
      attr_writer :path
      
      def path
        @path ||= ''
      end  
    end  
    
    def initialize( base )
      self.base_object = base
    end  
    
    def self.classes
      @classes ||= {}
    end  
    
    def self.get_class( class_str )
      classes[class_str] ||= class_str.constantize
    end 
    
    def unpack_object( doc, opts=Opts.new ) 
      opts.base_object = self.base_object
      self.class.unpack_object( doc, opts )
    end  
    
    def self.unpack_object( doc, opts=Opts.new )
      if doc.respond_to?(:from_aqua)
        doc.from_aqua
      else
        # create the class 
        klass = get_class( doc['class'] )
        obj = if (init = doc['init']) &&  klass.respond_to?( :aqua_init )
          klass.aqua_init( init, opts )
        else
          klass.new   
        end 
        # add the ivars  
        if ivars = doc['ivars']
          ivars.each do |ivar_name, ivar_hash|
            opts.path += "#{ivar_name}"
            unpacked_ivar = unpack_object( ivar_hash, opts ) 
            obj.instance_variable_set( ivar_name, unpacked_ivar )
          end  
        end
        obj  
      end    
    end
    
  end
end    