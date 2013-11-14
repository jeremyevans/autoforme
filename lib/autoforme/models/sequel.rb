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

      def set_fields(obj, type, request, params)
        columns_for(type).each do |col|
          column = col

          if association?(col)
            ref = model.association_reflection(col)
            ds = ref.associated_dataset
            if model_class = associated_model_class(col)
              ds = model_class.apply_dataset_options(:association, request, ds)
            end

            if v = params[ref[:key]]
              v = ds.first!(ref.primary_key=>v)
            end
          else
            v = params[col]
          end

          obj.send("#{column}=", v)
        end
      end

      def association?(column)
        model.association_reflection(column)
      end

      def associated_class(assoc)
        model.association_reflection(assoc).associated_class
      end

      def association_type(assoc)
        case model.association_reflection(assoc)[:type]
        when :many_to_one, :one_to_one
          :one
        when :one_to_many
          :new
        when :many_to_many
          :edit
        end
      end

      def associated_new_column_values(obj, assoc)
        ref = model.association_reflection(assoc)
        ref[:keys].zip(ref[:primary_keys].map{|k| obj.send(k)})
      end

      def mtm_association_names
        model.all_association_reflections.select{|r| r[:type] == :many_to_many}.map{|r| r[:name].to_s}.sort
      end

      def association_names
        types = [:many_to_one, :one_to_one, :one_to_many, :many_to_many]
        model.all_association_reflections.select{|r| types.include?(r[:type])}.map{|r| r[:name]}.sort_by{|n| n.to_s}
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

      def with_pk(type, request, pk)
        dataset_for(type, request).with_pk!(pk)
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
        columns_for(:search_form).each do |c|
          if (v = params[c]) && !v.empty?
            if association?(c)
              ref = model.association_reflection(c)
              ads = ref.associated_dataset
              if model_class = associated_model_class(c)
                ads = model_class.apply_dataset_options(:association, request, ads)
              end
              ds = ds.where(ref[:key]=>ads.where(ref.primary_key=>v).select(ref.primary_key))
            elsif column_type(c) == :string
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
            if model = associated_model_class(col)
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

      def apply_dataset_options(type, request, ds)
        if filter = filter_for(type)
          ds = filter.call(ds, request)
        end
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

      def mtm_update(request, assoc, obj, add, remove)
        ref = model.association_reflection(assoc)
        assoc_class = associated_model_class(assoc)
        model.db.transaction do
          [[add, ref.add_method], [remove, ref.remove_method]].each do |ids, meth|
            if ids
              ids.each do |id|
                obj.send(meth, assoc_class ? assoc_class.with_pk(:association, request, id) : ref.associated_dataset.with_pk!(id))
              end
            end
          end
        end
      end

      def associated_mtm_objects(request, assoc, obj)
        ds = obj.send("#{assoc}_dataset")
        if assoc_class = associated_model_class(assoc)
          ds = assoc_class.apply_dataset_options(:association, request, ds)
        end
        ds
      end

      def unassociated_mtm_objects(request, assoc, obj)
        ref = model.association_reflection(assoc)
        assoc_class = associated_model_class(assoc)
        lambda do |ds|
          subquery = model.db.from(ref[:join_table]).
            select(ref.qualified_right_key).
            where(ref.qualified_left_key=>obj.pk)
          ds = ds.exclude(::Sequel.qualify(ref.associated_class.table_name, model.primary_key)=>subquery)
          ds = assoc_class.apply_dataset_options(:association, request, ds) if assoc_class
          ds
        end
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
        apply_dataset_options(type, request, @model.dataset)
      end
    end
  end

  register_model(:sequel, Models::Sequel)
end
