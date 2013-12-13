module AutoForme
  module OptsAttributes
    # Setup methods for each given argument such that if the method is called with an argument or
    # block, it sets the value of the related option to that argument or block.  If called without
    # an argument or block, it returns the stored option value.
    def opts_attribute(*meths)
      meths.each do |meth|
        define_method(meth) do |*args, &block|
          if block
            if args.empty?
              opts[meth] = block
            else
              raise ArgumentError, "No arguments allowed if passing a block"
            end
          end

          case args.length
          when 0
            opts[meth]
          when 1
            opts[meth] = args.first
          else
            raise ArgumentError, "Only 0-1 arguments allowed"
          end
        end
      end
    end
  end
end
