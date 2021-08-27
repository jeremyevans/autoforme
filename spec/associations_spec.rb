require_relative 'spec_helper'

describe AutoForme do
  before(:all) do
    db_setup(:artists=>[[:name, :string]], :albums=>[[:name, :string], [:artist_id, :integer, {:table=>:artists}]])
    model_setup(:Artist=>[:artists, [[:one_to_many, :albums]]], :Album=>[:albums, [[:many_to_one, :artist]]])
  end
  after(:all) do
    Object.send(:remove_const, :Album)
    Object.send(:remove_const, :Artist)
  end

  it "should have basic many to one associations working" do
    app_setup do
      model Artist
      model Album do
        columns [:name, :artist]
      end
    end

    visit("/Artist/new")
    fill_in 'Name', :with=>'Artist1'
    click_button 'Create'
    fill_in 'Name', :with=>'Artist2'
    click_button 'Create'

    visit("/Album/new")
    fill_in 'Name', :with=>'Album1'
    click_button 'Create'

    click_link 'Edit'
    select 'Album1'
    click_button 'Edit'
    fill_in 'Name', :with=>'Album1b'
    select 'Artist2'
    click_button 'Update'

    click_link 'Show'
    select 'Album1'
    click_button 'Show'
    page.html.must_match(/Name.+Album1b/m)
    page.html.must_match(/Artist.+Artist2/m)

    click_link 'Search'
    fill_in 'Name', :with=>'1b'
    select 'Artist2'
    click_button 'Search'
    page.all('td').map{|s| s.text}.must_equal ["Album1b", "Artist2", "Show", "Edit", "Delete"]

    click_link 'Album'
    page.all('td').map{|s| s.text}.must_equal ["Album1b", "Artist2", "Show", "Edit", "Delete"]
  end

  it "should escape display names in association links" do
    app_setup do
      model Artist
      model Album do
        columns [:name, :artist]
      end
      association_links :all
    end

    visit("/Artist/new")
    fill_in 'Name', :with=>'Art&"ist2'
    click_button 'Create'

    visit("/Album/new")
    fill_in 'Name', :with=>'Album1'
    select 'Art&"ist2'
    click_button 'Create'

    click_link 'Edit'
    select 'Album1'
    click_button 'Edit'
    page.html.must_match(%r{- <a href="/Artist/edit/\d+">Art&amp;&quot;ist2})
  end

  it "should escape display names in association links" do
    app_setup do
      model Album do
        columns [:name, :artist]
      end
      association_links :all
    end

    Artist.create(:name=>'Art&"ist2')
    visit("/Album/new")
    fill_in 'Name', :with=>'Album1'
    select 'Art&"ist2'
    click_button 'Create'

    click_link 'Edit'
    select 'Album1'
    click_button 'Edit'
    page.html.must_include("- Art&amp;&quot;ist2")
  end

  it "should use text boxes for associated objects on new/edit/search forms if associated model uses autocompleting" do
    app_setup do
      model Artist do
        autocomplete_options({})
      end
      model Album do
        columns [:name, :artist]
      end
    end

    a = Artist.create(:name=>'TestArtist')
    b = Artist.create(:name=>'TestArtist2')

    visit("/Album/new")
    fill_in 'Name', :with=>'Album1'
    fill_in 'Artist', :with=>a.id.to_s
    click_button 'Create'
    Album.first.artist_id.must_equal a.id

    click_link 'Show'
    select 'Album1'
    click_button 'Show'
    page.body.must_include 'TestArtist'

    click_link 'Edit'
    select 'Album1'
    click_button 'Edit'
    fill_in 'Name', :with=>'Album1b'
    fill_in 'Artist', :with=>b.id.to_s
    click_button 'Update'
    Album.first.artist_id.must_equal b.id

    click_link 'Search'
    fill_in 'Name', :with=>'1b'
    fill_in 'Artist', :with=>b.id.to_s
    click_button 'Search'
    page.all('td').map{|s| s.text}.must_equal ["Album1b", "TestArtist2", "Show", "Edit", "Delete"]

    visit '/Artist/autocomplete?q=Test'
    page.body.must_match(/\d+ - TestArtist\n\d+ - TestArtist2/m)

    visit '/Album/autocomplete/artist?q=Test'
    page.body.must_match(/\d+ - TestArtist\n\d+ - TestArtist2/m)

    visit '/Album/autocomplete/artist?type=edit&q=Test'
    page.body.must_match(/\d+ - TestArtist\n\d+ - TestArtist2/m)
  end

  it "should be able to used specified name formatting in other model" do
    app_setup do
      model Artist do
        display_name{|obj| obj.name * 2}
      end
      model Album do
        columns [:name, :artist]
      end
    end

    visit("/Artist/new")
    fill_in 'Name', :with=>'A1'
    click_button 'Create'
    fill_in 'Name', :with=>'A2'
    click_button 'Create'

    visit("/Album/new")
    fill_in 'Name', :with=>'Album1'
    select 'A1A1'
    click_button 'Create'

    click_link 'Show'
    select 'Album1'
    click_button 'Show'
    page.html.must_match(/Name.+Album1/m)
    page.html.must_match(/Artist.+A1A1/m)

    click_link 'Edit'
    select 'Album1'
    click_button 'Edit'
    fill_in 'Name', :with=>'Album1b'
    select 'A2A2'
    click_button 'Update'

    click_link 'Search'
    fill_in 'Name', :with=>'1b'
    select 'A2A2'
    click_button 'Search'
    page.all('td').map{|s| s.text}.must_equal ["Album1b", "A2A2", "Show", "Edit", "Delete"]

    click_link 'Album'
    page.all('td').map{|s| s.text}.must_equal ["Album1b", "A2A2", "Show", "Edit", "Delete"]
  end

  it "should be able to used specified name formatting for current association" do
    app_setup do
      model Artist
      model Album do
        columns [:name, :artist]
        column_options :artist=>{:name_method=>lambda{|obj| obj.name * 2}}
      end
    end

    visit("/Artist/new")
    fill_in 'Name', :with=>'A1'
    click_button 'Create'
    fill_in 'Name', :with=>'A2'
    click_button 'Create'

    visit("/Album/new")
    fill_in 'Name', :with=>'Album1'
    select 'A1A1'
    click_button 'Create'

    click_link 'Show'
    select 'Album1'
    click_button 'Show'
    page.html.must_match(/Name.+Album1/m)
    page.html.must_match(/Artist.+A1A1/m)

    click_link 'Edit'
    select 'Album1'
    click_button 'Edit'
    fill_in 'Name', :with=>'Album1b'
    select 'A2A2'
    click_button 'Update'

    click_link 'Search'
    fill_in 'Name', :with=>'1b'
    select 'A2A2'
    click_button 'Search'
    page.all('td').map{|s| s.text}.must_equal ["Album1b", "A2A2", "Show", "Edit", "Delete"]

    click_link 'Album'
    page.all('td').map{|s| s.text}.must_equal ["Album1b", "A2A2", "Show", "Edit", "Delete"]
  end

  it "should be able to used specified name formatting for current association" do
    app_setup do
      model Artist
      model Album do
        columns [:name, :artist]
        column_options :artist=>{:name_method=>:name}
      end
    end

    visit("/Artist/new")
    fill_in 'Name', :with=>'A1'
    click_button 'Create'
    fill_in 'Name', :with=>'A2'
    click_button 'Create'

    visit("/Album/new")
    fill_in 'Name', :with=>'Album1'
    select 'A1'
    click_button 'Create'

    click_link 'Show'
    select 'Album1'
    click_button 'Show'
    page.html.must_match(/Name.+Album1/m)
    page.html.must_match(/Artist.+A1/m)

    click_link 'Edit'
    select 'Album1'
    click_button 'Edit'
    fill_in 'Name', :with=>'Album1b'
    select 'A2'
    click_button 'Update'

    click_link 'Search'
    fill_in 'Name', :with=>'1b'
    select 'A2'
    click_button 'Search'
    page.all('td').map{|s| s.text}.must_equal ["Album1b", "A2", "Show", "Edit", "Delete"]

    click_link 'Album'
    page.all('td').map{|s| s.text}.must_equal ["Album1b", "A2", "Show", "Edit", "Delete"]
  end

  it "should be able to eager load associations when loading model" do
    app_setup do
      model Artist
      model Album do
        columns [:name, :artist]
        eager :artist
        display_name{|obj| "#{obj.associations[:artist].name}-#{obj.name}"}
      end
    end

    visit("/Artist/new")
    fill_in 'Name', :with=>'A1'
    click_button 'Create'
    fill_in 'Name', :with=>'A2'
    click_button 'Create'

    visit("/Album/new")
    fill_in 'Name', :with=>'Album1'
    select 'A1'
    click_button 'Create'

    click_link 'Show'
    select 'A1-Album1'
    click_button 'Show'
    page.html.must_match(/Name.+Album1/m)
    page.html.must_match(/Artist.+A1/m)

    click_link 'Edit'
    select 'A1-Album1'
    click_button 'Edit'
    fill_in 'Name', :with=>'Album1b'
    select 'A2'
    click_button 'Update'

    click_link 'Search'
    fill_in 'Name', :with=>'1b'
    select 'A2'
    click_button 'Search'
    page.all('td').map{|s| s.text}.must_equal ["Album1b", "A2", "Show", "Edit", "Delete"]

    click_link 'Album'
    page.all('td').map{|s| s.text}.must_equal ["Album1b", "A2", "Show", "Edit", "Delete"]

    click_link 'Delete', :match=>:first
    select 'A2-Album1b'
    click_button 'Delete'
  end

  it "should be able to eager load associations when loading model without autoforme for associated model" do
    app_setup do
      model Album do
        columns [:name, :artist]
        eager :artist
        display_name{|obj| "#{obj.associations[:artist].name}-#{obj.name}"}
      end
    end

    Artist.create(:name=>'A1')
    Artist.create(:name=>'A2')

    visit("/Album/new")
    fill_in 'Name', :with=>'Album1'
    select 'A1'
    click_button 'Create'

    click_link 'Show'
    select 'A1-Album1'
    click_button 'Show'
    page.html.must_match(/Name.+Album1/m)
    page.html.must_match(/Artist.+A1/m)

    click_link 'Edit'
    select 'A1-Album1'
    click_button 'Edit'
    fill_in 'Name', :with=>'Album1b'
    select 'A2'
    click_button 'Update'

    click_link 'Search'
    fill_in 'Name', :with=>'1b'
    select 'A2'
    click_button 'Search'
    page.all('td').map{|s| s.text}.must_equal ["Album1b", "A2", "Show", "Edit", "Delete"]

    click_link 'Album'
    page.all('td').map{|s| s.text}.must_equal ["Album1b", "A2", "Show", "Edit", "Delete"]

    click_link 'Delete', :match=>:first
    select 'A2-Album1b'
    click_button 'Delete'
  end

  it "should handle case when setting many_to_one association for associated class that eagerly graphs" do
    app_setup do
      model Artist do
        eager_graph :albums
      end
      model Album do
        columns [:name, :artist]
        eager_graph :artist
        order{|type, req| type == :edit ? [Sequel[:albums][:name], Sequel[:artist][:name]] : [Sequel[:artist][:name], Sequel[:albums][:name]]}
        display_name{|obj, type| type == :edit ? "#{obj.name} (#{obj.artist.name})" : "#{obj.artist.name}-#{obj.name}"}
      end
    end

    visit("/Artist/new")
    fill_in 'Name', :with=>'B'
    click_button 'Create'
    visit("/Album/new")
    fill_in 'Name', :with=>'A'
    select 'B'
    click_button 'Create'
  end

  it "should be able to order on eager_graphed associations when loading model" do
    app_setup do
      model Artist
      model Album do
        columns [:name, :artist]
        eager_graph :artist
        order{|type, req| type == :edit ? [Sequel[:albums][:name], Sequel[:artist][:name]] : [Sequel[:artist][:name], Sequel[:albums][:name]]}
        display_name{|obj, type| type == :edit ? "#{obj.name} (#{obj.artist.name})" : "#{obj.artist.name}-#{obj.name}"}
      end
    end

    visit("/Artist/new")
    fill_in 'Name', :with=>'B'
    click_button 'Create'
    fill_in 'Name', :with=>'A'
    click_button 'Create'

    visit("/Album/new")
    fill_in 'Name', :with=>'Z'
    select 'B'
    click_button 'Create'
    fill_in 'Name', :with=>'Y'
    select 'A'
    click_button 'Create'
    fill_in 'Name', :with=>'X'
    select 'B'
    click_button 'Create'

    click_link 'Show'
    page.all('select option').map{|s| s.text}.must_equal ['', 'A-Y', 'B-X', 'B-Z']
    select 'B-X'
    click_button 'Show'
    page.html.must_match(/Name.+X/m)
    page.html.must_match(/Artist.+B/m)

    click_link 'Edit'
    page.all('select option').map{|s| s.text}.must_equal ['', 'X (B)', 'Y (A)', 'Z (B)']
    select 'Z (B)'
    click_button 'Edit'
    fill_in 'Name', :with=>'ZZ'
    select 'A'
    click_button 'Update'

    click_link 'Search'
    select 'A'
    click_button 'Search'
    page.all('tr td:first-child').map{|s| s.text}.must_equal %w'Y ZZ'

    click_link 'Album'
    page.all('tr td:first-child').map{|s| s.text}.must_equal %w'Y ZZ X'

    click_link 'Delete', :match=>:first
    page.all('select option').map{|s| s.text}.must_equal ['', 'A-Y', 'A-ZZ', 'B-X']
    select 'B-X'
    click_button 'Delete'
  end

  it "should have many_to_one association lookup use order/eager/eager_graph/filter for associated model" do
    app_setup do
      model Artist do
        order :name
        eager :albums
        filter{|ds, action| ds.where{name > 'M'}}
        display_name{|obj| "#{obj.name} #{obj.albums.length}"}
      end
      model Album do
        columns [:name, :artist]
        order [:name]
      end
    end

    visit("/Artist/new")
    fill_in 'Name', :with=>'J'
    click_button 'Create'
    fill_in 'Name', :with=>'Z'
    click_button 'Create'
    fill_in 'Name', :with=>'Y'
    click_button 'Create'
    fill_in 'Name', :with=>'X'
    click_button 'Create'

    visit("/Album/new")
    fill_in 'Name', :with=>'E'
    page.all('select option').map{|s| s.text}.must_equal ['', 'X 0', 'Y 0', 'Z 0']
    select 'X 0'
    click_button 'Create'
    fill_in 'Name', :with=>'D'
    page.all('select option').map{|s| s.text}.must_equal ['', 'X 1', 'Y 0', 'Z 0']
    select 'Y 0'
    click_button 'Create'
    fill_in 'Name', :with=>'C'
    page.all('select option').map{|s| s.text}.must_equal ['', 'X 1', 'Y 1', 'Z 0']
    select 'Y 1'
    click_button 'Create'

    click_link 'Show'
    select 'D'
    click_button 'Show'
    page.html.must_match(/Name.+D/m)
    page.html.must_match(/Artist.+Y 2/m)

    click_link 'Edit'
    select 'C'
    click_button 'Edit'
    page.all('select option').map{|s| s.text}.must_equal ['', 'X 1', 'Y 2', 'Z 0']
    select 'X 1'
    click_button 'Update'

    click_link 'Search'
    page.all('select option').map{|s| s.text}.must_equal ['', 'X 2', 'Y 1', 'Z 0']
    select 'X 2'
    click_button 'Search'
    page.all('tr td:first-child').map{|s| s.text}.must_equal %w'C E'

    click_link 'Album'
    page.all('tr td:first-child').map{|s| s.text}.must_equal %w'C D E'

    click_link 'Delete', :match=>:first
    page.all('select option').map{|s| s.text}.must_equal ['', 'C', 'D', 'E']
    select 'C'
    click_button 'Delete'
    click_button 'Delete'

    visit("/Album/new")
    Artist.where(:name=>'Y').update(:name=>'A')
    fill_in 'Name', :with=>'F'
    select 'Y 1' 
    proc{click_button 'Create'}.must_raise(Sequel::NoMatchingRow)

    visit("/Album/search")
    select 'X 1' 
    Artist.where(:name=>'X').update(:name=>'B')
    click_button 'Search'
    page.all('tr td:first-child').map{|s| s.text}.must_equal []
  end

  it "should have working one to many and many to one association links on show and edit pages" do
    app_setup do
      model Artist do
        association_links :all
      end
      model Album do
        association_links :all
        columns [:name, :artist]
      end
    end

    visit("/Artist/new")
    fill_in 'Name', :with=>'Artist1'
    click_button 'Create'

    click_link 'Edit'
    select 'Artist1'
    click_button 'Edit'
    click_link 'create'
    fill_in 'Name', :with=>'Album1'
    click_button 'Create'

    click_link 'Show'
    select 'Album1'
    click_button 'Show'
    click_link 'Artist1'
    page.current_path.must_match %r{Artist/show/\d+}
    click_link 'Album1'
    page.current_path.must_match %r{Album/show/\d+}
    click_link 'Artist'
    page.current_path.must_equal '/Artist/browse'

    click_link 'Edit', :match=>:first
    select 'Artist1'
    click_button 'Edit'
    click_link 'Album1'
    page.current_path.must_match %r{Album/edit/\d+}
    click_link 'Artist1'
    page.current_path.must_match %r{Artist/edit/\d+}
    click_link 'Albums'
    page.current_path.must_equal '/Album/browse'

    visit "/Album/association_links/#{Artist.first.id}"
    click_link 'Artist1'
    click_button 'Update'
    page.current_path.must_match %r{Artist/edit/\d+}
  end

  it "should have working associations listed without links if there is no autoforme for other model" do
    app_setup do
      model Artist do
        association_links :all
      end
    end

    visit("/Artist/new")
    fill_in 'Name', :with=>'Artist1'
    click_button 'Create'

    Artist.first.add_album(:name=>'Album1')
    click_link 'Edit'
    select 'Artist1'
    click_button 'Edit'
    page.html.must_include 'Album1'
    page.html.wont_include 'create'
    page.html.wont_include '/Album'
  end

  it "should display but not link if the action is not supported " do
    app_setup do
      model Artist do
        association_links :all
      end
      model Album do
        association_links :all
        supported_actions [:new]
        display_name{|o| o.name.to_sym}
      end
    end

    visit("/Artist/new")
    fill_in 'Name', :with=>'Artist1'
    click_button 'Create'

    click_link 'Edit'
    select 'Artist1'
    click_button 'Edit'
    click_link 'create'
    fill_in 'Name', :with=>'Album1'
    click_button 'Create'

    visit("/Artist/edit")
    select 'Artist1'
    click_button 'Edit'
    page.html.must_include 'Album1'
    page.html.wont_include '>edit<'
  end

  it "should support lazy loading association links on show and edit pages" do
    app_setup do
      model Artist do
        lazy_load_association_links true
        association_links :all
      end
      model Album do
        lazy_load_association_links true
        association_links :all
        columns [:name, :artist]
      end
    end

    visit("/Artist/new")
    fill_in 'Name', :with=>'Artist1'
    click_button 'Create'

    click_link 'Edit'
    select 'Artist1'
    click_button 'Edit'
    page.html.wont_include 'create'
    click_link 'Show Associations'
    click_link 'create'
    fill_in 'Name', :with=>'Album1'
    click_button 'Create'

    click_link 'Show'
    select 'Album1'
    click_button 'Show'
    click_link 'Show Associations'
    click_link 'Artist1'
    page.current_path.must_match %r{Artist/show/\d+}
    click_link 'Show Associations'
    click_link 'Album1'
    page.current_path.must_match %r{Album/show/\d+}
    click_link 'Show Associations'
    click_link 'Artist'
    page.current_path.must_equal '/Artist/browse'

    click_link 'Edit', :match=>:first
    select 'Artist1'
    click_button 'Edit'
    click_link 'Show Associations'
    click_link 'Album1'
    page.current_path.must_match %r{Album/edit/\d+}
    click_link 'Show Associations'
    click_link 'Artist1'
    page.current_path.must_match %r{Artist/edit/\d+}
    click_link 'Show Associations'
    click_link 'Albums'
    page.current_path.must_equal '/Album/browse'
  end
end

describe AutoForme do
  before(:all) do
    db_setup(:artists=>[[:name, :string], [:artist_id, :integer]], :albums=>[[:name, :string], [:artist_id, :integer, {:table=>:artists}]])
    model_setup(:Artist=>[:artists, [[:one_to_many, :albums]]], :Album=>[:albums, [[:many_to_one, :artist]]])
  end
  after(:all) do
    Object.send(:remove_const, :Album)
    Object.send(:remove_const, :Artist)
  end

  it "should have basic many to one associations working" do
    app_setup do
      model Artist
      model Album do
        columns [:name, :artist]
        eager_graph :artist
        order Sequel[:artist][:name]
      end
    end

    visit("/Artist/new")
    fill_in 'Name', :with=>'Artist1'
    click_button 'Create'
    fill_in 'Name', :with=>'Artist2'
    click_button 'Create'

    visit("/Album/new")
    fill_in 'Name', :with=>'Album1'
    click_button 'Create'

    click_link 'Edit'
    select 'Album1'
    click_button 'Edit'
    fill_in 'Name', :with=>'Album1b'
    select 'Artist2'
    click_button 'Update'

    click_link 'Show'
    select 'Album1'
    click_button 'Show'
    page.html.must_match(/Name.+Album1b/m)
    page.html.must_match(/Artist.+Artist2/m)

    click_link 'Search'
    fill_in 'Name', :with=>'1b'
    select 'Artist2'
    click_button 'Search'
    page.all('td').map{|s| s.text}.must_equal ["Album1b", "Artist2", "Show", "Edit", "Delete"]

    click_link 'Album'
    page.all('td').map{|s| s.text}.must_equal ["Album1b", "Artist2", "Show", "Edit", "Delete"]
  end

  it "should have basic many to one associations working" do
    app_setup do
      model Artist do
        eager_graph :albums
        order Sequel[:albums][:name]
      end
      model Album do
        columns [:name, :artist]
      end
    end

    visit("/Artist/new")
    fill_in 'Name', :with=>'Artist1'
    click_button 'Create'
    fill_in 'Name', :with=>'Artist2'
    click_button 'Create'

    visit("/Album/new")
    fill_in 'Name', :with=>'Album1'
    click_button 'Create'

    click_link 'Edit'
    select 'Album1'
    click_button 'Edit'
    fill_in 'Name', :with=>'Album1b'
    select 'Artist2'
    click_button 'Update'

    click_link 'Show'
    select 'Album1'
    click_button 'Show'
    page.html.must_match(/Name.+Album1b/m)
    page.html.must_match(/Artist.+Artist2/m)

    click_link 'Search'
    fill_in 'Name', :with=>'1b'
    select 'Artist2'
    click_button 'Search'
    page.all('td').map{|s| s.text}.must_equal ["Album1b", "Artist2", "Show", "Edit", "Delete"]

    click_link 'Album'
    page.all('td').map{|s| s.text}.must_equal ["Album1b", "Artist2", "Show", "Edit", "Delete"]
  end
end

describe AutoForme do
  before(:all) do
    db_setup(:artists=>[[:name, :string]], :albums=>[[:name, :string], [:artist_id, :integer, {:table=>:artists}]])
    model_setup(:Artist=>[:artists, [[:one_to_many, :albums]]], :Album=>[:albums, [[:many_to_one, :artist, {:conditions=>{:name=>'A'..'M'}, :order=>:name}]]])
  end
  after(:all) do
    Object.send(:remove_const, :Album)
    Object.send(:remove_const, :Artist)
  end

  it "should have select options respect association options" do
    app_setup do
      model Artist
      model Album do
        columns [:name, :artist]
        column_options{|col, type, req| {:dataset=>proc{|ds| ds.where(:name=>'B'..'O').reverse_order(:name)}} if type == :edit && col == :artist}
      end
    end

    %w'A1 E1 L1 N1'.each{|n| Artist.create(:name=>n)}
    visit("/Album/new")
    page.all('select option').map{|s| s.text}.must_equal ["", "A1", "E1", "L1"]

    visit("/Album/edit/#{Album.create(:name=>'Album1').id}")
    page.all('select option').map{|s| s.text}.must_equal ["", "L1", "E1"]
  end
end
