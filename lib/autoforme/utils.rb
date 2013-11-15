module AutoForme
  module OptsAttributes
    def opts_attribute(base, prefixes=[], &default_block)
      meths = [base] + prefixes.map{|prefix| :"#{prefix}_#{base}"}
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
            opts.fetch(meth) do
              if meth == base
                default_block.call if default_block
              else
                send(base)
              end
            end
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
