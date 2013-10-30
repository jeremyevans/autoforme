module AutoForme
  module Models
    class Sequel < Model
      def initialize(*)
        super
        @model.plugin :forme
      end

      def new_search
        @model.call({})
      end

      def set_fields(obj, type, params)
        obj.set_fields(params, columns_for(type))
      end

      def save(obj)
        obj.raise_on_save_failure = false
        obj.save
      end

      def primary_key_value(obj)
        obj.pk
      end

      def params_name
        @model.send(:underscore, @model.name)
      end

      def with_pk(pk)
        @model.with_pk!(pk)
      end

      def search_results(request)
        ds = @model.dataset
        columns_for(:search_form).each do |c|
          if (v = request.params[c]) && !v.empty?
            if column_type(c) == :string
              ds = ds.where(::Sequel.ilike(c, "%#{ds.escape_like(v.to_s)}%"))
            else
              ds = ds.where(c=>v.to_s)
            end
          end
        end
        paginate(request, ds)
      end

      def browse(request)
        paginate(request, @model)
      end

      def paginate(request, ds)
        limit = limit_for(:browse)
        offset = ((request.id.to_i||1)-1) * limit
        objs = ds.limit(limit+1, (offset if offset > 0)).all
        next_page = false
        if objs.length > limit
          next_page = true
          objs.pop
        end
        [next_page, objs]
      end

      def column_type(column)
        (sch = model.db_schema[column]) && sch[:type]
      end
    end
  end

  register_model(:sequel, Models::Sequel)
end
