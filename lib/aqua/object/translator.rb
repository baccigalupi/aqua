module Aqua
  # Packing of objects needs to save an object as well as query it. Therefore this packer module gives a lot
  # of class methods and mirrored instance methods that pack various types of objects. The instance methods
  # aggregate all of the attachments and externals that need to be mapped back to the base object after they 
  # are saved. The class methods return an array with the packaging in the first element and the attachment
  # and externals in subsequent elements
  class Translator 
    attr_accessor :base_object
    
    # PACKING ---------------------------------------------------------------------------------------
    # ===============================================================================================
    attr_writer :externals, :attachments 
    
    # Hash-like object that gathers all the externally saved aquatic objects. Pattern for storage is
    #   external_object => 'pack_path_to_object'
    # where the string 'pack_path_to_object' gets instance evaled in order to update the id in the pack
    # after a new external is saved
    # @api private
    def externals
      @externals ||= {}
    end
    
    # An array of attachments that have to be stored by the base object
    # @api private
    def attachments
      @attachments ||= []
    end    
    
    # Although most of what the translator does happens via class level methods, instantiation happens 
    # to maintain a reference to the base object when packing/saving externals and attachments. It is 
    # also needed in the unpack process to locate attachments.
    #
    # @param [Aquatic Object]
    #
    # @api private
    def initialize( base_object )
      self.base_object = base_object
    end 
    
    # This is a wrapper method that takes the a class method and aggregates externals and attachments
    # @api private
    def pack
      rat = yield 
      self.externals.merge!( rat.externals )
      self.attachments += rat.attachments
      rat.pack
    end  
    
    # Packs the ivars for a given object.  
    #
    # @param Object to pack 
    # @param [String] path to this particular object within the parent object
    # @return [Mash] Indifferent hash that is the data/metadata deconstruction of an object.
    #
    # @api private
    def self.pack_ivars( obj, path='' )
      path = "#{path}['ivars']"
      rat = Rat.new
      vars = obj.respond_to?(:_storable_attributes) ? obj._storable_attributes : obj.instance_variables
      vars.each do |ivar_name| 
        ivar = obj.instance_variable_get( ivar_name ) 
        ivar_path = path + "['#{ivar_name}']" 
        if ivar
          if ivar == obj # self referential TODO: this will only work direct descendants :(
            ivar_rat = pack_to_stub( ivar, ivar_path )
            rat.hord( ivar_rat, ivar_name ) 
          else   
            ivar_rat = pack_object( ivar, ivar_path )
            rat.hord( ivar_rat, ivar_name )
          end
        end         
      end
      rat
    end
    
    # The instance version is wrapped by the #pack method. It otherwise performs the class method 
    def pack_ivars( obj, path='' )
      pack { self.class.pack_ivars( obj ) }
    end
    
    # Packs an object into data and meta data. Works recursively sending out to array, hash, etc.  
    # object packers, which send their values back to _pack_object
    #
    # @param Object to pack 
    # @param [String] path, so that unsaved externals can find and set their id after creation
    # @return [Mash] Indifferent hash that is the data/metadata deconstruction of an object.
    #
    # @api private  
    def self.pack_object( obj, path='' )
      klass = obj.class
      if obj.respond_to?(:to_aqua) # probably requires special initialization not just ivar assignment
        obj.to_aqua( path )
      elsif obj.aquatic? 
        if obj._embedded? || path == ''
          pack_vanilla( obj, path )
        else
          pack_to_stub( obj, path)
        end
      else
        pack_vanilla( obj, path )
      end    
    end
    
    # The instance version is wrapped by the #pack method. It otherwise performs the class method 
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
      rat = Rat.new( { 'class' => obj.class.to_s } ) 
      ivar_rat = pack_ivars( obj, path )
      rat.hord( ivar_rat, 'ivars' ) unless ivar_rat.pack.empty?
      rat
    end 
    
    # The instance version is wrapped by the #pack method. It otherwise performs the class method 
    def pack_vanilla( obj, path='' )
      pack { self.class.pack_vanilla( obj ) }
    end
    
     
    # Packs the stub for an externally saved object.  
    #
    # @param Object to pack
    # @param [String] path to this part of the object
    # @return [Mash] Indifferent hash that is the data/metadata deconstruction of an object.
    #
    # @api private    
    def self.pack_to_stub( obj, path='' )
      rat = Rat.new( {'class' => 'Aqua::Stub'} ) 
      stub_rat = Rat.new({'class' => obj.class.to_s, 'id' => obj.id || '' }, {obj => path} )
      # deal with cached methods
      unless (stub_methods = obj._stubbed_methods).empty?
        stub_rat.pack['methods'] = {}
        stub_methods.each do |meth|
          meth = meth.to_s
          method_rat = pack_object( obj.send( meth ) )
          stub_rat.hord( method_rat, ['methods', "#{meth}"])
        end    
      end
      rat.hord( stub_rat, 'init' )
    end
    
    # The instance version is wrapped by the #pack method. It otherwise performs the class method 
    def pack_to_stub( obj, path='' )
      pack { self.class.pack_to_stub( obj ) }
    end  
    
    # def pack_singletons
    #   # TODO: figure out 1.8 and 1.9 compatibility issues. 
    #   # Also learn the library usage, without any docs :(
    # end
                 
    # Rat class is used by the translators packing side and aggregates methods for merging
    # packed representation, externals and attachments
    class Rat 
      attr_accessor :pack, :externals, :attachments
      def initialize( pack=Mash.new, externals=Mash.new, attachments=[] )
        self.pack = pack
        self.externals = externals
        self.attachments = attachments
      end
    
      # merges the two rats
      def eat( other_rat )
        if self.pack.respond_to?(:keys) 
          self.pack.merge!( other_rat.pack )
        else
          self.pack << other_rat.pack  # this is a special case for array init rats
        end    
        self.externals.merge!( other_rat.externals )
        self.attachments += other_rat.attachments 
        self
      end
    
      # outputs and resets the accessor
      def barf( accessor )
        case accessor
        when :pack, 'pack'
          meal = self.pack
          self.pack = {}
        when :externals, 'externals'  
          meal = self.externals
          self.externals = {}  
        else
          meal = self.attachments
          self.attachments = []
        end    
        meal
      end
    
      def hord( other_rat, index)
        if [String, Symbol].include?( index.class ) 
          self.pack[index] = other_rat.barf(:pack) 
        else # for nested hording
          eval_string = index.inject("self.pack") do |result, element|
            element = "'#{element}'" if element.class == String
            result += "[#{element}]" 
          end 
          value = other_rat.barf(:pack)
          instance_eval "#{eval_string} = #{value.inspect}"
        end      
        self.eat( other_rat ) 
        self
      end
    
      def ==( other_rat ) 
        self.pack == other_rat.pack && self.externals == other_rat.externals && self.attachments == other_rat.attachments
      end    
    end
    
    # PACKING ---------------------------------------------------------------------------------------
    # ===============================================================================================
    def self.classes
      @classes ||= {}
    end  
    
    def self.get_class( class_str )
      classes[class_str] ||= class_str.constantize  if class_str
    end 
    
    def unpack_object( doc, opts=Opts.new ) 
      opts.base_object = self.base_object
      self.class.unpack_object( doc, opts )
    end  
    
    def self.unpack_object( doc, opts=Opts.new )
      if doc.respond_to?(:from_aqua)
        doc.from_aqua # these are basic types, like nil, strings, true/false, or symbols
      else
        # create the class 
        klass = get_class( doc['class'] )
        obj = if (init = doc['init']) &&  klass.respond_to?( :aqua_init )
          klass.aqua_init( init, opts )
        else
          klass.new   
        end

        # mixin the id and rev
        if obj.aquatic? && !obj._embedded?
          obj.id = doc.id if doc.id
          obj._rev = doc.rev if doc.rev
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
    
    class Opts 
      attr_accessor :base_object
      attr_writer :path
      
      def path
        @path ||= ''
      end  
    end  
    
  end # Translator   
end # Aqua   