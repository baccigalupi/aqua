module Aqua::Unpack
  
  def self.included( klass ) 
    klass.class_eval do
      extend ClassMethods
      include InstanceMethods
    end  
  end 
  
  module ClassMethods
    # Searches the store for a document. Initializes a New Object with it. 
    def load( id ) 
      instance = new
      instance.id = id
      instance.reload
      instance
    end  
  end
  
  module InstanceMethods 
    def reload( mask_exceptions = true ) 
      if id.nil?
        if mask_exceptions
          false
        else
          raise ObjectNotFound, "#{self.class} instance must have an id to be reloaded"
        end    
      else
        begin
          _reload
        rescue Exception => e 
          if mask_exceptions
            false
          else 
            raise e
          end    
        end      
      end  
    end
    
    def reload!
      reload( false )
    end  
    
    private
      def _reload
        _get_store
        _unpack
        _clear_store
        self
      end
      
      def _get_store
        # this is kind of klunky, should refactor
        self._store = Aqua::Storage.new(:id => self.id).retrieve 
      end
      
      def _unpack
        if init = _unpack_initialization( _store )
          replace( init ) 
        end
        if ivars = _store[:data]
          _unpack_ivars( self, ivars )
        end    
      end 
      
      def _clear_store
        @_store = nil
      end  
      
      def _unpack_ivars( obj, data ) 
        data.each do |ivar_name, data_package|
          unpacked = if data_package.class == String
            data_package
          else
            _unpack_object( data_package )
          end    
          obj.instance_variable_set( ivar_name, unpacked )
        end  
      end    
      
      def _unpack_initialization( obj )
        if init = obj[:initialization] 
          init_class = init.class
          if init_class == String
            init
          elsif init.class == Array 
            _unpack_array( init )
          else
            _unpack_hash( init )
          end    
        end 
      end  
      
      def _unpack_array( obj ) 
        arr = [] 
        obj.each do |value|
          value = _unpack_object( value ) unless value.class == String
          arr << value
        end  
        arr
      end
      
      def _unpack_hash( obj )
        hash = {}
        obj.each do |raw_key, value|
          value = _unpack_object( value ) unless value.class == String
          if raw_key.match(/\A(:)/)
            key = raw_key.gsub($1, '').to_sym
          elsif raw_key.match(/\A\/OBJECT_/) # object keys will start with '/OBJECT_' hopefully an unlikely actual string name   
            raise 'object keys not yet implemented'
          else
            key = raw_key
          end  
          hash[key] = value
        end
        hash  
      end    
      
      def _unpack_object( store_pack )
        # store_pack will be: an array, a string, a hash
        # a hash that has the class key is an object representation
        # an array will either have strings or object representations
        # a hash that doesn't have a class key is a hash and may have object representations 
        
        package_class = store_pack.class 
        if package_class == String
          store_pack
        elsif package_class == Array 
          _unpack_array( store_pack )  
        else # package_class == Hash -or- Mash 
          if obj_class_string = store_pack['class']
            
            # Constantize the objects class
            obj_class = obj_class_string.constantize rescue nil
            
            # build from initialization 
            init = _unpack_initialization( store_pack )
            return_object = if init 
              init_class = init.class
              if init_class == Array
                if obj_class == Rational
                  Rational( init[0].to_i, init[1].to_i )
                elsif obj_class && obj_class != Array
                  obj_class.new.replace( init )
                else
                  # should log an error internally
                  init
                end
              elsif init_class.ancestors.include?( Hash )
                if obj_class == OpenStruct
                  obj_class.new( init )
                elsif obj_class  
                  obj_class.new.replace( init )
                else
                  # should log an error internally
                  init
                end
              else # is a string 
                if obj_class == Date || obj_class == Time 
                  obj_class.parse( init )
                elsif [Fixnum, Bignum].include?( obj_class )
                  init.to_i
                elsif obj_class == Float
                  init.to_f  
                elsif obj_class == TrueClass 
                  true
                elsif obj_class == FalseClass 
                  false
                else
                  nil
                end            
              end       
            end
            
            # Build uninitialized object
            if return_object.nil?
              if obj_class
                return_object = obj_class.new
              else 
                # should log an error internally
                return_object = OpenStruct.new
              end
            end
            
            # add the ivars
            if ivars = store_pack['data'] 
              ivars.delete('@table') if obj_class.ancestors.include?( OpenStruct )
              _unpack_ivars( return_object, ivars )
            end
                   
            return_object 
          else # not a packaged object, just a hash, so unpack
            _unpack_hash( hash )
          end    
        end    
             
      end  
            
    public  
  end

end       