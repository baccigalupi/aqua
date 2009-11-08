# Packing of objects needs to save an object as well as query it. Therefore this packer module gives a lot
# of class methods and mirrored instance methods that pack various types of objects. The instance methods
# aggregate all of the attachments and externals that need to be mapped back to the base object after they 
# are saved. The class methods return an array with the packaging in the first element and the attachment
# and externals in subsequent elements
module Aqua
  class Packer 
    attr_accessor :base
    
    def externals
      @externals ||= {}
    end
    
    def attachments
      @attachments ||= {}
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
    
    def self.pack_ivars( obj, path='' )
      hash = {}
      externals = {}
      attachments = []
      
      vars = obj.respond_to?(:_storable_attributes) ? obj._storable_attributes : obj.instance_variables
      vars.each do |ivar_name|
        ivar = obj.instance_variable_get( ivar_name )
        unless ivar.nil?
          arr = pack_object( ivar )
          hash[ivar_name] = arr[0]
          externals.merge!( arr[1] ) unless arr[1].empty?
          attachments    += arr[2] 
        end         
      end
       
      [hash, externals, attachments]
    end 
    
    def pack_ivars( obj, path='' )
      pack { self.class.pack_ivars( obj ) }
    end
    
    def self.pack_object( obj, path='' )
      klass = obj.class
      if obj.respond_to?(:to_aqua) # probably requires special initialization not just ivar assignment
        obj.to_aqua( path )
      elsif obj.aquatic? && obj != self # if object is aquatic follow instructions for its class
        obj._embed_me == true ? obj._pack : pack_to_stub( obj, path ) 
      else # other object without initializations
        pack_vanilla( obj )
      end     
    end
    
    def pack_object( obj, path='' )
      pack { self.class.pack_object( obj ) }
    end
    
    
    # Packs the an object requiring no initialization.  
    #
    # @param Object to pack
    # @return [Mash] Indifferent hash that is the data/metadata deconstruction of an object.
    #
    # @api private  
    def self.pack_vanilla( obj, path='' ) 
      arr = pack_ivars( obj )
      [{ 'class' => obj.class.to_s,
        'ivars' => 0 }, arr[1], arr[2]]  
    end 
    
    def pack_vanilla( obj, path='' )
      pack { self.class.pack_vanilla( obj ) }
    end
    
     
    # Packs the stub for an externally saved object.  
    #
    # @param Object to pack
    # @return [Mash] Indifferent hash that is the data/metadata deconstruction of an object.
    #
    # @api private    
    def self.pack_to_stub( obj, path='' )
      externals = {obj => path}
      attachments = []
      stub = { 
        'class' => obj.class.to_s, 
        'id' => obj.id || '' 
      } 
      
      # deal with cached methods
      if obj._embed_me && obj._embed_me.keys && stub_methods = obj._embed_me[:stub]
        stub['methods'] = {}
        if stub_methods.class == Symbol || stub_methods.class == String
          meth = stub_methods.to_s
          arr = pack_object( obj.send( meth ) )
          stub['methods'][meth] = arr[0]
          externals.merge!( arr[1] ) unless arr[1].empty?
          attachments += arr[2]
        else # is an array of values
          stub_methods.each do |meth|
            meth = meth.to_s
            arr = pack_object( obj.send( meth ) )
            stub['methods'][meth] = arr[0]
            externals.merge!( arr[1] ) unless arr[1].empty?
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
    
    def pack_to_stub( obj, path='' )
      pack { self.class.pack_to_stub( obj ) }
    end  
    
    # def pack_singletons
    #   # TODO: figure out 1.8 and 1.9 compatibility issues. 
    #   # Also learn the library usage, without any docs :(
    # end
                 
  end 
end     