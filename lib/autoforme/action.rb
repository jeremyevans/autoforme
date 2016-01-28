require 'enum_csv'

module AutoForme
  # Represents an action on a model in response to a web request.
  class Action
    # The AutoForme::Model instance related to the current action
    attr_reader :model

    # The normalized type symbol related to the current action, so that paired actions
    # such as new and create both use :new.
    attr_reader :normalized_type

    # An association symbol for the current related association.
    attr_reader :params_association

    # The AutoForme::Request instance related to the current action
    attr_reader :request

    # An string suitable for use as the HTML title on the displayed page
    attr_reader :title

    # The type symbols related to the current action (e.g. :new, :create).
    attr_reader :type

    # The type of output, currently nil for normal output, and 'csv' for csv output
    attr_reader :output_type

    # The filename to use for file output
    attr_reader :output_filename

    # Array of strings for all action types currently supported
    ALL_SUPPORTED_ACTIONS = %w'new create show edit update delete destroy browse search mtm_edit mtm_update association_links autocomplete'.freeze

    # Map of regular type symbols to normalized type symbols
    NORMALIZED_ACTION_MAP = {:create=>:new, :update=>:edit, :destroy=>:delete, :mtm_update=>:mtm_edit}

    # Map of type symbols to HTML titles
    TITLE_MAP = {:new=>'New', :show=>'Show', :edit=>'Edit', :delete=>'Delete', :browse=>'Browse', :search=>'Search', :mtm_edit=>'Many To Many Edit'}

    # Creates a new action for the model and request.  This action is not
    # usable unless supported? is called first and it returns true.
    def initialize(model, request)
      @model = model
      @request = request
    end

    # Return true if the action is supported, and false otherwise.  An action
    # may not be supported if the type is not one of the supported types, or
    # if an non-idemponent request is issued with get instead of post, or
    # potentionally other reasons.
    #
    # As a side-effect, this sets up additional state related to the request.
    def supported?
      return false unless idempotent? || request.post?
      return false unless ALL_SUPPORTED_ACTIONS.include?(request.action_type)

      @type = request.action_type.to_sym
      @normalized_type = NORMALIZED_ACTION_MAP.fetch(@type, @type)

      case type
      when :mtm_edit
        return false unless model.supported_action?(type, request)
        if request.id && (assoc = request.params['association'])
          return false unless model.supported_mtm_edit?(assoc, request)
          @params_association = assoc.to_sym
        end

        @title = "#{model.class_name} - #{TITLE_MAP[type]}"
      when :mtm_update
        return false unless request.id && (assoc = request.params['association']) && model.supported_mtm_update?(assoc, request)
        @params_association = assoc.to_sym
      when :association_links
        @subtype = subtype
        return false unless model.supported_action?(@subtype, request)
      when :autocomplete
        if assoc = request.id
          return false unless model.association?(assoc)
          @params_association = assoc.to_sym
          @subtype = :association
        else
          @subtype = subtype
        end
        return false unless model.autocomplete_options_for(@subtype, request)
      else
        return false unless model.supported_action?(normalized_type, request)

        if title = TITLE_MAP[type]
          @title = "#{model.class_name} - #{title}"
        end
      end

      true
    end

    # Convert input to a string adn HTML escape it.
    def h(s)
      Rack::Utils.escape_html(s.to_s)
    end

    # Return whether the current action is an idempotent action.
    def idempotent?
      type == normalized_type
    end

    # Get request parameters for the model.  Used when retrieving form
    # values that use namespacing.
    def model_params
      request.params[model.params_name]
    end

    # A path for the given page tied to the framework, but not the current model.
    # Used for linking to other models in the same framework.
    def base_url_for(page)
      "#{request.path}#{model.framework.prefix}/#{page}"
    end

    # A path for the given page for the same model. 
    def url_for(page)
      base_url_for("#{model.link}/#{page}")
    end

    # The subtype of request, used for association_links and autocomplete actions.
    def subtype
      ((t = request.params['type']) && ALL_SUPPORTED_ACTIONS.include?(t) && t.to_sym) || :edit
    end

    # Redirect to a page based on the type of action and the given object.
    def redirect(type, obj)
      if redir = model.redirect_for
        path = redir.call(obj, type, request)
      end

      unless path
        path = case type
        when :new, :delete
          type.to_s
        when :edit
          "edit/#{model.primary_key_value(obj)}"
        when :mtm_edit
          "mtm_edit/#{model.primary_key_value(obj)}?association=#{params_association}"
        else
          raise Error, "Unhandled redirect type: #{type.inspect}"
        end
        path = url_for(path)
      end

      request.redirect(path)
      nil
    end

    # Handle the current action, returning an HTML string containing the page content,
    # or redirecting.
    def handle
      model.before_action_hook(type, request)
      send("handle_#{type}")
    end

    # Convert the given object into a suitable human readable string.
    def humanize(string)
      string = string.to_s
      string.respond_to?(:humanize) ? string.humanize : string.gsub(/_/, " ").capitalize
    end

    # The options to use for the given column, which will be passed to Forme::Form#input.
    def column_options_for(type, request, obj, column)
      opts = model.column_options_for(type, request, column)
      if opts[:class] == 'autoforme_autocomplete'
        if type == :show
          opts[:value] = model.column_value(type, request, obj, column)
        elsif key = obj.send(model.association_key(column))
          opts[:value] = "#{key} - #{model.column_value(type, request, obj, column)}"
        end
      end
      opts
    end

    # The label to use for the given column.
    def column_label_for(type, request, model, column)
      unless label = model.column_options_for(type, request, column)[:label]
        label = humanize(column)
      end
      label
    end

    # Return a string in CSV format with the results
    def csv(meth)
      @output_type = 'csv'
      @output_filename = "#{model.link.downcase}_#{normalized_type}.csv"
      columns = model.columns_for(type, request)
      headers = columns.map{|column| column_label_for(type, request, model, column)}
      EnumCSV.csv(model.send(meth, normalized_type, request, :all_results=>true), :headers=>headers) do |obj|
        columns.map{|column| model.column_value(type, request, obj, column)}
      end
    end

    # HTML fragment for the default page header, which uses tabs for each supported action.
    def tabs
      content = String.new
      content << '<ul class="nav nav-tabs">'
      Model::DEFAULT_SUPPORTED_ACTIONS.each do |action_type|
        if model.supported_action?(action_type, request)
          content << "<li class=\"#{'active' if type == action_type}\"><a href=\"#{url_for(action_type)}\">#{tab_name(action_type)}</a></li>"
        end
      end
      content << '</ul>'
    end

    # The name to give the tab for the given type.
    def tab_name(type)
      case type
      when :browse
        model.class_name
      when :mtm_edit
        'MTM'
      else
        type.to_s.capitalize
      end
    end

    # Yields and wraps the returned data in a header and footer for the page.
    def page
      html = String.new
      html << (model.page_header_for(type, request) || tabs)
      html << "<div id='autoforme_content' data-url='#{url_for('')}'>"
      html << yield.to_s
      html << "</div>"
      html << model.page_footer_for(type, request).to_s
      html
    end

    # Options to use for the form.  If the form uses POST, automatically adds the CSRF token.
    def form_opts
      opts = model.form_options_for(type, request).dup
      hidden_tags = opts[:hidden_tags] = []
      if csrf = request.csrf_token_hash
        hidden_tags << lambda{|tag| csrf if tag.attr[:method].to_s.upcase == 'POST'}
      end
      opts
    end

    # Merge the model's form attributes into the given form attributes, yielding the
    # attributes to use for the form.
    def form_attributes(attrs)
      attrs.merge(model.form_attributes_for(type, request))
    end

    # HTML content used for the new action
    def new_page(obj, opts={})
      page do
        Forme.form(obj, form_attributes(:action=>url_for("create")), form_opts) do |f|
          model.columns_for(:new, request).each do |column|
            col_opts = column_options_for(:new, request, obj, column)
            if html = model.edit_html_for(obj, column, :new, request)
              col_opts = col_opts.merge(:html=>html)
            end
            f.input(column, col_opts)
          end
          f.button(:value=>'Create', :class=>'btn btn-primary')
        end
      end
    end
    
    # Handle the new action by always showing the new form.
    def handle_new
      obj = model.new(request.params[model.link], request)
      model.hook(:before_new, request, obj)
      new_page(obj)
    end

    # Handle the create action by creating a new model object.
    def handle_create
      obj = model.new(nil, request)
      model.set_fields(obj, :new, request, model_params)
      model.hook(:before_create, request, obj)
      if model.save(obj)
        model.hook(:after_create, request, obj)
        request.set_flash_notice("Created #{model.class_name}")
        redirect(:new, obj)
      else
        request.set_flash_now_error("Error Creating #{model.class_name}")
        new_page(obj)
      end
    end

    # Shared page used by show, edit, and delete actions that shows a list of available
    # model objects (or an autocompleting box), and allows the user to choose one to act on.
    def list_page(type, opts={})
      page do
        form_attr = form_attributes(opts[:form] || {:action=>url_for(type)})
        Forme.form(form_attr, form_opts) do |f|
          input_opts = {:name=>'id', :id=>'id', :label=>model.class_name}
          if model.autocomplete_options_for(type, request)
            input_type = :text
            input_opts.merge!(:class=>'autoforme_autocomplete', :attr=>{'data-type'=>type})
          else
            input_type = :select
            input_opts.merge!(:options=>model.select_options(type, request), :add_blank=>true)
          end
          f.input(input_type, input_opts)
          f.button(:value=>type.to_s.capitalize, :class=>"btn btn-#{type == :delete ? 'danger' : 'primary'}")
        end
      end
    end

    # The page to use when displaying an object, always used as a confirmation screen when deleting an object.
    def show_page(obj)
      page do
        t = String.new
        f = Forme::Form.new(obj, :formatter=>:readonly, :wrapper=>:trtd, :labeler=>:explicit)
        t << "<table class=\"#{model.table_class_for(:show, request)}\">"
        model.columns_for(type, request).each do |column|
          col_opts = column_options_for(type, request, obj, column)
          if html = model.show_html_for(obj, column, type, request)
            col_opts = col_opts.merge(:html=>html)
          end
          t << f.input(column, col_opts).to_s
        end
        t << '</table>'
        if type == :show && model.supported_action?(:edit, request)
          t << Forme.form(form_attributes(:action=>url_for("edit/#{model.primary_key_value(obj)}")), form_opts) do |f|
            f.button(:value=>'Edit', :class=>'btn btn-primary')
          end.to_s
        end
        if type == :delete
          t << Forme.form(form_attributes(:action=>url_for("destroy/#{model.primary_key_value(obj)}"), :method=>:post), form_opts) do |f|
            f.button(:value=>'Delete', :class=>'btn btn-danger')
          end.to_s
        else
          t << association_links(obj)
        end
        t
      end
    end

    # Handle the show action by showing a list page if there is no model object selected, or the show page if there is one.
    def handle_show
      if request.id
        show_page(model.with_pk(normalized_type, request, request.id))
      else
        list_page(:show)
      end
    end

    # The page to use when editing the object.
    def edit_page(obj)
      page do
        t = String.new
        t << Forme.form(obj, form_attributes(:action=>url_for("update/#{model.primary_key_value(obj)}")), form_opts) do |f|
          model.columns_for(:edit, request).each do |column|
            col_opts = column_options_for(:edit, request, obj, column)
            if html = model.edit_html_for(obj, column, :edit, request)
              col_opts = col_opts.merge(:html=>html)
            end
            f.input(column, col_opts)
          end
          f.button(:value=>'Update', :class=>'btn btn-primary')
        end.to_s
        if model.supported_action?(:delete, request)
          t << Forme.form(form_attributes(:action=>url_for("delete/#{model.primary_key_value(obj)}")), form_opts) do |f|
            f.button(:value=>'Delete', :class=>'btn btn-danger')
          end.to_s
        end
        t << association_links(obj)
      end
    end

    # Handle the edit action by showing a list page if there is no model object selected, or the edit page if there is one.
    def handle_edit
      if request.id
        obj = model.with_pk(normalized_type, request, request.id)
        model.hook(:before_edit, request, obj)
        edit_page(obj)
      else
        list_page(:edit)
      end
    end

    # Handle the update action by updating the current model object.
    def handle_update
      obj = model.with_pk(normalized_type, request, request.id)
      model.set_fields(obj, :edit, request, model_params)
      model.hook(:before_update, request, obj)
      if model.save(obj)
        model.hook(:after_update, request, obj)
        request.set_flash_notice("Updated #{model.class_name}")
        redirect(:edit, obj)
      else
        request.set_flash_now_error("Error Updating #{model.class_name}")
        edit_page(obj)
      end
    end

    # Handle the edit action by showing a list page if there is no model object selected, or a confirmation screen if there is one.
    def handle_delete
      if request.id
        handle_show
      else
        list_page(:delete, :form=>{:action=>url_for('delete')})
      end
    end

    # Handle the destroy action by destroying the model object.
    def handle_destroy
      obj = model.with_pk(normalized_type, request, request.id)
      model.hook(:before_destroy, request, obj)
      model.destroy(obj)
      model.hook(:after_destroy, request, obj)
      request.set_flash_notice("Deleted #{model.class_name}")
      redirect(:delete, obj)
    end

    # HTML fragment for the table pager, showing links to next page or previous page for browse/search forms.
    def table_pager(type, next_page)
      html = String.new
      html << '<ul class="pager">'
      page = request.id.to_i
      if page > 1
        html << "<li><a href=\"#{url_for("#{type}/#{page-1}?#{h request.query_string}")}\">Previous</a></li>"
      else
        html << '<li class="disabled"><a href="#">Previous</a></li>'
      end
      if next_page
        page = 1 if page < 1
        html << "<li><a href=\"#{url_for("#{type}/#{page+1}?#{h request.query_string}")}\">Next</a></li>"
      else
        html << '<li class="disabled"><a href="#">Next</a></li>'
      end
      html << "</ul>"
      html << "<p><a href=\"#{url_for("#{type}/csv?#{h request.query_string}")}\">CSV Format</a></p>"
    end

    # Show page used for browse/search pages.
    def table_page(next_page, objs)
      page do
        Table.new(self, objs).to_s << table_pager(normalized_type, next_page)
      end
    end

    # Handle browse action by showing a table containing model objects.
    def handle_browse
      if request.id == 'csv'
        csv(:browse)
      else
        table_page(*model.browse(type, request))
      end
    end

    # Handle browse action by showing a search form if no page is selected, or the correct page of search results
    # if there is a page selected.
    def handle_search
      if request.id == 'csv'
        csv(:search_results)
      elsif request.id
        table_page(*model.search_results(normalized_type, request))
      else
        page do
          Forme.form(model.new(nil, request), form_attributes(:action=>url_for("search/1"), :method=>:get), form_opts) do |f|
            model.columns_for(:search_form, request).each do |column|
              col_opts = column_options_for(:search_form, request, f.obj, column).merge(:name=>column, :id=>column)
              if html = model.edit_html_for(f.obj, column, :search_form, request)
                col_opts[:html] = html
              end
              f.input(column, col_opts)
            end
            f.button(:value=>'Search', :class=>'btn btn-primary')
          end
        end
      end
    end

    # Handle the mtm_edit action by showing a list page if there is no model object selected, a list of associations for that model
    # if there is a model object but no association selected, or a mtm_edit form if there is a model object and association selected.
    def handle_mtm_edit
      if id = request.id
        obj = model.with_pk(:edit, request, request.id)
        unless assoc = params_association
          options = model.mtm_association_select_options(request)
          if options.length == 1
            assoc = options.first
          end
        end
        if assoc
          page do
            t = String.new
            t << "<h2>Edit #{humanize(assoc)} for #{h model.object_display_name(type, request, obj)}</h2>"
            t << Forme.form(obj, form_attributes(:action=>url_for("mtm_update/#{model.primary_key_value(obj)}?association=#{assoc}")), form_opts) do |f|
              opts = model.column_options_for(:mtm_edit, request, assoc)
              add_opts = opts[:add] ? opts.merge(opts.delete(:add)) : opts
              remove_opts = opts[:remove] ? opts.merge(opts.delete(:remove)) : opts
              add_opts = {:name=>'add[]', :id=>'add', :label=>'Associate With'}.merge(add_opts)
              if model.association_autocomplete?(assoc, request)
                f.input(assoc, {:type=>'text', :class=>'autoforme_autocomplete', :attr=>{'data-type'=>'association', 'data-column'=>assoc, 'data-exclude'=>model.primary_key_value(obj)}, :value=>''}.merge(add_opts))
              else
                f.input(assoc, {:dataset=>model.unassociated_mtm_objects(request, assoc, obj)}.merge(add_opts))
              end
              f.input(assoc, {:name=>'remove[]', :id=>'remove', :label=>'Disassociate From', :dataset=>model.associated_mtm_objects(request, assoc, obj), :value=>[]}.merge(remove_opts))
              f.button(:value=>'Update', :class=>'btn btn-primary')
            end.to_s
          end
        else
          page do
            Forme.form(form_attributes(:action=>"mtm_edit/#{model.primary_key_value(obj)}"), form_opts) do |f|
              f.input(:select, :options=>options, :name=>'association', :id=>'association', :label=>'Association', :add_blank=>true)
              f.button(:value=>'Edit', :class=>'btn btn-primary')
            end
          end
        end
      else
        list_page(:edit, :form=>{})
      end
    end

    # Handle mtm_update action by updating the related many to many association.  For ajax requests,
    # return an HTML fragment to update the page, otherwise redirect to the appropriate form.
    def handle_mtm_update
      obj = model.with_pk(:edit, request, request.id)
      assoc = params_association
      assoc_obj = model.mtm_update(request, assoc, obj, request.params['add'], request.params['remove'])
      request.set_flash_notice("Updated #{assoc} association for #{model.class_name}") unless request.xhr?
      if request.xhr?
        if add = request.params['add']
          @type = :edit
          mtm_edit_remove(assoc, model.associated_model_class(assoc), obj, assoc_obj)
        else
          "<option value=\"#{model.primary_key_value(assoc_obj)}\">#{model.associated_object_display_name(assoc, request, assoc_obj)}</option>"
        end
      elsif request.params['redir'] == 'edit'
        redirect(:edit, obj)
      else
        redirect(:mtm_edit, obj)
      end
    end

    # Handle association_links action by returning an HTML fragment of association links.
    def handle_association_links
      @type = @normalized_type = @subtype
      obj = model.with_pk(@type, request, request.id)
      association_links(obj)
    end

    # Handle autocomplete action by returning a string with one line per model object.
    def handle_autocomplete
      unless (query = request.params['q'].to_s).empty?
        model.autocomplete(:type=>@subtype, :request=>request, :association=>params_association, :query=>query, :exclude=>request.params['exclude']).join("\n")
      end
    end

    # HTML fragment containing the association links for the given object, or a link to lazily load them
    # if configured.  Also contains the inline mtm_edit forms when editing.
    def association_links(obj)
      if model.lazy_load_association_links?(type, request) && normalized_type != :association_links && request.params['associations'] != 'show'
        "<div id='lazy_load_association_links' data-object='#{model.primary_key_value(obj)}' data-type='#{type}'><a href=\"#{url_for("#{type}/#{model.primary_key_value(obj)}?associations=show")}\">Show Associations</a></div>"
      elsif type == :show
        association_link_list(obj).to_s
      else
        "#{inline_mtm_edit_forms(obj)}#{association_link_list(obj)}"
      end
    end

    # HTML fragment for the list of association links, allowing quick access to associated models and objects.
    def association_link_list(obj)
      assocs = model.association_links_for(type, request) 
      return if assocs.empty?
      read_only = type == :show
      t = String.new
      t << '<h3 class="associated_records_header">Associated Records</h3>'
      t << "<ul class='association_links'>\n"
      assocs.each do |assoc|
        mc = model.associated_model_class(assoc)
        t << "<li>"
        t << association_class_link(mc, assoc)
        t << "\n "

        case model.association_type(assoc)
        when :one
          if assoc_obj = obj.send(assoc)
            t << " - "
            t << association_link(mc, assoc_obj)
          end
          assoc_objs = []
        when :edit
          if !read_only && model.supported_mtm_edit?(assoc.to_s, request)
            t << "(<a href=\"#{url_for("mtm_edit/#{model.primary_key_value(obj)}?association=#{assoc}")}\">associate</a>)"
          end
          assoc_objs = obj.send(assoc)
        when :new
          if !read_only && mc && mc.supported_action?(:new, request)
            params = model.associated_new_column_values(obj, assoc).map do |col, value|
              "#{mc.link}%5b#{col}%5d=#{value}"
            end
            t << "(<a href=\"#{base_url_for("#{mc.link}/new?#{params.join('&amp;')}")}\">create</a>)"
          end
          assoc_objs = obj.send(assoc)
        else
          assoc_objs = []
        end

        unless assoc_objs.empty?
          t << "<ul>\n"
          assoc_objs.each do |assoc_obj|
            t << "<li>"
            t << association_link(mc, assoc_obj)
            t << "</li>"
          end
          t << "</ul>"
        end

        t << "</li>"
      end
      t << "</ul>"
    end

    # If the framework contains the associated model class and that supports browsing,
    # return a link to the associated browse page, otherwise, just return the name.
    def association_class_link(mc, assoc)
      assoc_name = humanize(assoc)
      if mc && mc.supported_action?(:browse, request)
        "<a href=\"#{base_url_for("#{mc.link}/browse")}\">#{assoc_name}</a>"
      else
        assoc_name
      end
    end

    # For the given associated object, if the framework contains the associated model class,
    # and that supports the type of action we are doing, return a link to the associated action
    # page.
    def association_link(mc, assoc_obj)
      if mc
        t = mc.object_display_name(:association, request, assoc_obj)
        if mc.supported_action?(type, request)
          t = "<a href=\"#{base_url_for("#{mc.link}/#{type}/#{mc.primary_key_value(assoc_obj)}")}\">#{t}</a>"
        end
        t
      else
        model.default_object_display_name(assoc_obj)
      end
    end

    # HTML fragment used for the inline mtm_edit forms on the edit page.
    def inline_mtm_edit_forms(obj)
      assocs = model.inline_mtm_assocs(request)
      return if assocs.empty?

      t = String.new
      t << "<div class='inline_mtm_add_associations'>"
      assocs.each do |assoc|
        form_attr = form_attributes(:action=>url_for("mtm_update/#{model.primary_key_value(obj)}?association=#{assoc}&redir=edit"), :class => 'mtm_add_associations', 'data-remove' => "##{assoc}_remove_list")
        t << Forme.form(obj, form_attr, form_opts) do |f|
          opts = model.column_options_for(:mtm_edit, request, assoc)
          add_opts = opts[:add] ? opts.merge(opts.delete(:add)) : opts.dup
          add_opts = {:name=>'add[]', :id=>"add_#{assoc}"}.merge(add_opts)
          if model.association_autocomplete?(assoc, request)
            f.input(assoc, {:type=>'text', :class=>'autoforme_autocomplete', :attr=>{'data-type'=>'association', 'data-column'=>assoc, 'data-exclude'=>model.primary_key_value(obj)}, :value=>''}.merge(add_opts))
          else
            f.input(assoc, {:dataset=>model.unassociated_mtm_objects(request, assoc, obj), :multiple=>false, :add_blank=>true}.merge(add_opts))
          end
          f.button(:value=>'Add', :class=>'btn btn-mini btn-primary')
        end.to_s
      end
      t << "</div>"
      t << "<div class='inline_mtm_remove_associations'><ul>"
      assocs.each do |assoc|
        mc = model.associated_model_class(assoc)
        t << "<li>"
        t << association_class_link(mc, assoc)
        t << "<ul id='#{assoc}_remove_list'>"
        obj.send(assoc).each do |assoc_obj|
          t << mtm_edit_remove(assoc, mc, obj, assoc_obj)
        end
        t << "</ul></li>"
      end
      t << "</ul></div>"
    end

    # Line item containing form to remove the currently associated object.
    def mtm_edit_remove(assoc, mc, obj, assoc_obj)
      t = String.new
      t << "<li>"
      t << association_link(mc, assoc_obj)
      form_attr = form_attributes(:action=>url_for("mtm_update/#{model.primary_key_value(obj)}?association=#{assoc}&remove%5b%5d=#{model.primary_key_value(assoc_obj)}&redir=edit"), :method=>'post', :class => 'mtm_remove_associations', 'data-add'=>"#add_#{assoc}")
      t << Forme.form(form_attr, form_opts) do |f|
        f.button(:value=>'Remove', :class=>'btn btn-mini btn-danger')
      end.to_s
      t << "</li>"
    end
  end
end
