require_relative 'spec_helper'

describe AutoForme do
  before(:all) do
    db_setup(:artists=>[[:name, :string]])
    model_setup(:Artist=>[:artists])
  end
  after(:all) do
    Object.send(:remove_const, :Artist)
  end

  it "should have basic functionality working" do
    app_setup(Artist)
    visit("/Artist/new")
    page.html.must_include '<!DOCTYPE html>'
    page.title.must_equal 'Artist - New'
    fill_in 'Name', :with=>'TestArtistNew'
    click_button 'Create'
    page.html.must_include 'Created Artist'
    page.current_path.must_equal '/Artist/new'

    click_link 'Show'
    page.title.must_equal 'Artist - Show'
    click_button 'Show'
    select 'TestArtistNew'
    click_button 'Show'
    page.html.must_match(/Name.+TestArtistNew/m)

    click_link 'Edit'
    page.title.must_equal 'Artist - Edit'
    click_button 'Edit'
    select 'TestArtistNew'
    click_button 'Edit'
    fill_in 'Name', :with=>'TestArtistUpdate'
    click_button 'Update'
    page.html.must_include 'Updated Artist'
    page.html.must_match(/Name.+TestArtistUpdate/m)
    page.current_path.must_match %r{/Artist/edit/\d+}

    click_link 'Search'
    page.title.must_equal 'Artist - Search'
    fill_in 'Name', :with=>'Upd'
    click_button 'Search'
    page.all('table').first['id'].must_equal 'autoforme_table'
    page.all('th').map{|s| s.text}.must_equal ['Name', 'Show', 'Edit', 'Delete']
    page.all('td').map{|s| s.text}.must_equal ["TestArtistUpdate", "Show", "Edit", "Delete"]
    click_link 'CSV Format'
    page.body.must_equal "Name\nTestArtistUpdate\n"

    visit("/Artist/browse")
    click_link 'Search'
    fill_in 'Name', :with=>'Foo'
    click_button 'Search'
    page.all('td').map{|s| s.text}.must_equal []

    click_link 'Artist'
    page.title.must_equal 'Artist - Browse'
    page.all('td').map{|s| s.text}.must_equal ["TestArtistUpdate", "Show", "Edit", "Delete"]
    click_link 'CSV Format'
    page.body.must_equal "Name\nTestArtistUpdate\n"

    visit("/Artist/destroy/#{Artist.first.id}")
    page.html.must_include 'Unhandled Request'

    visit("/Artist/browse")
    page.all('td').last.find('a').click
    click_button 'Delete'
    page.title.must_equal 'Artist - Delete'
    page.html.must_include 'Deleted Artist'
    page.current_path.must_equal '/Artist/delete'

    click_link 'Artist'
    page.all('td').map{|s| s.text}.must_equal []
  end

  it "should have basic functionality working in a subdirectory" do
    app_setup(Artist, :prefix=>"/prefix")
    visit("/prefix/Artist/new")
    fill_in 'Name', :with=>'TestArtistNew'
    click_button 'Create'
    page.html.must_include 'Created Artist'
    page.current_path.must_equal '/prefix/Artist/new'

    click_link 'Show'
    select 'TestArtistNew'
    click_button 'Show'
    page.html.must_match(/Name.+TestArtistNew/m)

    click_link 'Edit'
    select 'TestArtistNew'
    click_button 'Edit'
    fill_in 'Name', :with=>'TestArtistUpdate'
    click_button 'Update'
    page.html.must_include 'Updated Artist'
    page.html.must_match(/Name.+TestArtistUpdate/m)
    page.current_path.must_match %r{/prefix/Artist/edit/\d+}

    click_link 'Search'
    fill_in 'Name', :with=>'Upd'
    click_button 'Search'
    page.all('th').map{|s| s.text}.must_equal ['Name', 'Show', 'Edit', 'Delete']
    page.all('td').map{|s| s.text}.must_equal ["TestArtistUpdate", "Show", "Edit", "Delete"]

    click_link 'Search'
    fill_in 'Name', :with=>'Foo'
    click_button 'Search'
    page.all('td').map{|s| s.text}.must_equal []

    click_link 'Artist'
    page.all('td').map{|s| s.text}.must_equal ["TestArtistUpdate", "Show", "Edit", "Delete"]

    page.all('td').last.find('a').click
    click_button 'Delete'
    page.html.must_include 'Deleted Artist'
    page.current_path.must_equal '/prefix/Artist/delete'

    click_link 'Artist'
    page.all('td').map{|s| s.text}.must_equal []
  end

  it "should have basic functionality working with namespaced models" do
    begin
      def Artist.name; "Object::Artist"; end
      app_setup(Artist)
      visit("/Object::Artist/new")
      page.title.must_equal 'Object::Artist - New'
      fill_in 'Name', :with=>'TestArtistNew'
      click_button 'Create'
      page.html.must_include 'Created Object::Artist'
      page.current_path.must_equal '/Object::Artist/new'

      click_link 'Show'
      page.title.must_equal 'Object::Artist - Show'
      click_button 'Show'
      select 'TestArtistNew'
      click_button 'Show'
      page.html.must_match(/Name.+TestArtistNew/m)

      click_link 'Edit'
      page.title.must_equal 'Object::Artist - Edit'
      click_button 'Edit'
      select 'TestArtistNew'
      click_button 'Edit'
      fill_in 'Name', :with=>'TestArtistUpdate'
      click_button 'Update'
      page.html.must_include 'Updated Object::Artist'
      page.html.must_match(/Name.+TestArtistUpdate/m)
      page.current_path.must_match %r{/Object::Artist/edit/\d+}

      click_link 'Search'
      page.title.must_equal 'Object::Artist - Search'
      fill_in 'Name', :with=>'Upd'
      click_button 'Search'
      page.all('table').first['id'].must_equal 'autoforme_table'
      page.all('th').map{|s| s.text}.must_equal ['Name', 'Show', 'Edit', 'Delete']
      page.all('td').map{|s| s.text}.must_equal ["TestArtistUpdate", "Show", "Edit", "Delete"]
      click_link 'CSV Format'
      page.body.must_equal "Name\nTestArtistUpdate\n"

      visit("/Object::Artist/browse")
      click_link 'Search'
      fill_in 'Name', :with=>'Foo'
      click_button 'Search'
      page.all('td').map{|s| s.text}.must_equal []

      click_link 'Object::Artist'
      page.title.must_equal 'Object::Artist - Browse'
      page.all('td').map{|s| s.text}.must_equal ["TestArtistUpdate", "Show", "Edit", "Delete"]
      click_link 'CSV Format'
      page.body.must_equal "Name\nTestArtistUpdate\n"

      visit("/Object::Artist/browse")
      page.all('td').last.find('a').click
      click_button 'Delete'
      page.title.must_equal 'Object::Artist - Delete'
      page.html.must_include 'Deleted Object::Artist'
      page.current_path.must_equal '/Object::Artist/delete'

      click_link 'Object::Artist'
      page.all('td').map{|s| s.text}.must_equal []
    ensure
      class << Artist
        remove_method :name
      end
    end
  end

  it "should have delete button on edit page" do
    app_setup(Artist)
    visit("/Artist/new")
    fill_in 'Name', :with=>'TestArtistNew'
    click_button 'Create'

    click_link 'Edit'
    select 'TestArtistNew'
    click_button 'Edit'
    click_button 'Delete'
    Artist.count.must_equal 1
    click_button 'Delete'
    Artist.count.must_equal 0
  end

  it "should support custom headers and footers" do
    app_setup(Artist) do
      page_header "<a href='/Artist/new'>N</a>"
      page_footer "<a href='/Artist/edit'>E</a>"
    end
    visit("/Artist/browse")
    page.html.wont_include 'search'
    click_link 'N'
    fill_in 'Name', :with=>'TestArtistNew'
    click_button 'Create'
    click_link 'E'
    select 'TestArtistNew'
    click_button 'Edit'
  end

  it "should support showing models with custom ids" do
    db_setup(:tracks => proc do
      column :id, String, :primary_key => true
      column :name, String
    end)

    model_setup(:Track => [:tracks])
    Track.unrestrict_primary_key
    app_setup(Track)

    Track.create(:id => 'dark-side', :name => 'The Dark Side of the Moon')

    visit("/Track/show/dark-side")

    page.html.must_include 'The Dark Side of the Moon'
  end

  it "should support custom redirects" do
    app_setup(Artist) do
      redirect do |obj, type, req|
        case type
        when :new
          "/Artist/edit/#{obj.id}"
        when :edit
          "/Artist/show/#{obj.id}"
        when :delete
          "/Artist/new"
        end
      end
    end
    visit("/Artist/new")
    fill_in 'Name', :with=>'TestArtistNew'
    click_button 'Create'
    page.current_path.must_match %r{/Artist/edit/\d}
    click_button 'Update'
    page.current_path.must_match %r{/Artist/show/\d}
    click_link 'Delete'
    click_button 'Delete'
    select 'TestArtistNew'
    click_button 'Delete'
    click_button 'Delete'
    page.current_path.must_equal "/Artist/new"
  end

  it "should support custom form options and attributes" do
    app_setup(Artist) do
      form_attributes :class=>'foobar', :action=>'/create_artist'
      form_options :input_defaults=>{'text'=>{:class=>'barfoo'}}
    end
    visit("/Artist/new")
    find('form')[:class].must_equal 'foobar forme artist'
    find('form')[:action].must_equal '/create_artist'
    find('form input#artist_name')[:class].must_equal 'barfoo'
  end

  it "should support support specifying column options per type" do
    app_setup(Artist) do
      column_options{|column, type, req| {:label=>"#{type.to_s.capitalize} Artist #{column.to_s.capitalize}"}}
    end

    visit("/Artist/new")
    fill_in 'New Artist Name', :with=>'TestArtistNew'
    click_button 'Create'
    page.current_path.must_equal '/Artist/new'

    click_link 'Show'
    select 'TestArtistNew'
    click_button 'Show'
    page.html.must_match(/Show Artist Name.+TestArtistNew/m)
    click_button 'Edit'
    fill_in 'Edit Artist Name', :with=>'TestArtistUpdate'
    click_button 'Update'
    page.html.must_match(/Edit Artist Name.+TestArtistUpdate/m)
    page.current_path.must_match %r{/Artist/edit/\d+}

    click_link 'Search'
    fill_in 'Search_form Artist Name', :with=>'Upd'
    click_button 'Search'
    page.all('th').map{|s| s.text}.must_equal ["Search Artist Name", "Show", "Edit", "Delete"]

    click_link 'Artist'
    page.all('th').map{|s| s.text}.must_equal ["Browse Artist Name", "Show", "Edit", "Delete"]
  end

  it "should support specifying display names per type" do
    app_setup(Artist) do
      display_name do |obj, type|
        case type
        when :edit
          obj.name[1..-1]
        when :show
          obj.name[2..-2]
        when :delete
          obj.send(:class)
        end
      end
    end
    Artist.create(:name=>'TestArtistNew')
    visit("/Artist/show")
    select 'stArtistN'
    click_button 'Show'
    page.html.must_match(/Name.+TestArtistNew/m)

    click_link 'Edit'
    select 'estArtistNe'
    click_button 'Edit'
    page.html.must_match(/Name.+TestArtistNew/m)

    click_link 'Delete'
    select 'Artist'
    click_button 'Delete'
    click_button 'Delete'
    Artist.count.must_equal 0
  end

  it "should support create, update, delete hooks" do
    a = []
    app_setup do
      before_action{|type, req| a << type}
      before_create{|obj, req| a << -1}
      before_update{|obj, req| a << -2}
      before_destroy{|obj, req| a << -3}
      before_new{|obj, req| obj.name = 'weNtsitrAtseT'.dup}
      before_edit{|obj, req| obj.name << '2'}
      after_create{|obj, req| a << 1 }
      after_update{|obj, req| a << 2 }
      after_destroy{|obj, req| a << 3 }
      model Artist do
        before_action{|type, req| req.redirect('/Artist/browse') if type == :show}
        before_create{|obj, req| obj.name = obj.name.reverse}
        before_update{|obj, req| obj.name = obj.name.upcase}
        before_destroy{|obj, req| raise if obj.name == obj.name.reverse}
        before_new{|obj, req| obj.name.reverse!}
        before_edit{|obj, req| obj.name << '1'}
        after_create{|obj, req| a << req.action_type }
        after_update{|obj, req| a << req.action_type }
        after_destroy{|obj, req| a << req.action_type }
      end
    end
    visit("/Artist/new")
    click_button 'Create'
    a.must_equal [:new, :create, -1, 'create', 1, :new]
    a.clear

    click_link 'Edit'
    select 'weNtsitrAtseT'
    click_button 'Edit'
    page.html.must_include 'weNtsitrAtseT21'
    click_button 'Update'
    a.must_equal [:edit, :edit, :update, -2, 'update', 2, :edit]
    a.clear

    click_link 'Show'
    page.current_path.must_equal '/Artist/browse'
    a.must_equal [:show, :browse]
    a.clear

    click_link 'Delete', :match=>:first
    Artist.create(:name=>'A')
    select 'WENTSITRATSET21'
    click_button 'Delete'
    click_button 'Delete'
    a.must_equal [:delete, :delete, :destroy, -3, 'destroy', 3, :delete]
    a.clear

    select 'A'
    click_button 'Delete'
    proc{click_button 'Delete'}.must_raise RuntimeError
    a.must_equal [:delete, :destroy, -3]
  end

  it "should support specifying table class for data tables per type" do
    app_setup(Artist) do
      table_class{|type, req| type == :browse ? 'foo' : 'bar'}
    end
    visit("/Artist/browse")
    first('table')['class'].must_equal 'foo'
    click_link 'Search'
    click_button 'Search'
    first('table')['class'].must_equal 'bar'
  end

  it "should support specifying numbers of rows per page per type" do
    app_setup(Artist) do
      per_page{|type, req| type == :browse ? 2 : 3}
    end
    5.times{|i| Artist.create(:name=>i.to_s)}
    visit("/Artist/browse")
    pager_class = lambda do |text|
      node = all('ul.pager li').select{|n| n[:class] if n.find('a').text == text}.first
      node[:class] if node
    end
    pager_class.call("Previous").must_equal 'disabled'
    page.all('tr td:first-child').map{|s| s.text}.must_equal %w'0 1'
    click_link 'Next'
    page.all('tr td:first-child').map{|s| s.text}.must_equal %w'2 3'
    click_link 'Next'
    page.all('tr td:first-child').map{|s| s.text}.must_equal %w'4'
    pager_class.call("Next").must_equal 'disabled'
    click_link 'Previous'
    page.all('tr td:first-child').map{|s| s.text}.must_equal %w'2 3'
    click_link 'Previous'
    page.all('tr td:first-child').map{|s| s.text}.must_equal %w'0 1'
    pager_class.call("Previous").must_equal 'disabled'

    click_link 'Search'
    click_button 'Search'
    page.all('tr td:first-child').map{|s| s.text}.must_equal %w'0 1 2'
    click_link 'Next'
    page.all('tr td:first-child').map{|s| s.text}.must_equal %w'3 4'
    pager_class.call("Next").must_equal 'disabled'
    click_link 'Previous'
    page.all('tr td:first-child').map{|s| s.text}.must_equal %w'0 1 2'
    pager_class.call("Previous").must_equal 'disabled'
  end

  it "should support specifying supported actions" do
    app_setup(Artist) do
      supported_actions [:new, :edit, :browse, :search]
    end
    visit("/Artist/new")
    fill_in 'Name', :with=>'TestArtistNew'
    click_button 'Create'
    page.current_path.must_equal '/Artist/new'
    page.html.wont_include 'Show'
    page.html.wont_include 'Delete'

    click_link 'Edit'
    select 'TestArtistNew'
    click_button 'Edit'
    fill_in 'Name', :with=>'TestArtistUpdate'
    click_button 'Update'
    page.html.must_match(/Name.+TestArtistUpdate/m)
    page.current_path.must_match %r{/Artist/edit/\d+}

    click_link 'Search'
    fill_in 'Name', :with=>'Upd'
    click_button 'Search'
    page.all('td').map{|s| s.text}.must_equal ["TestArtistUpdate", "Edit"]

    click_link 'Artist'
    page.all('td').map{|s| s.text}.must_equal ["TestArtistUpdate", "Edit"]
  end

  it "should have working link_name and class_display_name" do
    app_setup(Artist) do
      class_display_name "FooArtist"
      link_name "BarArtist"
    end
    visit("/BarArtist/new")
    fill_in 'Name', :with=>'TestArtistNew'
    click_button 'Create'
    page.html.must_include 'Created FooArtist'
    page.current_path.must_equal '/BarArtist/new'

    click_link 'Edit'
    select 'TestArtistNew'
    click_button 'Edit'
    fill_in 'Name', :with=>'TestArtistUpdate'
    click_button 'Update'
    page.html.must_include 'Updated FooArtist'

    click_link 'FooArtist'
    page.all('td').map{|s| s.text}.must_equal ["TestArtistUpdate", "Show", "Edit", "Delete"]

    page.all('td').last.find('a').click
    click_button 'Delete'
    page.html.must_include 'Deleted FooArtist'
  end

  it "should use text boxes on list page when autocompleting is enabled" do
    app_setup(Artist) do
      autocomplete_options({})
    end
    a = Artist.create(:name=>'TestArtistNew')

    visit('/Artist/show')
    fill_in 'Artist', :with=>a.id.to_s
    click_button 'Show'
    page.html.must_match(/Name.+TestArtistNew/m)

    click_link 'Edit'
    fill_in 'Artist', :with=>a.id.to_s
    click_button 'Edit'
    click_button 'Update'

    click_link 'Delete'
    fill_in 'Artist', :with=>a.id.to_s
    click_button 'Delete'
    click_button 'Delete'
    Artist.count.must_equal 0
  end

  it "should support show_html and edit_html" do
    app_setup(Artist) do
      show_html do |obj, c, t, req|
        "#{c}#{t}-#{obj.send(c).to_s*2}"
      end
      edit_html do |obj, c, t, req|
        "<label for='artist_#{c}'>#{c}#{t}</label><input type='text' id='artist_#{c}' name='#{t == :search_form ? c : "artist[#{c}]"}' value='#{obj.send(c).to_s*2}'/>"
      end
    end
    visit("/Artist/new")
    page.title.must_equal 'Artist - New'
    fill_in 'namenew', :with=>'TAN'
    click_button 'Create'
    page.html.must_include 'Created Artist'
    page.current_path.must_equal '/Artist/new'

    click_link 'Show'
    page.title.must_equal 'Artist - Show'
    select 'TAN'
    click_button 'Show'
    page.html.must_include 'nameshow-TANTAN'

    click_link 'Edit'
    page.title.must_equal 'Artist - Edit'
    select 'TAN'
    click_button 'Edit'
    fill_in 'nameedit', :with=>'TAU'
    click_button 'Update'
    page.html.must_include 'Updated Artist'
    page.html.must_match(/nameedit.+TAUTAU/m)
    page.current_path.must_match %r{/Artist/edit/\d+}

    click_link 'Search'
    page.title.must_equal 'Artist - Search'
    fill_in 'namesearch_form', :with=>'AU'
    click_button 'Search'
    page.all('table').first['id'].must_equal 'autoforme_table'
    page.all('th').map{|s| s.text}.must_equal ['Name', 'Show', 'Edit', 'Delete']
    page.all('td').map{|s| s.text}.must_equal ["namesearch-TAUTAU", "Show", "Edit", "Delete"]
    click_link 'CSV Format'
    page.body.must_equal "Name\nTAU\n"

    visit("/Artist/browse")
    click_link 'Search'
    fill_in 'namesearch_form', :with=>'TAUTAU'
    click_button 'Search'
    page.all('td').map{|s| s.text}.must_equal []

    click_link 'Artist'
    page.title.must_equal 'Artist - Browse'
    page.all('td').map{|s| s.text}.must_equal ["namebrowse-TAUTAU", "Show", "Edit", "Delete"]
    click_link 'CSV Format'
    page.body.must_equal "Name\nTAU\n"

    visit("/Artist/browse")
    page.all('td').last.find('a').click
    page.html.must_include 'namedelete-TAUTAU'
    click_button 'Delete'
    page.title.must_equal 'Artist - Delete'
    page.html.must_include 'Deleted Artist'
    page.current_path.must_equal '/Artist/delete'

    click_link 'Artist'
    page.all('td').map{|s| s.text}.must_equal []
  end

  it "should correctly handle validation errors" do
    app_setup(Artist)
    Artist.send(:define_method, :validate) do
      errors.add(:name, "bad name") if name == 'Foo'
    end

    visit("/Artist/new")
    page.title.must_equal 'Artist - New'
    fill_in 'Name', :with=>'Foo'
    click_button 'Create'
    page.title.must_equal 'Artist - New'
    page.html.must_include 'Error Creating Artist'
    page.html.must_include 'bad name'
    fill_in 'Name', :with=>'TestArtistNew'
    click_button 'Create'
    page.html.must_include 'Created Artist'
    page.current_path.must_equal '/Artist/new'

    click_link 'Edit'
    page.title.must_equal 'Artist - Edit'
    click_button 'Edit'
    select 'TestArtistNew'
    click_button 'Edit'
    fill_in 'Name', :with=>'Foo'
    click_button 'Update'
    page.title.must_equal 'Artist - Edit'
    page.html.must_include 'Error Updating Artist'
    page.html.must_include 'bad name'
    fill_in 'Name', :with=>'TestArtistUpdate'
    click_button 'Update'
    page.html.must_include 'Updated Artist'
    page.html.must_match(/Name.+TestArtistUpdate/m)
    page.current_path.must_match %r{/Artist/edit/\d+}
  end

  it "should support view_options" do
    app_setup(Artist, view_options: {:layout=>false}){}
    visit("/Artist/browse")
    page.html.wont_include '<!DOCTYPE html>'
    page.all('table').first['id'].must_equal 'autoforme_table'
  end
end

describe AutoForme do
  before(:all) do
    db_setup(:artists=>[[:name, :string], [:active, :boolean]])
    model_setup(:Artist=>[:artists])
  end
  after(:all) do
    Object.send(:remove_const, :Artist)
  end

  it "should typecast when searching" do
    app_setup(Artist)
    Artist.plugin(:typecast_on_load, :active) if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
    visit("/Artist/new")
    page.title.must_equal 'Artist - New'
    select 'True'
    fill_in 'Name', :with=>'TestArtistNew'
    click_button 'Create'
    page.html.must_include 'Created Artist'
    page.current_path.must_equal '/Artist/new'

    click_link 'Show'
    page.title.must_equal 'Artist - Show'
    click_button 'Show'
    select 'TestArtistNew'
    click_button 'Show'
    page.html.must_match(/Active.+True.+Name.+TestArtistNew/m)

    click_link 'Edit'
    page.title.must_equal 'Artist - Edit'
    click_button 'Edit'
    select 'TestArtistNew'
    click_button 'Edit'
    select 'False'
    fill_in 'Name', :with=>'TestArtistUpdate'
    click_button 'Update'
    page.html.must_include 'Updated Artist'
    page.html.must_match(/Active.+False.+Name.+TestArtistUpdate/m)
    page.current_path.must_match %r{/Artist/edit/\d+}

    click_link 'Search'
    page.title.must_equal 'Artist - Search'
    fill_in 'Name', :with=>'Upd'
    select 'False'
    click_button 'Search'
    page.all('table').first['id'].must_equal 'autoforme_table'
    page.all('th').map{|s| s.text}.must_equal ['Active', 'Name', 'Show', 'Edit', 'Delete']
    page.all('td').map{|s| s.text}.must_equal ['false', "TestArtistUpdate", "Show", "Edit", "Delete"]
    click_link 'CSV Format'
    page.body.must_equal "Active,Name\nfalse,TestArtistUpdate\n"

    visit("/Artist/browse")
    click_link 'Search'
    fill_in 'Name', :with=>'Foo'
    click_button 'Search'
    page.all('td').map{|s| s.text}.must_equal []

    visit("/Artist/browse")
    click_link 'Search'
    select 'True'
    click_button 'Search'
    page.all('td').map{|s| s.text}.must_equal []

    click_link 'Artist'
    page.title.must_equal 'Artist - Browse'
    page.all('td').map{|s| s.text}.must_equal ["false", "TestArtistUpdate", "Show", "Edit", "Delete"]
    click_link 'CSV Format'
    page.body.must_equal "Active,Name\nfalse,TestArtistUpdate\n"

    visit("/Artist/browse")
    page.all('td').last.find('a').click
    click_button 'Delete'
    page.title.must_equal 'Artist - Delete'
    page.html.must_include 'Deleted Artist'
    page.current_path.must_equal '/Artist/delete'

    click_link 'Artist'
    page.all('td').map{|s| s.text}.must_equal []
  end
end

describe AutoForme do
  before(:all) do
    db_setup(:artists=>(0..5).map{|i|[:"n#{i}", :string]})
    model_setup(:Artist=>[:artists])
    class Artist
      def forme_name
        n0
      end
    end
  end
  after(:all) do
    Object.send(:remove_const, :Artist)
  end

  it "should support specifying columns per type" do
    cols = Artist.columns - [:id]
    map = {:new=>:n5, :edit=>:n4, :show=>:n3, :browse=>:n2, :search_form=>:n1, :search=>:n0}
    app_setup(Artist) do
      columns{|type, req| cols - [map[type]]}
    end

    visit("/Artist/new")
    fill_in 'N0', :with=>'V0'
    fill_in 'N1', :with=>'V1'
    fill_in 'N2', :with=>'V2'
    fill_in 'N3', :with=>'V3'
    fill_in 'N4', :with=>'V4'
    page.body.wont_match(/<label>N5/i)
    click_button 'Create'

    click_link 'Show'
    select 'V0'
    click_button 'Show'
    page.body.must_match(/[VN]0/i)
    page.body.must_match(/[VN]1/i)
    page.body.must_match(/[VN]2/i)
    page.body.wont_match(/[VN]3/i)
    page.body.must_match(/[VN]4/i)
    page.body.must_match(/N5/i)

    click_link 'Edit'
    select 'V0'
    click_button 'Edit'
    fill_in 'N0', :with=>'Q0'
    fill_in 'N1', :with=>'Q1'
    fill_in 'N2', :with=>'Q2'
    fill_in 'N3', :with=>'Q3'
    page.body.wont_match(/<label>N4/i)
    fill_in 'N5', :with=>'Q5'
    click_button 'Update'

    click_link 'Search'
    fill_in 'N0', :with=>'Q0'
    page.body.wont_match(/<label>N1/i)
    fill_in 'N2', :with=>'Q2'
    fill_in 'N3', :with=>'Q3'
    fill_in 'N4', :with=>'V4'
    fill_in 'N5', :with=>'Q5'
    click_button 'Search'
    page.all('td').map{|s| s.text}.must_equal ["Q1", "Q2", "Q3", "V4", "Q5", "Show", "Edit", "Delete"]
    click_link 'CSV Format'
    page.body.must_equal "N1,N2,N3,N4,N5\nQ1,Q2,Q3,V4,Q5\n"

    visit '/Artist/browse'
    page.all('td').map{|s| s.text}.must_equal ["Q0", "Q1", "Q3", "V4", "Q5", "Show", "Edit", "Delete"]
    click_link 'CSV Format'
    page.body.must_equal "N0,N1,N3,N4,N5\nQ0,Q1,Q3,V4,Q5\n"
  end

  it "should support specifying order per type" do
    map = {:edit=>:n0, :show=>[:n1, :n2], :delete=>:n3, :browse=>[:n1, :n0], :search=>:n4}
    app_setup(Artist) do
      order{|type, req| map[type]}
    end

    Artist.create(:n0=>'1', :n1=>'2', :n2=>'3', :n3=>'7', :n4=>'5')
    Artist.create(:n0=>'2', :n1=>'2', :n2=>'1', :n3=>'3', :n4=>'4')
    Artist.create(:n0=>'0', :n1=>'4', :n2=>'1', :n3=>'5', :n4=>'3')

    visit("/Artist/show")
    page.all('option').map{|s| s.text}.must_equal ['', '2', '1', '0']

    click_link 'Edit'
    page.all('option').map{|s| s.text}.must_equal ['', '0', '1', '2']

    click_link 'Delete'
    page.all('option').map{|s| s.text}.must_equal ['', '2', '0', '1']

    click_link 'Search'
    click_button 'Search'
    page.all('tr td:first-child').map{|s| s.text}.must_equal ['0', '2', '1']

    click_link 'Artist'
    page.all('tr td:first-child').map{|s| s.text}.must_equal ['1', '2', '0']
  end

  it "should support specifying filter per type" do
    app_setup(Artist) do
      filter do |ds, type, req|
        case type
        when :edit
          ds.where{n0 > 1}
        when :show
          ds.where{n1 > 3}
        when :delete
          ds.where{n2 > 2}
        when :browse
          ds.where{n3 > 6}
        when :search
          ds.where{n4 > 4}
        end
      end
    end

    Artist.create(:n0=>'1', :n1=>'2', :n2=>'3', :n3=>'7', :n4=>'5')
    Artist.create(:n0=>'2', :n1=>'2', :n2=>'1', :n3=>'3', :n4=>'4')
    Artist.create(:n0=>'0', :n1=>'4', :n2=>'1', :n3=>'5', :n4=>'3')

    visit("/Artist/show")
    page.all('option').map{|s| s.text}.must_equal ['', '0']

    click_link 'Edit'
    page.all('option').map{|s| s.text}.must_equal ['', '2']
    select '2'
    click_button 'Edit'
    click_button 'Update'

    click_link 'Delete'
    page.all('option').map{|s| s.text}.must_equal ['', '1']
    select '1'
    click_button 'Delete'
    click_button 'Delete'
    Artist.create(:n0=>'1', :n1=>'2', :n2=>'3', :n3=>'7', :n4=>'5')

    click_link 'Search'
    click_button 'Search'
    page.all('tr td:first-child').map{|s| s.text}.must_equal %w'1'

    click_link 'Artist'
    page.all('tr td:first-child').map{|s| s.text}.must_equal %w'1'
  end

  it "should support specifying filter per type using request params" do
    app_setup(Artist) do
      filter do |ds, type, req|
        v = req.params['f']
        case type
        when :edit
          ds.where{n0 > v}
        when :show
          ds.where{n1 > v}
        when :delete
          ds.where{n2 > v}
        when :browse
          ds.where{n3 > v}
        when :search
          ds.where{n4 > v}
        end
      end
    end

    Artist.create(:n0=>'1', :n1=>'2', :n2=>'3', :n3=>'7', :n4=>'5')
    Artist.create(:n0=>'2', :n1=>'2', :n2=>'1', :n3=>'3', :n4=>'4')
    Artist.create(:n0=>'0', :n1=>'4', :n2=>'1', :n3=>'5', :n4=>'3')

    visit("/Artist/show?f=3")
    page.all('option').map{|s| s.text}.must_equal ['', '0']

    visit("/Artist/edit?f=1")
    page.all('option').map{|s| s.text}.must_equal ['', '2']

    visit("/Artist/delete?f=2")
    page.all('option').map{|s| s.text}.must_equal ['', '1']

    visit("/Artist/search/1?f=4")
    page.all('tr td:first-child').map{|s| s.text}.must_equal %w'1'

    visit("/Artist/browse?f=6")
    page.all('tr td:first-child').map{|s| s.text}.must_equal %w'1'
  end

  it "should support specifying filter per type using request session" do
    app_setup(Artist) do
      filter{|ds, type, req| ds.where(:n1=>req.session['n1'])}
      order :n2
    end

    Artist.create(:n0=>'1', :n1=>'2', :n2=>'3', :n3=>'7', :n4=>'5')
    Artist.create(:n0=>'2', :n1=>'2', :n2=>'1', :n3=>'3', :n4=>'4')
    Artist.create(:n0=>'0', :n1=>'4', :n2=>'1', :n3=>'5', :n4=>'3')
    visit '/session/set?n1=2'

    visit("/Artist/show")
    page.all('option').map{|s| s.text}.must_equal ['', '2', '1']

    click_link 'Edit'
    page.all('option').map{|s| s.text}.must_equal ['', '2', '1']
    select '2'
    click_button 'Edit'
    click_button 'Update'

    click_link 'Delete'
    page.all('option').map{|s| s.text}.must_equal ['', '2', '1']
    select '1'
    click_button 'Delete'
    click_button 'Delete'
    Artist.create(:n0=>'1', :n1=>'2', :n2=>'3', :n3=>'7', :n4=>'5')

    click_link 'Search'
    click_button 'Search'
    page.all('tr td:first-child').map{|s| s.text}.must_equal %w'2 1'

    click_link 'Artist'
    page.all('tr td:first-child').map{|s| s.text}.must_equal %w'2 1'
  end

  it "should support session_value for restricting access by matching session variable to column value" do
    app_setup(Artist) do
      session_value :n1
      columns [:n0, :n2]
      order :n2
    end

    Artist.create(:n0=>'0', :n1=>'4', :n2=>'1')
    visit '/session/set?n1=2'

    visit("/Artist/new")
    fill_in 'N0', :with=>'1'
    fill_in 'N2', :with=>'3'
    click_button 'Create'
    fill_in 'N0', :with=>'2'
    fill_in 'N2', :with=>'1'
    click_button 'Create'

    click_link 'Show'
    page.all('option').map{|s| s.text}.must_equal ['', '2', '1']

    click_link 'Edit'
    page.all('option').map{|s| s.text}.must_equal ['', '2', '1']
    select '2'
    click_button 'Edit'
    click_button 'Update'

    click_link 'Search'
    click_button 'Search'
    page.all('tr td:first-child').map{|s| s.text}.must_equal %w'2 1'

    click_link 'Artist'
    page.all('tr td:first-child').map{|s| s.text}.must_equal %w'2 1'

    click_link 'Delete', :match=>:first
    page.all('option').map{|s| s.text}.must_equal ['', '2', '1']
    select '1'
    click_button 'Delete'
  end
end

describe AutoForme do
  before(:all) do
    db_setup(:artists=>[[:num, :decimal]])
    model_setup(:Artist=>[:artists])
  end
  after(:all) do
    Object.send(:remove_const, :Artist)
  end
  before do
    app_setup(Artist)
    visit("/Artist/new")
    page.title.must_equal 'Artist - New'
    fill_in 'Num', :with=>'1.01'
    click_button 'Create'
    visit("/Artist/browse")
  end

  it "should display decimals in float format in tables" do
    click_link 'Artist'
    page.all('tr td:first-child').map{|s| s.text}.must_equal %w'1.01'
    click_link 'Search'
    click_button 'Search'
    page.all('tr td:first-child').map{|s| s.text}.must_equal %w'1.01'
  end

  it "should treat invalid search fields as returning no results" do
    click_link 'Search'
    fill_in 'Num', :with=>'3/3/2020'
    click_button 'Search'
    page.all('tr td:first-child').map{|s| s.text}.must_equal []
  end
end

describe AutoForme do
  before(:all) do
    db_setup(:artists=>[[:name, :string]])
    model_setup(:Artist=>[:artists])
  end
  after(:all) do
    Object.send(:remove_const, :Artist)
  end

  it "should have basic functionality working when reloading code" do
    app_setup do
      register_by_name
      model Artist
    end
    artist_class = Artist
    Object.send(:remove_const, :Artist)
    ::Artist = Class.new(artist_class) do
      def name
        "-#{super}-"
      end
      def forme_name
        "[#{name}]"
      end
    end
    visit("/Artist/new")
    page.title.must_equal 'Artist - New'
    fill_in 'Name', :with=>'TestArtistNew'
    click_button 'Create'
    page.html.must_include 'Created Artist'
    page.current_path.must_equal '/Artist/new'

    click_link 'Show'
    page.title.must_equal 'Artist - Show'
    select '[-TestArtistNew-]'
    click_button 'Show'
    page.html.must_match(/Name.+-TestArtistNew-/m)

    click_link 'Edit'
    page.title.must_equal 'Artist - Edit'
    select '[-TestArtistNew-]'
    click_button 'Edit'
    fill_in 'Name', :with=>'TestArtistUpdate'
    click_button 'Update'
    page.html.must_include 'Updated Artist'
    page.html.must_match(/Name.+-TestArtistUpdate-/m)
    page.current_path.must_match %r{/Artist/edit/\d+}

    click_link 'Search'
    page.title.must_equal 'Artist - Search'
    fill_in 'Name', :with=>'Upd'
    click_button 'Search'
    page.all('th').map{|s| s.text}.must_equal ['Name', 'Show', 'Edit', 'Delete']
    page.all('td').map{|s| s.text}.must_equal ["-TestArtistUpdate-", "Show", "Edit", "Delete"]

    click_link 'Search'
    fill_in 'Name', :with=>'Foo'
    click_button 'Search'
    page.all('td').map{|s| s.text}.must_equal []

    click_link 'Artist'
    page.title.must_equal 'Artist - Browse'
    page.all('td').map{|s| s.text}.must_equal ["-TestArtistUpdate-", "Show", "Edit", "Delete"]

    page.all('td').last.find('a').click
    click_button 'Delete'
    page.html.must_include 'Deleted Artist'
    page.current_path.must_equal '/Artist/delete'

    click_link 'Artist'
    page.all('td').map{|s| s.text}.must_equal []
  end
end

describe AutoForme do
  before(:all) do
    db_setup(:artists=>[[:name, :string], [:i, :integer]])
    model_setup(:Artist=>[:artists])
  end
  after(:all) do
    Object.send(:remove_const, :Artist)
  end

  it "should have basic functionality working" do
    app_setup(Artist)
    visit("/Artist/new")
    page.title.must_equal 'Artist - New'
    fill_in 'Name', :with=>'TestArtistNew'
    fill_in 'I', :with=>'3'
    click_button 'Create'

    click_link 'Search'
    fill_in 'I', :with=>'2'
    click_button 'Search'
    page.all('th').map{|s| s.text}.must_equal ['I', 'Name', 'Show', 'Edit', 'Delete']
    page.all('td').map{|s| s.text}.must_equal []

    click_link 'Search'
    fill_in 'I', :with=>'3'
    click_button 'Search'
    page.all('th').map{|s| s.text}.must_equal ['I', 'Name', 'Show', 'Edit', 'Delete']
    page.all('td').map{|s| s.text}.must_equal ["3", "TestArtistNew", "Show", "Edit", "Delete"]
  end
end

describe AutoForme do
  before(:all) do
    db_setup(:artists=>[])
    model_setup(:Artist=>[:artists])
  end
  after(:all) do
    Object.send(:remove_const, :Artist)
  end

  it "should have basic functionality working with no columns" do
    app_setup(Artist)
    visit("/Artist/new")
    page.title.must_equal 'Artist - New'
    click_button 'Create'
    page.html.must_include 'Created Artist'
    page.current_path.must_equal '/Artist/new'
    id = Artist.first.id.to_s

    click_link 'Show'
    page.title.must_equal 'Artist - Show'
    click_button 'Show'
    select id
    click_button 'Show'

    click_link 'Edit'
    page.title.must_equal 'Artist - Edit'
    click_button 'Edit'
    select id
    click_button 'Edit'
    click_button 'Update'
    page.html.must_include 'Updated Artist'
    page.current_path.must_equal "/Artist/edit/#{id}"

    click_link 'Artist'
    page.title.must_equal 'Artist - Browse'
    page.all('td').map{|s| s.text}.must_equal ["Show", "Edit", "Delete"]
    click_link 'CSV Format'
    page.body.must_equal "\n\n"

    visit("/Artist/browse")
    page.all('td').last.find('a').click
    click_button 'Delete'
    page.title.must_equal 'Artist - Delete'
    page.html.must_include 'Deleted Artist'
    page.current_path.must_equal '/Artist/delete'

    click_link 'Artist'
    page.all('td').map{|s| s.text}.must_equal []
  end
end

describe AutoForme do
  before(:all) do
    db_setup(:artists=>[[:name, :string]])
    Namespace = Module.new

    class Namespace::Artist < Sequel::Model(db[:artists])
      def forme_namespace
        "artist"
      end
    end
  end
  after(:all) do
    Object.send(:remove_const, :Namespace)
  end

  it "respects the forme_namespace method on the model" do
    app_setup(Namespace::Artist)
    visit("/Namespace::Artist/new")
    fill_in 'Name', :with=>'TestArtistNew'
    click_button 'Create'
    page.html.must_include 'Created Namespace::Artist'
    page.current_path.must_equal '/Namespace::Artist/new'
  end
end
