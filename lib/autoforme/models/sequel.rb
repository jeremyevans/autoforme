# frozen-string-literal: true

module AutoForme
  module Models
    # Sequel specific model class for AutoForme
    class Sequel < Model
      # Short reference to top level Sequel module, for easily calling methods
      S = ::Sequel

      # What association types to recognize.  Other association types are ignored.
      SUPPORTED_ASSOCIATION_TYPES = [:many_to_one, :one_to_one, :one_to_many, :many_to_many]

      # Make sure the forme plugin is loaded into the model.
      def initialize(*)
        super
        model.plugin :forme
      end

      # The base class for the underlying model, ::Sequel::Model.
      def base_class
        S::Model
      end

      # A completely empty search object, with no defaults.
      def new_search
        model.call({})
      end

      # The name of the form param for the given association.
      def form_param_name(assoc)
        "#{model.send(:underscore, model.name)}[#{association_key(assoc)}]"
      end

      # Set the fields for the given action type to the object based on the request params.
      def set_fields(obj, type, request, params)
        columns_for(type, request).each do |col|
          column = col

          if association?(col)
            ref = model.association_reflection(col)
            ds = ref.associated_dataset
            if model_class = associated_model_class(col)
              ds = model_class.apply_filter(:association, request, ds)
            end

            v = params[ref[:key].to_s]
            v = nil if v.to_s.strip == ''
            if v
              v = ds.first!(S.qualify(ds.model.table_name, ref.primary_key)=>v)
            end
          else
            v = params[col.to_s]
          end

          obj.send("#{column}=", v)
        end
      end

      # Whether the column represents an association.
      def association?(column)
        case column
        when String
          model.associations.map(&:to_s).include?(column)
        else
          model.association_reflection(column)
        end
      end

      # The associated class for the given association
      def associated_class(assoc)
        model.association_reflection(assoc).associated_class
      end

      # A short type for the association, either :one for a
      # singular association, :new for an association where
      # you can create new objects, or :edit for association
      # where you can add/remove members from the association.
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

      # The foreign key column for the given many to one association.
      def association_key(assoc)
        model.association_reflection(assoc)[:key]
      end

      # An array of pairs mapping foreign keys in associated class
      # to primary key value of current object
      def associated_new_column_values(obj, assoc)
        ref = model.association_reflection(assoc)
        ref[:keys].zip(ref[:primary_keys].map{|k| obj.send(k)})
      end

      # Array of many to many association name strings.
      def mtm_association_names
        association_names([:many_to_many])
      end

      # Array of association name strings for given association types
      def association_names(types=SUPPORTED_ASSOCIATION_TYPES)
        model.all_association_reflections.select{|r| types.include?(r[:type])}.map{|r| r[:name]}.sort_by(&:to_s)
      end

      # Save the object, returning the object if successful, or nil if not.
      def save(obj)
        obj.raise_on_save_failure = false
        obj.save
      end

      # The primary key value for the given object.
      def primary_key_value(obj)
        obj.pk
      end

      # The namespace for form parameter names for this model, needs to match
      # the ones automatically used by Forme.
      def params_name
        model.send(:underscore, model.name)
      end

      # Retrieve underlying model instance with matching primary key
      def with_pk(type, request, pk)
        dataset_for(type, request).with_pk!(pk)
      end

      # Retrieve all matching rows for this model.
      def all_rows_for(type, request)
        all_dataset_for(type, request).all
      end

      # Return the default columns for this model
      def default_columns
        columns = model.columns - Array(model.primary_key)
        model.all_association_reflections.each do |reflection|
          next unless reflection[:type] == :many_to_one
          if i = columns.index(reflection[:key])
            columns[i] = reflection[:name]
          end
        end
        columns.sort_by(&:to_s)
      end

      # Add a filter restricting access to only rows where the column name
      # matching the session value.  Also add a before_create hook that sets
      # the column value to the session value.
      def session_value(column)
        filter do |ds, type, req|
          ds.where(S.qualify(model.table_name, column)=>req.session[column])
        end
        before_create do |obj, req|
          obj.send("#{column}=", req.session[column])
        end
      end

      # Returning array of matching objects for the current search page using the given parameters.
      def search_results(type, request, opts={})
        params = request.params
        ds = apply_associated_eager(:search, request, all_dataset_for(type, request))
        columns_for(:search_form, request).each do |c|
          if (v = params[c.to_s]) && !v.empty?
            if association?(c)
              ref = model.association_reflection(c)
              ads = ref.associated_dataset
              if model_class = associated_model_class(c)
                ads = model_class.apply_filter(:association, request, ads)
              end
              primary_key = S.qualify(ref.associated_class.table_name, ref.primary_key)
              ds = ds.where(S.qualify(model.table_name, ref[:key])=>ads.where(primary_key=>v).select(primary_key))
            elsif column_type(c) == :string
              ds = ds.where(S.ilike(S.qualify(model.table_name, c), "%#{ds.escape_like(v.to_s)}%"))
            else
              ds = ds.where(S.qualify(model.table_name, c)=>v.to_s)
            end
          end
        end
        paginate(type, request, ds, opts)
      end

      # Return array of matching objects for the current page.
      def browse(type, request, opts={})
        paginate(type, request, apply_associated_eager(:browse, request, all_dataset_for(type, request)), opts)
      end

      # Do very simple pagination, by selecting one more object than necessary,
      # and noting if there is a next page by seeing if more objects are returned than the limit.
      def paginate(type, request, ds, opts={})
        return ds.all if opts[:all_results]
        limit = limit_for(type, request)
        %r{\/(\d+)\z} =~ request.env['PATH_INFO']
        offset = (($1||1).to_i - 1) * limit
        objs = ds.limit(limit+1, (offset if offset > 0)).all
        next_page = false
        if objs.length > limit
          next_page = true
          objs.pop
        end
        [next_page, objs]
      end

      # On the browse/search results pages, in addition to eager loading based on the current model's eager
      # loading config, also eager load based on the associated models config.
      def apply_associated_eager(type, request, ds)
        columns_for(type, request).each do |col|
          if association?(col)
            if model = associated_model_class(col)
              eager = model.eager_for(:association, request) || model.eager_graph_for(:association, request)
              ds = ds.eager(col=>eager)
            else
              ds = ds.eager(col)
            end
          end
        end
        ds
      end

      # The schema type for the column
      def column_type(column)
        (sch = model.db_schema[column]) && sch[:type]
      end

      # Apply the model's filter to the given dataset
      def apply_filter(type, request, ds)
        if filter = filter_for
          ds = filter.call(ds, type, request)
        end
        ds
      end

      # Apply the model's filter, eager, and order to the given dataset
      def apply_dataset_options(type, request, ds)
        ds = apply_filter(type, request, ds)
        if order = order_for(type, request)
          ds = ds.order(*order)
        end
        if eager = eager_for(type, request)
          ds = ds.eager(eager)
        end
        if eager_graph = eager_graph_for(type, request)
          ds = ds.eager_graph(eager_graph)
        end
        ds
      end

      # Whether to autocomplete for the given association.
      def association_autocomplete?(assoc, request)
        (c = associated_model_class(assoc)) && c.autocomplete_options_for(:association, request)
      end

      # Return array of autocompletion strings for the request.  Options:
      # :type :: Action type symbol
      # :request :: AutoForme::Request instance
      # :association :: Association symbol 
      # :query :: Query string submitted by the user
      # :exclude :: Primary key value of current model, excluding already associated values (used when
      #             editing many to many associations)
      def autocomplete(opts={})
        type, request, assoc, query, exclude = opts.values_at(:type, :request, :association, :query, :exclude)
        if assoc
          if exclude && association_type(assoc) == :edit
            ref = model.association_reflection(assoc)
            block = lambda do |ds|
              ds.exclude(S.qualify(ref.associated_class.table_name, ref.right_primary_key)=>model.db.from(ref[:join_table]).where(ref[:left_key]=>exclude).select(ref[:right_key]))
            end
          end
          return associated_model_class(assoc).autocomplete(opts.merge(:type=>:association, :association=>nil), &block)
        end
        opts = autocomplete_options_for(type, request)
        callback_opts = {:type=>type, :request=>request, :query=>query}
        ds = all_dataset_for(type, request)
        ds = opts[:callback].call(ds, callback_opts) if opts[:callback]
        display = opts[:display] || S.qualify(model.table_name, :name)
        display = display.call(callback_opts) if display.respond_to?(:call)
        limit = opts[:limit] || 10
        limit = limit.call(callback_opts) if limit.respond_to?(:call)
        opts[:filter] ||= lambda{|ds, opts| ds.where(S.ilike(display, "%#{ds.escape_like(query)}%"))}
        ds = opts[:filter].call(ds, callback_opts)
        ds = ds.select(S.join([S.qualify(model.table_name, model.primary_key), display], ' - ').as(:v)).
          limit(limit)
        ds = yield ds if block_given?
        ds.map(:v)
      end

      # Update the many to many association.  add and remove should be arrays of primary key values
      # of associated objects to add to the association.
      def mtm_update(request, assoc, obj, add, remove)
        ref = model.association_reflection(assoc)
        assoc_class = associated_model_class(assoc)
        ret = nil
        model.db.transaction do
          [[add, ref.add_method], [remove, ref.remove_method]].each do |ids, meth|
            if ids
              ids.each do |id|
                next if id.to_s.empty?
                ret = assoc_class ? assoc_class.with_pk(:association, request, id) : obj.send(:_apply_association_options, ref, ref.associated_class.dataset.clone).with_pk!(id)
                obj.send(meth, ret)
              end
            end
          end
        end
        ret
      end

      # The currently associated many to many objects for the association
      def associated_mtm_objects(request, assoc, obj)
        ds = obj.send("#{assoc}_dataset")
        if assoc_class = associated_model_class(assoc)
          ds = assoc_class.apply_dataset_options(:association, request, ds)
        end
        ds
      end

      # All objects in the associated table that are not currently associated to the given object.
      def unassociated_mtm_objects(request, assoc, obj)
        ref = model.association_reflection(assoc)
        assoc_class = associated_model_class(assoc)
        lambda do |ds|
          subquery = model.db.from(ref[:join_table]).
            select(ref.qualified_right_key).
            where(ref.qualified_left_key=>obj.pk)
          ds = ds.exclude(S.qualify(ref.associated_class.table_name, model.primary_key)=>subquery)
          ds = assoc_class.apply_dataset_options(:association, request, ds) if assoc_class
          ds
        end
      end

      private

      def dataset_for(type, request)
        ds = model.dataset
        if filter = filter_for
          ds = filter.call(ds, type, request)
        end
        ds
      end

      def all_dataset_for(type, request)
        apply_dataset_options(type, request, model.dataset)
      end
    end
  end

  register_model(:sequel, Models::Sequel)
end
