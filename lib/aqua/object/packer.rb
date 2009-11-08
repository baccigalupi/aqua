# These are class methods that don't need to be added to each class, but can be used from the
# module directly. They are responsible for packing objects ...
module Aqua
  class Packer 
    attr_accessor :base
    
    def externals
      @externals ||= []
    end
    
    def attachments
      @attachments ||= []
    end    
    
    def initialize( base_object )
      self.base = base_object
    end 
    
    def pack
      arr = yield 
      self.externals += arr[1]
      self.attachments += arr[2]
      arr[0]
    end  
    
    def self.pack_ivars( obj )
      hash = {}
      externals = []
      attachments = []
      
      vars = obj.respond_to?(:_storable_attributes) ? obj._storable_attributes : obj.instance_variables
      vars.each do |ivar_name|
        ivar = obj.instance_variable_get( ivar_name )
        unless ivar.nil?
          arr = pack_object( ivar )
          hash[ivar_name] = arr[0]
          externals       += arr[1]
          attachments     += arr[2] 
        end         
      end
       
      [hash, externals, attachments]
    end 
    
    def pack_ivars( obj )
      pack { self.class.pack_ivars( obj ) }
    end
    
    def self.pack_object( obj )
      klass = obj.class
      if klass == String
        [obj, [], []]
      elsif obj.respond_to?(:to_aqua) # requires initialization not just ivar assignment
        obj.to_aqua
      elsif obj.aquatic? && obj != self # if object is aquatic follow instructions in class
        obj._embed_me == true ? obj._pack : pack_to_stub( obj ) 
      else # other object without initializations
        pack_vanilla( obj )
      end     
    end
    
    def pack_object( obj )
      pack { self.class.pack_object( obj ) }
    end
    
    
    # Packs the an object requiring no initialization.  
    #
    # @param Object to pack
    # @return [Mash] Indifferent hash that is the data/metadata deconstruction of an object.
    #
    # @api private  
    def self.pack_vanilla( obj ) 
      arr = pack_ivars( obj )
      [{ 'class' => obj.class.to_s,
        'ivars' => 0 }, arr[1], arr[2]]  
    end 
    
    def pack_vanilla( obj )
      pack { self.class.pack_vanilla( obj ) }
    end
    
     
    # Packs the stub for an externally saved object.  
    #
    # @param Object to pack
    # @return [Mash] Indifferent hash that is the data/metadata deconstruction of an object.
    #
    # @api private    
    def self.pack_to_stub( obj )
      externals = [obj]
      attachments = []
      stub = { 
        'class' => obj.class.to_s, 
        'id' => obj.id 
      } 
      
      # deal with cached methods
      if obj._embed_me && obj._embed_me.keys && stub_methods = obj._embed_me[:stub]
        stub['methods'] = {}
        if stub_methods.class == Symbol || stub_methods.class == String
          meth = stub_methods.to_s
          arr = pack_object( obj.send( meth ) )
          stub['methods'][meth] = arr[0]
          externals += arr[1]
          attachments += arr[2]
        else # is an array of values
          stub_methods.each do |meth|
            meth = meth.to_s
            arr = pack_object( obj.send( meth ) )
            stub['methods'][meth] = arr[0]
            externals += arr[1]
            attachments += arr[2]
          end  
        end    
      end
      # return hash  
      [{
        'class' => 'Aqua::Stub', 
        'init' => stub
      }, externals, attachments]
    end 
    
    def pack_to_stub( obj )
      pack { self.class.pack_to_stub( obj ) }
    end  
    
    def pack_singletons
      # TODO: figure out 1.8 and 1.9 compatibility issues. 
      # Also learn the library usage, without any docs :(
    end
                 
  end 
end     