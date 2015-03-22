require './spec/spec_helper'

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
    page.title.should == 'Artist - New'
    fill_in 'Name', :with=>'TestArtistNew'
    click_button 'Create'
    page.html.should =~ /Created Artist/
    page.current_path.should == '/Artist/new'

    click_link 'Show'
    page.title.should == 'Artist - Show'
    select 'TestArtistNew'
    click_button 'Show'
    page.html.should =~ /Name.+TestArtistNew/m

    click_link 'Edit'
    page.title.should == 'Artist - Edit'
    select 'TestArtistNew'
    click_button 'Edit'
    fill_in 'Name', :with=>'TestArtistUpdate'
    click_button 'Update'
    page.html.should =~ /Updated Artist/
    page.html.should =~ /Name.+TestArtistUpdate/m
    page.current_path.should =~ %r{/Artist/edit/\d+}

    click_link 'Search'
    page.title.should == 'Artist - Search'
    fill_in 'Name', :with=>'Upd'
    click_button 'Search'
    page.all('th').map{|s| s.text}.should == ['Name', 'Show', 'Edit', 'Delete']
    page.all('td').map{|s| s.text}.should == ["TestArtistUpdate", "Show", "Edit", "Delete"]

    click_link 'Search'
    fill_in 'Name', :with=>'Foo'
    click_button 'Search'
    page.all('td').map{|s| s.text}.should == []

    click_link 'Artist'
    page.title.should == 'Artist - Browse'
    page.all('td').map{|s| s.text}.should == ["TestArtistUpdate", "Show", "Edit", "Delete"]

    page.all('td').last.find('a').click
    click_button 'Delete'
    page.title.should == 'Artist - Delete'
    page.html.should =~ /Deleted Artist/
    page.current_path.should == '/Artist/delete'

    click_link 'Artist'
    page.all('td').map{|s| s.text}.should == []
  end

  it "should have basic functionality working in a subdirectory" do
    app_setup(Artist, :prefix=>"/prefix")
    visit("/prefix/Artist/new")
    fill_in 'Name', :with=>'TestArtistNew'
    click_button 'Create'
    page.html.should =~ /Created Artist/
    page.current_path.should == '/prefix/Artist/new'

    click_link 'Show'
    select 'TestArtistNew'
    click_button 'Show'
    page.html.should =~ /Name.+TestArtistNew/m

    click_link 'Edit'
    select 'TestArtistNew'
    click_button 'Edit'
    fill_in 'Name', :with=>'TestArtistUpdate'
    click_button 'Update'
    page.html.should =~ /Updated Artist/
    page.html.should =~ /Name.+TestArtistUpdate/m
    page.current_path.should =~ %r{/prefix/Artist/edit/\d+}

    click_link 'Search'
    fill_in 'Name', :with=>'Upd'
    click_button 'Search'
    page.all('th').map{|s| s.text}.should == ['Name', 'Show', 'Edit', 'Delete']
    page.all('td').map{|s| s.text}.should == ["TestArtistUpdate", "Show", "Edit", "Delete"]

    click_link 'Search'
    fill_in 'Name', :with=>'Foo'
    click_button 'Search'
    page.all('td').map{|s| s.text}.should == []

    click_link 'Artist'
    page.all('td').map{|s| s.text}.should == ["TestArtistUpdate", "Show", "Edit", "Delete"]

    page.all('td').last.find('a').click
    click_button 'Delete'
    page.html.should =~ /Deleted Artist/
    page.current_path.should == '/prefix/Artist/delete'

    click_link 'Artist'
    page.all('td').map{|s| s.text}.should == []
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
    Artist.count.should == 1
    click_button 'Delete'
    Artist.count.should == 0
  end

  it "should support custom headers and footers" do
    app_setup(Artist) do
      page_header "<a href='/Artist/new'>N</a>"
      page_footer "<a href='/Artist/edit'>E</a>"
    end
    visit("/Artist/browse")
    page.html.should_not =~ /search/
    click_link 'N'
    fill_in 'Name', :with=>'TestArtistNew'
    click_button 'Create'
    click_link 'E'
    select 'TestArtistNew'
    click_button 'Edit'
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
    page.current_path.should =~ %r{/Artist/edit/\d}
    click_button 'Update'
    page.current_path.should =~ %r{/Artist/show/\d}
    click_link 'Delete'
    select 'TestArtistNew'
    click_button 'Delete'
    click_button 'Delete'
    page.current_path.should == "/Artist/new"
  end

  it "should support custom form options and attributes" do
    app_setup(Artist) do
      form_attributes :class=>'foobar', :action=>'/create_artist'
      form_options :input_defaults=>{'text'=>{:class=>'barfoo'}}
    end
    visit("/Artist/new")
    find('form')[:class].should == 'foobar forme artist'
    find('form')[:action].should == '/create_artist'
    find('form input#artist_name')[:class].should == 'barfoo'
  end

  it "should support support specifying column options per type" do
    app_setup(Artist) do
      column_options{|column, type, req| {:label=>"#{type.to_s.capitalize} Artist #{column.to_s.capitalize}"}}
    end

    visit("/Artist/new")
    fill_in 'New Artist Name', :with=>'TestArtistNew'
    click_button 'Create'
    page.current_path.should == '/Artist/new'

    click_link 'Show'
    select 'TestArtistNew'
    click_button 'Show'
    page.html.should =~ /Show Artist Name.+TestArtistNew/m
    click_button 'Edit'
    fill_in 'Edit Artist Name', :with=>'TestArtistUpdate'
    click_button 'Update'
    page.html.should =~ /Edit Artist Name.+TestArtistUpdate/m
    page.current_path.should =~ %r{/Artist/edit/\d+}

    click_link 'Search'
    fill_in 'Search_form Artist Name', :with=>'Upd'
    click_button 'Search'
    page.all('th').map{|s| s.text}.should == ["Search Artist Name", "Show", "Edit", "Delete"]

    click_link 'Artist'
    page.all('th').map{|s| s.text}.should == ["Browse Artist Name", "Show", "Edit", "Delete"]
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
    page.html.should =~ /Name.+TestArtistNew/m

    click_link 'Edit'
    select 'estArtistNe'
    click_button 'Edit'
    page.html.should =~ /Name.+TestArtistNew/m

    click_link 'Delete'
    select 'Artist'
    click_button 'Delete'
    click_button 'Delete'
    Artist.count.should == 0
  end

  it "should support create, update, delete hooks" do
    a = []
    app_setup do
      before_action{|type, req| a << type}
      before_create{|obj, req| a << -1}
      before_update{|obj, req| a << -2}
      before_destroy{|obj, req| a << -3}
      before_new{|obj, req| obj.name = 'weNtsitrAtseT'}
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
    a.should == [:new, :create, -1, 'create', 1, :new]
    a.clear

    click_link 'Edit'
    select 'weNtsitrAtseT'
    click_button 'Edit'
    page.html.should =~ /weNtsitrAtseT21/
    click_button 'Update'
    a.should == [:edit, :edit, :update, -2, 'update', 2, :edit]
    a.clear

    click_link 'Show'
    page.current_path.should == '/Artist/browse'
    a.should == [:show, :browse]
    a.clear

    click_link 'Delete', :match=>:first
    Artist.create(:name=>'A')
    select 'WENTSITRATSET21'
    click_button 'Delete'
    click_button 'Delete'
    a.should == [:delete, :delete, :destroy, -3, 'destroy', 3, :delete]
    a.clear

    select 'A'
    click_button 'Delete'
    proc{click_button 'Delete'}.should raise_error
    a.should == [:delete, :destroy, -3]
  end

  it "should support specifying table class for data tables per type" do
    app_setup(Artist) do
      table_class{|type, req| type == :browse ? 'foo' : 'bar'}
    end
    visit("/Artist/browse")
    first('table')['class'].should == 'foo'
    click_link 'Search'
    click_button 'Search'
    first('table')['class'].should == 'bar'
  end

  it "should support specifying numbers of rows per page per type" do
    app_setup(Artist) do
      per_page{|type, req| type == :browse ? 2 : 3}
    end
    5.times{|i| Artist.create(:name=>i.to_s)}
    visit("/Artist/browse")
    first('li.disabled a').text.should == 'Previous'
    page.all('tr td:first-child').map{|s| s.text}.should == %w'0 1'
    click_link 'Next'
    page.all('tr td:first-child').map{|s| s.text}.should == %w'2 3'
    click_link 'Next'
    page.all('tr td:first-child').map{|s| s.text}.should == %w'4'
    first('li.disabled a').text.should == 'Next'
    click_link 'Previous'
    page.all('tr td:first-child').map{|s| s.text}.should == %w'2 3'
    click_link 'Previous'
    page.all('tr td:first-child').map{|s| s.text}.should == %w'0 1'
    first('li.disabled a').text.should == 'Previous'

    click_link 'Search'
    click_button 'Search'
    page.all('tr td:first-child').map{|s| s.text}.should == %w'0 1 2'
    click_link 'Next'
    page.all('tr td:first-child').map{|s| s.text}.should == %w'3 4'
    first('li.disabled a').text.should == 'Next'
    click_link 'Previous'
    page.all('tr td:first-child').map{|s| s.text}.should == %w'0 1 2'
    first('li.disabled a').text.should == 'Previous'
  end

  it "should support specifying supported actions" do
    app_setup(Artist) do
      supported_actions [:new, :edit, :browse, :search]
    end
    visit("/Artist/new")
    fill_in 'Name', :with=>'TestArtistNew'
    click_button 'Create'
    page.current_path.should == '/Artist/new'
    page.html.should_not =~ /Show/
    page.html.should_not =~ /Delete/

    click_link 'Edit'
    select 'TestArtistNew'
    click_button 'Edit'
    fill_in 'Name', :with=>'TestArtistUpdate'
    click_button 'Update'
    page.html.should =~ /Name.+TestArtistUpdate/m
    page.current_path.should =~ %r{/Artist/edit/\d+}

    click_link 'Search'
    fill_in 'Name', :with=>'Upd'
    click_button 'Search'
    page.all('td').map{|s| s.text}.should == ["TestArtistUpdate", "Edit"]

    click_link 'Artist'
    page.all('td').map{|s| s.text}.should == ["TestArtistUpdate", "Edit"]
  end

  it "should have basic functionality working" do
    app_setup(Artist) do
      class_display_name "FooArtist"
      link_name "BarArtist"
    end
    visit("/BarArtist/new")
    fill_in 'Name', :with=>'TestArtistNew'
    click_button 'Create'
    page.html.should =~ /Created FooArtist/
    page.current_path.should == '/BarArtist/new'

    click_link 'Edit'
    select 'TestArtistNew'
    click_button 'Edit'
    fill_in 'Name', :with=>'TestArtistUpdate'
    click_button 'Update'
    page.html.should =~ /Updated FooArtist/

    click_link 'FooArtist'
    page.all('td').map{|s| s.text}.should == ["TestArtistUpdate", "Show", "Edit", "Delete"]

    page.all('td').last.find('a').click
    click_button 'Delete'
    page.html.should =~ /Deleted FooArtist/
  end

  it "should use text boxes on list page when autocompleting is enabled" do
    app_setup(Artist) do
      autocomplete_options({})
    end
    a = Artist.create(:name=>'TestArtistNew')

    visit('/Artist/show')
    fill_in 'Artist', :with=>a.id.to_s
    click_button 'Show'
    page.html.should =~ /Name.+TestArtistNew/m

    click_link 'Edit'
    fill_in 'Artist', :with=>a.id.to_s
    click_button 'Edit'
    click_button 'Update'

    click_link 'Delete'
    fill_in 'Artist', :with=>a.id.to_s
    click_button 'Delete'
    click_button 'Delete'
    Artist.count.should == 0
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
    page.body.should_not =~ /<label>N5/i
    click_button 'Create'

    click_link 'Show'
    select 'V0'
    click_button 'Show'
    page.body.should =~ /[VN]0/i
    page.body.should =~ /[VN]1/i
    page.body.should =~ /[VN]2/i
    page.body.should_not =~ /[VN]3/i
    page.body.should =~ /[VN]4/i
    page.body.should =~ /N5/i

    click_link 'Edit'
    select 'V0'
    click_button 'Edit'
    fill_in 'N0', :with=>'Q0'
    fill_in 'N1', :with=>'Q1'
    fill_in 'N2', :with=>'Q2'
    fill_in 'N3', :with=>'Q3'
    page.body.should_not =~ /<label>N4/i
    fill_in 'N5', :with=>'Q5'
    click_button 'Update'

    click_link 'Search'
    fill_in 'N0', :with=>'Q0'
    page.body.should_not =~ /<label>N1/i
    fill_in 'N2', :with=>'Q2'
    fill_in 'N3', :with=>'Q3'
    fill_in 'N4', :with=>'V4'
    fill_in 'N5', :with=>'Q5'
    click_button 'Search'
    page.all('td').map{|s| s.text}.should == ["Q1", "Q2", "Q3", "V4", "Q5", "Show", "Edit", "Delete"]

    click_link 'Artist'
    page.all('td').map{|s| s.text}.should == ["Q0", "Q1", "Q3", "V4", "Q5", "Show", "Edit", "Delete"]
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
    page.all('option').map{|s| s.text}.should == ['', '2', '1', '0']

    click_link 'Edit'
    page.all('option').map{|s| s.text}.should == ['', '0', '1', '2']

    click_link 'Delete'
    page.all('option').map{|s| s.text}.should == ['', '2', '0', '1']

    click_link 'Search'
    click_button 'Search'
    page.all('tr td:first-child').map{|s| s.text}.should == ['0', '2', '1']

    click_link 'Artist'
    page.all('tr td:first-child').map{|s| s.text}.should == ['1', '2', '0']
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
    page.all('option').map{|s| s.text}.should == ['', '0']

    click_link 'Edit'
    page.all('option').map{|s| s.text}.should == ['', '2']
    select '2'
    click_button 'Edit'
    click_button 'Update'

    click_link 'Delete'
    page.all('option').map{|s| s.text}.should == ['', '1']
    select '1'
    click_button 'Delete'
    click_button 'Delete'
    Artist.create(:n0=>'1', :n1=>'2', :n2=>'3', :n3=>'7', :n4=>'5')

    click_link 'Search'
    click_button 'Search'
    page.all('tr td:first-child').map{|s| s.text}.should == %w'1'

    click_link 'Artist'
    page.all('tr td:first-child').map{|s| s.text}.should == %w'1'
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
    page.all('option').map{|s| s.text}.should == ['', '0']

    visit("/Artist/edit?f=1")
    page.all('option').map{|s| s.text}.should == ['', '2']

    visit("/Artist/delete?f=2")
    page.all('option').map{|s| s.text}.should == ['', '1']

    visit("/Artist/search/1?f=4")
    page.all('tr td:first-child').map{|s| s.text}.should == %w'1'

    visit("/Artist/browse?f=6")
    page.all('tr td:first-child').map{|s| s.text}.should == %w'1'
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
    page.all('option').map{|s| s.text}.should == ['', '2', '1']

    click_link 'Edit'
    page.all('option').map{|s| s.text}.should == ['', '2', '1']
    select '2'
    click_button 'Edit'
    click_button 'Update'

    click_link 'Delete'
    page.all('option').map{|s| s.text}.should == ['', '2', '1']
    select '1'
    click_button 'Delete'
    click_button 'Delete'
    Artist.create(:n0=>'1', :n1=>'2', :n2=>'3', :n3=>'7', :n4=>'5')

    click_link 'Search'
    click_button 'Search'
    page.all('tr td:first-child').map{|s| s.text}.should == %w'2 1'

    click_link 'Artist'
    page.all('tr td:first-child').map{|s| s.text}.should == %w'2 1'
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
    page.all('option').map{|s| s.text}.should == ['', '2', '1']

    click_link 'Edit'
    page.all('option').map{|s| s.text}.should == ['', '2', '1']
    select '2'
    click_button 'Edit'
    click_button 'Update'

    click_link 'Search'
    click_button 'Search'
    page.all('tr td:first-child').map{|s| s.text}.should == %w'2 1'

    click_link 'Artist'
    page.all('tr td:first-child').map{|s| s.text}.should == %w'2 1'

    click_link 'Delete', :match=>:first
    page.all('option').map{|s| s.text}.should == ['', '2', '1']
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

  it "should display decimals in float format in tables" do
    app_setup(Artist)
    visit("/Artist/new")
    page.title.should == 'Artist - New'
    fill_in 'Num', :with=>'1.01'
    click_button 'Create'
    click_link 'Artist'
    page.all('tr td:first-child').map{|s| s.text}.should == %w'1.01'
    click_link 'Search'
    click_button 'Search'
    page.all('tr td:first-child').map{|s| s.text}.should == %w'1.01'
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
    page.title.should == 'Artist - New'
    fill_in 'Name', :with=>'TestArtistNew'
    click_button 'Create'
    page.html.should =~ /Created Artist/
    page.current_path.should == '/Artist/new'

    click_link 'Show'
    page.title.should == 'Artist - Show'
    select '[-TestArtistNew-]'
    click_button 'Show'
    page.html.should =~ /Name.+-TestArtistNew-/m

    click_link 'Edit'
    page.title.should == 'Artist - Edit'
    select '[-TestArtistNew-]'
    click_button 'Edit'
    fill_in 'Name', :with=>'TestArtistUpdate'
    click_button 'Update'
    page.html.should =~ /Updated Artist/
    page.html.should =~ /Name.+-TestArtistUpdate-/m
    page.current_path.should =~ %r{/Artist/edit/\d+}

    click_link 'Search'
    page.title.should == 'Artist - Search'
    fill_in 'Name', :with=>'Upd'
    click_button 'Search'
    page.all('th').map{|s| s.text}.should == ['Name', 'Show', 'Edit', 'Delete']
    page.all('td').map{|s| s.text}.should == ["-TestArtistUpdate-", "Show", "Edit", "Delete"]

    click_link 'Search'
    fill_in 'Name', :with=>'Foo'
    click_button 'Search'
    page.all('td').map{|s| s.text}.should == []

    click_link 'Artist'
    page.title.should == 'Artist - Browse'
    page.all('td').map{|s| s.text}.should == ["-TestArtistUpdate-", "Show", "Edit", "Delete"]

    page.all('td').last.find('a').click
    click_button 'Delete'
    page.html.should =~ /Deleted Artist/
    page.current_path.should == '/Artist/delete'

    click_link 'Artist'
    page.all('td').map{|s| s.text}.should == []
  end
end
