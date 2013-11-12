module AutoForme
  module Models
    class Sequel < Model
      def initialize(*)
        super
        @model.plugin :forme
      end

      def base_class
        ::Sequel::Model
      end

      def new_search
        @model.call({})
      end

      def set_fields(obj, type, params)
        obj.set_fields(params, set_columns(type))
      end

      def set_columns(type)
        columns_for(type).map{|c| set_column(c)}
      end

      def set_column(column)
        a = model.association_reflection(column)
        a ? a[:key] : column
      end

      def association?(column)
        model.association_reflection(column)
      end

      def associated_class(assoc)
        model.association_reflection(assoc).associated_class
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

      def with_pk(type, request)
        dataset_for(type, request).with_pk!(request.id)
      end

      def all_rows_for(type, request)
        all_dataset_for(type, request).all
      end

      def default_columns
        columns = model.columns - Array(model.primary_key)
        model.all_association_reflections.each do |reflection|
          next unless reflection[:type] == :many_to_one
          if i = columns.index(reflection[:key])
            columns[i] = reflection[:name]
          end
        end
        columns.sort_by{|s| s.to_s}
      end

      def session_value(column)
        filter do |ds, req|
          ds.where(column=>req.session[column])
        end
        before_create do |obj, req|
          obj.send("#{column}=", req.session[column])
        end
      end

      def search_results(type, request)
        params = request.params
        ds = apply_associated_eager(:search, all_dataset_for(type, request))
        set_columns(:search_form).each do |c|
          if (v = params[c]) && !v.empty?
            if column_type(c) == :string
              ds = ds.where(::Sequel.ilike(c, "%#{ds.escape_like(v.to_s)}%"))
            else
              ds = ds.where(c=>v.to_s)
            end
          end
        end
        paginate(type, request, ds)
      end

      def browse(type, request)
        paginate(type, request, apply_associated_eager(:browse, all_dataset_for(type, request)))
      end

      def paginate(type, request, ds)
        limit = limit_for(type)
        offset = ((request.id.to_i||1)-1) * limit
        objs = ds.limit(limit+1, (offset if offset > 0)).all
        next_page = false
        if objs.length > limit
          next_page = true
          objs.pop
        end
        [next_page, objs]
      end

      def apply_associated_eager(type, ds)
        columns_for(type).each do |col|
          if association?(col)
            if model = framework.model_classes[associated_class(col)]
              eager = model.eager_for(:association)
              ds = ds.eager(col=>eager)
            else
              ds = ds.eager(col)
            end
          end
        end
        ds
      end

      def column_type(column)
        (sch = model.db_schema[column]) && sch[:type]
      end

      private

      def dataset_for(type, request)
        ds = @model.dataset
        if filter = filter_for(type)
          ds = filter.call(ds, request)
        end
        ds
      end

      def all_dataset_for(type, request)
        ds = dataset_for(type, request)
        if order = order_for(type)
          ds = ds.order(*order)
        end
        if eager = eager_for(type)
          ds = ds.eager(eager)
        end
        if eager_graph = eager_graph_for(type)
          ds = ds.eager_graph(eager_graph)
        end
        ds
      end

    end
  end

  register_model(:sequel, Models::Sequel)
end
