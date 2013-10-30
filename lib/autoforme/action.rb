module AutoForme
  # Represents an action on a model in response to a web request.
  class Action
    attr_reader :model
    attr_reader :request
    attr_reader :action

    def initialize(model, request)
      @model = model
      @request = request
      @action = request.action
    end

    def supported?
      return false unless idempotent? || request.post?
      return false unless model.supported_action?(action)
      true
    end

    def h(s)
      Rack::Utils.escape_html(s.to_s)
    end

    def idempotent?
      action !~ /\A(?:create|update|destroy|add_\w+|remove_\w+)\z/
    end

    def model_params
      request.params[model.params_name]
    end

    def url_for(page)
      "#{request.path}/#{request.model}/#{page}"
    end

    def redirect(page)
      request.redirect(url_for(page))
      nil
    end


    def handle
      send("handle_#{action}")
    end

    def tabs
      content = '<ul class="nav nav-tabs">'
      %w'browse new show edit delete search'.each do |action|
        if model.supported_action?(action)
          content << "<li class=\"#{'active' if request.action == action}\"><a href=\"#{url_for(action)}\">#{action == 'browse' ? request.model : action.capitalize}</a></li>"
        end
      end
      content << '</ul>'
    end

    def page
      html = tabs
      html << yield.to_s
      html
    end

    def new_page(obj, opts={})
      page do
        Forme.form(obj, :action=>url_for("create")) do |f|
          model.columns_for(:new).each do |column|
            f.input(column)
          end
          f.button('Create')
        end
      end
    end
    def handle_new
      new_page(model.new)
    end
    def handle_create
      obj = model.new
      model.set_fields(obj, :new, model_params)
      if model.save(obj)
        request.set_flash_notice("Created #{request.model}")
        redirect("new")
      else
        request.set_flash_now_error("Error Creating #{request.model}")
        new_page(obj)
      end
    end

    def list_page(type, opts={})
      page do
        form_attributes = opts[:form] || {:action=>url_for(type.to_s)}
        Forme.form(form_attributes) do |f|
          f.input(:select, :options=>model.select_options(type), :name=>'id', :id=>'id')
          f.button(type.to_s.capitalize)
        end
      end
    end

    def show_page(obj)
      page do
        Forme.form(obj, {}, :formatter=>:readonly) do |f|
          model.columns_for(:show).each do |column|
            f.input(column)
          end
        end
      end
    end
    def handle_show
      if request.id
        show_page(model.with_pk(request.id))
      else
        list_page(:show)
      end
    end

    def edit_page(obj)
      page do
        Forme.form(obj, :action=>url_for("update/#{obj.id}")) do |f|
          model.columns_for(:edit).each do |column|
            f.input(column)
          end
          f.button('Update')
        end
      end
    end
    def handle_edit
      if request.id
        edit_page(model.with_pk(request.id))
      else
        list_page(:edit)
      end
    end
    def handle_update
      obj = model.with_pk(request.id)
      model.set_fields(obj, :edit, model_params)
      if model.save(obj)
        request.set_flash_notice("Updated #{request.model}")
        redirect("edit/#{model.primary_key_value(obj)}")
      else
        request.set_flash_now_error("Error Updating #{request.model}")
        edit_page(obj)
      end
    end

    def handle_delete
      list_page(:delete, :form=>{:action=>url_for('destroy'), :method=>:post})
    end
    def handle_destroy
      model.destroy(request.id)
      request.set_flash_notice("Deleted #{request.model}")
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
    def table_page(type, next_page, objs)
      page do
        ModelTable.new(self, type, objs).to_s << table_pager(type, next_page)
      end
    end
    def handle_browse
      table_page(:browse, *model.browse(request))
    end

    def handle_search
      if request.id
        table_page(:search, *model.search_results(request))
      else
        page do
          Forme.form(model.new, :action=>url_for("search/1")) do |f|
            model.columns_for(:search).each do |column|
              f.input(column, :name=>column, :id=>column)
            end
            f.button('Search')
          end
        end
      end
    end
  end
end
