module AutoForme
  # Represents an action on a model in response to a web request.
  class Action
    attr_reader :model
    attr_reader :request
    attr_reader :type
    attr_reader :normalized_type

    NORMALIZED_ACTION_MAP = {'create'=>'new', 'update'=>'edit', 'destroy'=>'delete', 'mtm_update'=>'mtm_edit'}
    def initialize(model, request)
      @model = model
      @request = request
      @type = request.action_type
      @normalized_type = NORMALIZED_ACTION_MAP.fetch(@type, @type)
    end

    def supported?
      return false unless idempotent? || request.post?

      case type
      when 'mtm_edit'
        return false unless model.supported_action?(type)
        if request.id && request.params['association']
          return false unless model.supported_mtm_edit?(request.params['association'])
        end
      when 'mtm_update'
        return false unless request.id && request.params['association'] && model.supported_mtm_update?(request.params['association'])
      when 'association_links'
        return false unless model.supported_action?(request.params['type'] || 'edit')
      when 'autocomplete'
        return false unless model.autocomplete_options_for(request.params['type'])
      else
        return false unless model.supported_action?(normalized_type)
      end

      true
    end

    def h(s)
      Rack::Utils.escape_html(s.to_s)
    end

    def idempotent?
      type == normalized_type
    end

    def model_params
      request.params[model.params_name]
    end

    def base_url_for(page)
      "#{request.path}/#{page}"
    end

    def url_for(page)
      base_url_for("#{model.link}/#{page}")
    end

    def redirect(page)
      request.redirect(url_for(page))
      nil
    end

    def handle
      send("handle_#{type}")
    end

    def humanize(string)
      string = string.to_s
      string.respond_to?(:humanize) ? string.humanize : string.gsub(/_/, " ").capitalize
    end

    def column_options_for(type, request, obj, column)
      opts = model.column_options_for(type, request, column)
      if opts[:class] == 'autoforme_autocomplete'
        opts[:value] = "#{obj.send(model.association_key(column))} - #{model.column_value(type, request, obj, column)}"
      end
      opts
    end

    def column_label_for(type, request, model, column)
      unless label = model.column_options_for(type, request, column)[:label]
        label = humanize(column)
      end
      label
    end

    def tabs
      content = '<ul class="nav nav-tabs">'
      %w'browse new show edit delete search mtm_edit'.each do |action_type|
        if model.supported_action?(action_type)
          content << "<li class=\"#{'active' if type == action_type}\"><a href=\"#{url_for(action_type)}\">#{tab_name(action_type)}</a></li>"
        end
      end
      content << '</ul>'
    end
    def tab_name(type)
      case type
      when 'browse'
        model.class_name
      when 'mtm_edit'
        'MTM'
      else
        type.capitalize
      end
    end

    def page
      html = tabs
      html << yield.to_s
      html << <<JS
<script type="text/javascript">
$('.autoforme_autocomplete').each(function(){
  var e = $(this);
  var column = e.data('column');
  var exclude = e.data('exclude');
  var url = '#{request.path}/#{model.link}/autocomplete';
  if (column) {
    url += '/' + column;
  }
  url += '?type=' + e.data('type');
  if (exclude) {
    url += '&exclude=' + exclude;
  }
  e.autocomplete(url);
});
$('form').submit(function(e){
  $(this).find('.autoforme_autocomplete').each(function(){
    $(this).val($(this).val().split(' - ', 2)[0]);
  });
});
</script>
JS
      html
    end

    def form_opts
      opts = {}
      hidden_tags = opts[:hidden_tags] = []
      if csrf = request.csrf_token_hash
        hidden_tags << lambda{|tag| csrf if tag.attr[:method].to_s.upcase == 'POST'}
      end
      opts
    end

    def new_page(obj, opts={})
      page do
        Forme.form(obj, {:action=>url_for("create")}, form_opts) do |f|
          model.columns_for(:new).each do |column|
            f.input(column, column_options_for(:new, request, obj, column))
          end
          f.button(:value=>'Create', :class=>'btn btn-primary')
        end
      end
    end
    def handle_new
      new_page(model.new(request.params[model.link]))
    end
    def handle_create
      obj = model.new
      model.set_fields(obj, :new, request, model_params)
      model.hook(:before_create, request, obj)
      if model.save(obj)
        model.hook(:after_create, request, obj)
        request.set_flash_notice("Created #{model.class_name}")
        redirect("new")
      else
        request.set_flash_now_error("Error Creating #{model.class_name}")
        new_page(obj)
      end
    end

    def list_page(type, opts={})
      page do
        form_attributes = opts[:form] || {:action=>url_for(type.to_s)}
        Forme.form(form_attributes, form_opts) do |f|
          input_opts = {:name=>'id', :id=>'id', :label=>model.class_name}
          if model.autocomplete_options_for(type)
            input_type = :text
            input_opts.merge!(:class=>'autoforme_autocomplete', :attr=>{'data-type'=>type})
          else
            input_type = :select
            input_opts.merge!(:options=>model.select_options(type, request))
          end
          f.input(input_type, input_opts)
          f.button(:value=>type.to_s.capitalize, :class=>"btn btn-#{type.to_s == 'delete' ? 'danger' : 'primary'}")
        end
      end
    end

    def show_page(obj)
      page do
        t = ''
        f = Forme::Form.new(obj, :formatter=>:readonly)
        model.columns_for(type.to_sym).each do |column|
          t << f.input(column, model.column_options_for(:show, request, column)).to_s
        end
        if type == 'show' && model.supported_action?('edit')
          t << Forme.form({:action=>url_for("edit/#{model.primary_key_value(obj)}")}, form_opts) do |f|
            f.button(:value=>'Edit', :class=>'btn btn-primary')
          end.to_s
        end
        if type == 'delete'
          t << Forme.form({:action=>url_for("destroy/#{model.primary_key_value(obj)}"), :method=>:post}, form_opts) do |f|
            f.button(:value=>'Delete', :class=>'btn btn-danger')
          end.to_s
        else
          t << association_links(obj)
        end
        t
      end
    end
    def handle_show
      if request.id
        show_page(model.with_pk(normalized_type, request, request.id))
      else
        list_page(:show)
      end
    end

    def edit_page(obj)
      page do
        t = Forme.form(obj, {:action=>url_for("update/#{model.primary_key_value(obj)}")}, form_opts) do |f|
          model.columns_for(:edit).each do |column|
            f.input(column, column_options_for(:edit, request, obj, column))
          end
          f.button(:value=>'Update', :class=>'btn btn-primary')
        end.to_s
        if model.supported_action?('delete')
          t << Forme.form({:action=>url_for("delete/#{model.primary_key_value(obj)}")}, form_opts) do |f|
            f.button(:value=>'Delete', :class=>'btn btn-danger')
          end.to_s
        end
        t << association_links(obj)
      end
    end
    def handle_edit
      if request.id
        edit_page(model.with_pk(normalized_type, request, request.id))
      else
        list_page(:edit)
      end
    end
    def handle_update
      obj = model.with_pk(normalized_type, request, request.id)
      model.set_fields(obj, :edit, request, model_params)
      model.hook(:before_update, request, obj)
      if model.save(obj)
        model.hook(:after_update, request, obj)
        request.set_flash_notice("Updated #{model.class_name}")
        redirect("edit/#{model.primary_key_value(obj)}")
      else
        request.set_flash_now_error("Error Updating #{model.class_name}")
        edit_page(obj)
      end
    end

    def handle_delete
      if request.id
        handle_show
      else
        list_page(:delete, :form=>{:action=>url_for('delete')})
      end
    end
    def handle_destroy
      obj = model.with_pk(normalized_type, request, request.id)
      model.hook(:before_destroy, request, obj)
      model.destroy(obj)
      model.hook(:after_destroy, request, obj)
      request.set_flash_notice("Deleted #{model.class_name}")
      redirect("delete")
    end

    def table_pager(type, next_page)
      html = '<ul class="pager">'
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
    end
    def table_page(next_page, objs)
      page do
        ModelTable.new(self, objs).to_s << table_pager(normalized_type, next_page)
      end
    end
    def handle_browse
      table_page(*model.browse(type, request))
    end

    def handle_search
      if request.id
        table_page(*model.search_results(normalized_type, request))
      else
        page do
          Forme.form(model.new, {:action=>url_for("search/1"), :method=>:get}, form_opts) do |f|
            model.columns_for(:search_form).each do |column|
              f.input(column, {:name=>column, :id=>column}.merge(column_options_for(:search_form, request, f.obj, column)))
            end
            f.button(:value=>'Search', :class=>'btn btn-primary')
          end
        end
      end
    end

    def handle_mtm_edit
      if id = request.id
        obj = model.with_pk(:edit, request, request.id)
        if assoc = request.params['association']
          assoc = assoc.to_sym
          page do
            Forme.form(obj, {:action=>url_for("mtm_update/#{model.primary_key_value(obj)}?association=#{assoc}")}, form_opts) do |f|
              opts = model.column_options_for(:mtm_edit, request, assoc)
              add_opts = opts[:add] ? opts.merge(opts.delete(:add)) : opts
              remove_opts = opts[:remove] ? opts.merge(opts.delete(:remove)) : opts
              add_opts = {:name=>'add[]', :id=>'add', :label=>'Associate With'}.merge(add_opts)
              if model.association_autocomplete?(assoc)
                f.input(assoc, {:type=>'text', :class=>'autoforme_autocomplete', :attr=>{'data-type'=>'association', 'data-column'=>assoc, 'data-exclude'=>model.primary_key_value(obj)}, :value=>''}.merge(add_opts))
              else
                f.input(assoc, {:dataset=>model.unassociated_mtm_objects(request, assoc, obj)}.merge(add_opts))
              end
              f.input(assoc, {:name=>'remove[]', :id=>'remove', :label=>'Disassociate From', :dataset=>model.associated_mtm_objects(request, assoc, obj), :value=>[]}.merge(remove_opts))
              f.button(:value=>'Update', :class=>'btn btn-primary')
            end
          end
        else
          page do
            Forme.form({:action=>"mtm_edit/#{model.primary_key_value(obj)}"}, form_opts) do |f|
              f.input(:select, :options=>model.mtm_association_select_options, :name=>'association', :id=>'association', :label=>'Association')
              f.button(:value=>'Edit', :class=>'btn btn-primary')
            end
          end
        end
      else
        list_page(:edit, :form=>{})
      end
    end
    def handle_mtm_update
      obj = model.with_pk(:edit, request, request.id)
      assoc = request.params['association'].to_sym
      assoc_obj = model.mtm_update(request, assoc, obj, request.params['add'], request.params['remove'])
      request.set_flash_notice("Updated #{assoc} association for #{model.class_name}")
      if request.xhr?
        if add = request.params['add']
          @type = 'edit'
          mtm_edit_remove(assoc, model.associated_model_class(assoc), obj, assoc_obj, true)
        else
          "<option value=\"#{model.primary_key_value(assoc_obj)}\">#{model.associated_object_display_name(assoc, request, assoc_obj)}</option>"
        end
      elsif request.params['redir'] == 'edit'
        redirect("edit/#{model.primary_key_value(obj)}")
      else
        redirect("mtm_edit/#{model.primary_key_value(obj)}?association=#{assoc}")
      end
    end

    def handle_association_links
      @type = request.params['type'] || 'edit'
      obj = model.with_pk(type, request, request.id)
      association_links(obj)
    end

    def handle_autocomplete
      unless (query = request.params['q'].to_s).empty?
        model.autocomplete(:type=>request.params['type'], :request=>request, :association=>request.id, :query=>query, :exclude=>request.params['exclude']).join("\n")
      end
    end

    def association_links(obj)
      if model.lazy_load_association_links? && normalized_type != 'association_links' && request.params['associations'] != 'show'
        t = "<div id='lazy_load_association_links'><a href=\"#{url_for("#{type}/#{model.primary_key_value(obj)}?associations=show")}\">Show Associations</a></div>"
        if model.ajax_association_links?
          t << <<JS
<script type="text/javascript">
$('#lazy_load_association_links').click(function(e){
  $('#lazy_load_association_links').load("#{url_for("association_links/#{model.primary_key_value(obj)}?type=#{type}")}");
  $('#lazy_load_association_links').unbind('click');
  e.preventDefault();
});
</script>
JS
        end
        t
      elsif type == 'show'
        association_link_list(obj).to_s
      else
        "#{inline_mtm_edit_forms(obj)}#{association_link_list(obj)}"
      end
    end

    def association_link_list(obj)
      assocs = model.association_links_for(type) 
      return if assocs.empty?
      read_only = type == 'show'
      t = '<h3 class="associated_records_header">Associated Records</h3>'
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
          if !read_only && model.supported_mtm_edit?(assoc.to_s)
            t << "(<a href=\"#{url_for("mtm_edit/#{model.primary_key_value(obj)}?association=#{assoc}")}\">associate</a>)"
          end
          assoc_objs = obj.send(assoc)
        when :new
          if !read_only && mc && mc.supported_action?('new')
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
    def association_class_link(mc, assoc)
      assoc_name = humanize(assoc)
      if mc && mc.supported_action?('browse')
        "<a href=\"#{base_url_for("#{mc.link}/browse")}\">#{assoc_name}</a>"
      else
        assoc_name
      end
    end
    def association_link(mc, assoc_obj)
      if mc
        t = mc.object_display_name(:association, request, assoc_obj)
        if mc.supported_action?(type)
          t = "<a href=\"#{base_url_for("#{mc.link}/#{type}/#{mc.primary_key_value(assoc_obj)}")}\">#{t}</a>"
        end
        t
      else
        model.default_object_display_name(assoc_obj)
      end
    end

    def inline_mtm_edit_forms(obj)
      assocs = model.inline_mtm_assocs
      return if assocs.empty?
      ajax = model.ajax_inline_mtm_associations?

      t = "<div class='inline_mtm_add_associations'>"
      assocs.each do |assoc|
        form_attr = {:action=>url_for("mtm_update/#{model.primary_key_value(obj)}?association=#{assoc}&amp;redir=edit")}
        if ajax
          form_attr[:class] = 'ajax_mtm_add_associations'
          form_attr['data-remove'] = "##{assoc}_remove_list"
        end
        t << Forme.form(obj, form_attr, form_opts) do |f|
          opts = model.column_options_for(:mtm_edit, request, assoc)
          add_opts = opts[:add] ? opts.merge(opts.delete(:add)) : opts.dup
          f.input(assoc, {:name=>'add[]', :id=>"add_#{assoc}", :dataset=>model.unassociated_mtm_objects(request, assoc, obj), :multiple=>false, :add_blank=>true}.merge(add_opts))
          f.button(:value=>'Add', :class=>'btn btn-primary')
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
          t << mtm_edit_remove(assoc, mc, obj, assoc_obj, ajax)
        end
        t << "</ul></li>"
      end
      t << "</ul></div>"
      if ajax
        t << <<JS
<script type="text/javascript">
$('.ajax_mtm_add_associations').submit(function(e){
  var form = $(this);
  var select = form.find('select')[0];
  $.post(this.action, form.serialize(), function(data, textStatus){
    $(select).find('option:selected').remove();
    select.selectedIndex = 0;
    $(form.data('remove')).append(data);
  });
  e.preventDefault();
});
$('.inline_mtm_remove_associations').on("submit", "form", function(e){
  var form = $(this);
  var parent = form.parent();
  $.post(this.action, form.serialize(), function(data, textStatus){
    $(form.data('add')).append(data);
    parent.remove()
  });
  e.preventDefault();
});
</script>
JS
      end
      t
    end
    def mtm_edit_remove(assoc, mc, obj, assoc_obj, ajax)
      t = "<li>"
      t << association_link(mc, assoc_obj)
      form_attr = {:action=>url_for("mtm_update/#{model.primary_key_value(obj)}?association=#{assoc}&amp;remove%5b%5d=#{model.primary_key_value(assoc_obj)}&amp;redir=edit"), :method=>'post'}
      if ajax
        form_attr[:class] = 'ajax_mtm_remove_associations'
        form_attr['data-add'] = "#add_#{assoc}"
      end
      t << Forme.form(form_attr, form_opts) do |f|
        f.button(:value=>'Remove', :class=>'btn btn-danger')
      end.to_s
      t << "</li>"
    end
  end
end
