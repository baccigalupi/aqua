unless defined?( ActiveSupport )
  module Extlib
 
    # = English Nouns Number Inflection.
    #
    # This module provides english singular <-> plural noun inflections.
    module Inflection
 
      class << self
        # Take an underscored name and make it into a camelized name
        #
        # @example
        #   "egg_and_hams".classify #=> "EggAndHam"
        #   "post".classify #=> "Post"
        #
        def classify(name)
          camelize(singularize(name.to_s.sub(/.*\./, '')))
        end
 
        # By default, camelize converts strings to UpperCamelCase.
        #
        # camelize will also convert '/' to '::' which is useful for converting paths to namespaces
        #
        # @example
        #   "active_record".camelize #=> "ActiveRecord"
        #   "active_record/errors".camelize #=> "ActiveRecord::Errors"
        #
        def camelize(lower_case_and_underscored_word, *args)
          lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
        end
 
 
        # The reverse of +camelize+. Makes an underscored form from the expression in the string.
        #
        # Changes '::' to '/' to convert namespaces to paths.
        #
        # @example
        #   "ActiveRecord".underscore #=> "active_record"
        #   "ActiveRecord::Errors".underscore #=> active_record/errors
        #
        def underscore(camel_cased_word)
          camel_cased_word.to_s.gsub(/::/, '/').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          downcase
        end
 
        # Capitalizes the first word and turns underscores into spaces and strips _id.
        # Like titleize, this is meant for creating pretty output.
        #
        # @example
        #   "employee_salary" #=> "Employee salary"
        #   "author_id" #=> "Author"
        def humanize(lower_case_and_underscored_word)
          lower_case_and_underscored_word.to_s.gsub(/_id$/, "").gsub(/_/, " ").capitalize
        end
 
        # Constantize tries to find a declared constant with the name specified
        # in the string. It raises a NameError when the name is not in CamelCase
        # or is not initialized.
        #
        # @example
        #   "Module".constantize #=> Module
        #   "Class".constantize #=> Class
        def constantize(camel_cased_word)
          unless /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/ =~ camel_cased_word
            raise NameError, "#{camel_cased_word.inspect} is not a valid constant name!"
          end
 
          Object.module_eval("::#{$1}", __FILE__, __LINE__)
        end
      end
    
    end  
  end
 
  class String
    def constantize
      Extlib::Inflection.constantize( self )
    end  
    
    def humanize
      Extlib::Inflection.humanize( self )
    end  
    
    def underscore
      Extlib::Inflection.underscore( self )
    end
    
    def classify
      Extlib::Inflection.classify( self )
    end    
  end  
end            