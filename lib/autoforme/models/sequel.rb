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

      def with_pk(action, pk)
        dataset_for(action).with_pk!(pk)
      end

      def all_rows_for(action)
        all_dataset_for(action).all
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
        filter do |ds, action|
          ds.where(column=>action.request.session[column])
        end
        before_create do |obj, action|
          obj.send("#{column}=", action.request.session[column])
        end
      end

      def search_results(action)
        params = action.request.params
        ds = all_dataset_for(action)
        set_columns(:search_form).each do |c|
          if (v = params[c]) && !v.empty?
            if column_type(c) == :string
              ds = ds.where(::Sequel.ilike(c, "%#{ds.escape_like(v.to_s)}%"))
            else
              ds = ds.where(c=>v.to_s)
            end
          end
        end
        paginate(action, ds)
      end

      def browse(action)
        paginate(action, all_dataset_for(action))
      end

      def paginate(action, ds)
        limit = limit_for(action.normalized_type)
        offset = ((action.request.id.to_i||1)-1) * limit
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

      private

      def dataset_for(action)
        ds = @model.dataset
        if filter = filter_for(action.normalized_type)
          ds = filter.call(ds, action)
        end
        ds
      end

      def all_dataset_for(action)
        ds = dataset_for(action)
        if order = order_for(action.normalized_type)
          ds = ds.order(*order)
        end
        if eager = eager_for(action.normalized_type)
          ds = ds.eager(eager)
        end
        if eager_graph = eager_graph_for(action.normalized_type)
          ds = ds.eager_graph(eager_graph)
        end
        ds
      end

    end
  end

  register_model(:sequel, Models::Sequel)
end
