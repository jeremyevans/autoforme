require_relative 'spec_helper'

describe AutoForme do
  before(:all) do
    db_setup(:artists=>[[:name, :string]], :albums=>[[:name, :string]], :albums_artists=>[[:album_id, :integer, {:table=>:albums}], [:artist_id, :integer, {:table=>:artists}]])
    model_setup(:Artist=>[:artists, [[:many_to_many, :albums]]], :Album=>[:albums, [[:many_to_many, :artists]]])
  end
  after(:all) do
    Object.send(:remove_const, :Album)
    Object.send(:remove_const, :Artist)
  end

  it "should not show MTM link if there are no many to many associations" do
    app_setup do
      model Artist
      model Album
    end

    visit("/Artist/browse")
    page.html.wont_include 'MTM'
    visit("/Artist/mtm_edit")
    page.html.must_include 'Unhandled Request'
  end

  it "should have working Model#associated_object_display_name" do
    mod = nil
    app_setup do
      model Artist
      model Album do
        mod = self
      end
    end

    mod.associated_object_display_name(:artist, nil, Artist.load(:name=>'a')).must_equal 'a'
  end

  it "should have Model#associated_object_display_name respect :name_method column option" do
    mod = nil
    app_setup do
      model Artist
      model Album do
        column_options :artist=>{:name_method=>:id}
        mod = self
      end
    end

    mod.associated_object_display_name(:artist, nil, Artist.load(:id=>1)).must_equal 1
  end

  it "should have Model#associated_object_display_name raise Error if not valid" do
    mod = nil
    app_setup do
      model Artist
      model Album do
        column_options :artist=>{:name_method=>Object.new}
        mod = self
      end
    end

    proc{mod.associated_object_display_name(:artist, nil, Artist.load(:name=>'a'))}.must_raise AutoForme::Error
  end

  it "should have basic many to many association editing working" do
    app_setup do
      model Artist do
        mtm_associations :albums
      end
      model Album
    end

    Artist.create(:name=>'Artist1')
    Album.create(:name=>'Album1')
    Album.create(:name=>'Album2')
    Album.create(:name=>'Album3')

    visit("/Artist/mtm_edit")
    page.title.must_equal 'Artist - Many To Many Edit'
    click_button "Edit"
    select("Artist1")
    click_button "Edit"

    find('h2').text.must_equal 'Edit Albums for Artist1'
    page.all('select')[0].all('option').map{|s| s.text}.must_equal ["Album1", "Album2", "Album3"]
    page.all('select')[1].all('option').map{|s| s.text}.must_equal []
    select("Album1", :from=>"Associate With")
    click_button "Update"
    page.html.must_include 'Updated albums association for Artist'
    Artist.first.albums.map{|x| x.name}.must_equal %w'Album1'

    page.all('select')[0].all('option').map{|s| s.text}.must_equal ["Album2", "Album3"]
    page.all('select')[1].all('option').map{|s| s.text}.must_equal ["Album1"]
    select("Album2", :from=>"Associate With")
    select("Album3", :from=>"Associate With")
    select("Album1", :from=>"Disassociate From")
    click_button "Update"
    Artist.first.refresh.albums.map{|x| x.name}.must_equal %w'Album2 Album3'

    page.all('select')[0].all('option').map{|s| s.text}.must_equal ["Album1"]
    page.all('select')[1].all('option').map{|s| s.text}.must_equal ["Album2", "Album3"]
  end

  it "should handle unsupported associations with a 404 response" do
    mod = nil
    app_setup do
      model Artist do
        mod = self
        mtm_associations :albums
      end
      model Album
    end

    visit("/Artist/new")
    fill_in 'Name', :with=>'Artist1'
    click_button 'Create'

    visit "/Artist/mtm_edit/#{Artist.first.id}?association=foo"
    page.status_code.must_equal 404

    visit "/Artist/mtm_edit/#{Artist.first.id}?association=albums"
    mod.mtm_associations{}
    click_button 'Update'
    page.status_code.must_equal 404
  end

  it "should have many to many association editing working with autocompletion" do
    app_setup do
      model Artist do
        mtm_associations :albums
      end
      model Album do
        autocomplete_options({})
      end
    end

    Artist.create(:name=>'Artist1')
    a1 = Album.create(:name=>'Album1')
    a2 = Album.create(:name=>'Album2')
    a3 = Album.create(:name=>'Album3')

    visit("/Artist/mtm_edit")
    select("Artist1")
    click_button "Edit"

    page.all('select')[0].all('option').map{|s| s.text}.must_equal []
    fill_in "Associate With", :with=>a1.id
    click_button "Update"
    page.html.must_include 'Updated albums association for Artist'
    Artist.first.albums.map{|x| x.name}.must_equal %w'Album1'

    page.all('select')[0].all('option').map{|s| s.text}.must_equal ["Album1"]
    fill_in "Associate With", :with=>a2.id
    select("Album1", :from=>"Disassociate From")
    click_button "Update"
    Artist.first.refresh.albums.map{|x| x.name}.must_equal %w'Album2'

    visit "/Artist/autocomplete/albums?type=association&q=Album"
    page.body.must_match(/#{a1.id} - Album1\n#{a2.id} - Album2\n#{a3.id} - Album3/m)

    visit "/Artist/autocomplete/albums?type=association&q=3"
    page.body.wont_match(/#{a1.id} - Album1\n#{a2.id} - Album2\n#{a3.id} - Album3/m)
    page.body.must_match(/#{a3.id} - Album3/m)

    visit "/Artist/autocomplete/albums?type=association&exclude=#{Artist.first.id}&q=Album"
    page.body.must_match(/#{a1.id} - Album1\n#{a3.id} - Album3/m)

    visit("/Artist/mtm_edit")
    select("Artist1")
    click_button "Edit"
    page.all('select')[0].all('option').map{|s| s.text}.must_equal ["Album2"]
    select("Album2", :from=>"Disassociate From")
    click_button "Update"
    Artist.first.refresh.albums.map{|x| x.name}.must_equal []
    page.all('select')[0].all('option').map{|s| s.text}.must_equal []
  end

  it "should have inline many to many association editing working" do
    app_setup do
      model Artist do
        inline_mtm_associations :albums
      end
      model Album
    end

    Artist.create(:name=>'Artist1')
    Album.create(:name=>'Album1')
    Album.create(:name=>'Album2')
    Album.create(:name=>'Album3')

    visit("/Artist/edit")
    select("Artist1")
    click_button "Edit"
    select 'Album1'
    click_button 'Add'
    page.html.must_include 'Updated albums association for Artist'
    Artist.first.albums.map{|x| x.name}.must_equal %w'Album1'

    select 'Album2'
    click_button 'Add'
    Artist.first.refresh.albums.map{|x| x.name}.sort.must_equal %w'Album1 Album2'

    click_button 'Remove', :match=>:first
    Artist.first.refresh.albums.map{|x| x.name}.must_equal %w'Album2'

    select 'Album3'
    click_button 'Add'
    Artist.first.refresh.albums.map{|x| x.name}.sort.must_equal %w'Album2 Album3'
  end

  it "should have inline many to many association editing working with autocompletion" do
    app_setup do
      model Artist do
        inline_mtm_associations :albums
      end
      model Album do
        autocomplete_options({})
      end
    end

    Artist.create(:name=>'Artist1')
    a1 = Album.create(:name=>'Album1')
    a2 = Album.create(:name=>'Album2')
    a3 = Album.create(:name=>'Album3')

    visit("/Artist/edit")
    select("Artist1")
    click_button "Edit"
    fill_in 'Albums', :with=>a1.id.to_s
    click_button 'Add'
    page.html.must_include 'Updated albums association for Artist'
    Artist.first.albums.map{|x| x.name}.must_equal %w'Album1'

    fill_in 'Albums', :with=>a2.id.to_s
    click_button 'Add'
    Artist.first.refresh.albums.map{|x| x.name}.sort.must_equal %w'Album1 Album2'

    click_button 'Remove', :match=>:first
    Artist.first.refresh.albums.map{|x| x.name}.must_equal %w'Album2'

    fill_in 'Albums', :with=>a3.id.to_s
    click_button 'Add'
    Artist.first.refresh.albums.map{|x| x.name}.sort.must_equal %w'Album2 Album3'
  end

  it "should have inline many to many association editing working with xhr" do
    app_setup do
      model Artist do
        inline_mtm_associations do |req|
          def req.xhr?; action_type == 'mtm_update' end
          :albums
        end
      end
      model Album
    end

    Artist.create(:name=>'Artist1')
    album = Album.create(:name=>'Album1')

    visit("/Artist/edit")
    select("Artist1")
    click_button "Edit"
    select 'Album1'
    click_button 'Add'
    Artist.first.albums.map{|x| x.name}.must_equal %w'Album1'

    click_button 'Remove'
    Artist.first.refresh.albums.map{|x| x.name}.must_equal []
    page.body.must_equal "<option value=\"#{album.id}\">Album1</option>"
  end

  it "should have working many to many association links on show and edit pages" do
    app_setup do
      model Artist do
        mtm_associations :albums
        association_links :all_except_mtm
      end
      model Album do
        mtm_associations [:artists]
        association_links :all
      end
    end

    visit("/Artist/new")
    fill_in 'Name', :with=>'Artist1'
    click_button 'Create'
    click_link 'Edit'
    select 'Artist1'
    click_button 'Edit'
    page.html.wont_include 'Albums'

    visit("/Album/new")
    fill_in 'Name', :with=>'Album1'
    click_button 'Create'
    click_link 'Edit'
    select 'Album1'
    click_button 'Edit'
    click_link 'associate'
    select("Artist1", :from=>"Associate With")
    click_button 'Update'
    click_link 'Show'
    select 'Album1'
    click_button 'Show'
    click_link 'Artist1'
    page.current_path.must_match %r{Artist/show/\d+}
    page.html.wont_include 'Albums'
  end

  it "should have many to many association editing working when associated class is not using autoforme" do
    app_setup do
      model Artist do
        mtm_associations [:albums]
      end
    end

    Artist.create(:name=>'Artist1')
    Album.create(:name=>'Album1')
    Album.create(:name=>'Album2')
    Album.create(:name=>'Album3')

    visit("/Artist/mtm_edit")
    select("Artist1")
    click_button "Edit"

    page.all('select')[0].all('option').map{|s| s.text}.must_equal ["Album1", "Album2", "Album3"]
    page.all('select')[1].all('option').map{|s| s.text}.must_equal []
    select("Album1", :from=>"Associate With")
    click_button "Update"
    Artist.first.refresh.albums.map{|x| x.name}.must_equal %w'Album1'

    page.all('select')[0].all('option').map{|s| s.text}.must_equal ["Album2", "Album3"]
    page.all('select')[1].all('option').map{|s| s.text}.must_equal ["Album1"]
    select("Album2", :from=>"Associate With")
    select("Album3", :from=>"Associate With")
    select("Album1", :from=>"Disassociate From")
    click_button "Update"
    Artist.first.refresh.albums.map{|x| x.name}.must_equal %w'Album2 Album3'

    page.all('select')[0].all('option').map{|s| s.text}.must_equal ["Album1"]
    page.all('select')[1].all('option').map{|s| s.text}.must_equal ["Album2", "Album3"]
  end

  it "should use filter/order from associated class" do
    app_setup do
      model Artist do
        mtm_associations :all
      end
      model Album do
        filter{|ds, req| ds.where(:name=>'A'..'M')}
        order :name
      end
    end

    Artist.create(:name=>'Artist1')
    Album.create(:name=>'E1')
    Album.create(:name=>'B1')
    Album.create(:name=>'O1')

    visit("/Artist/mtm_edit")
    select("Artist1")
    click_button "Edit"

    page.all('select')[0].all('option').map{|s| s.text}.must_equal ["B1", "E1"]
    page.all('select')[1].all('option').map{|s| s.text}.must_equal []
    select("E1", :from=>"Associate With")
    click_button "Update"
    Artist.first.albums.map{|x| x.name}.must_equal %w'E1'

    page.all('select')[0].all('option').map{|s| s.text}.must_equal ["B1"]
    page.all('select')[1].all('option').map{|s| s.text}.must_equal ["E1"]
    select("B1", :from=>"Associate With")
    select("E1", :from=>"Disassociate From")
    click_button "Update"
    Artist.first.refresh.albums.map{|x| x.name}.must_equal %w'B1'

    page.all('select')[0].all('option').map{|s| s.text}.must_equal ["E1"]
    page.all('select')[1].all('option').map{|s| s.text}.must_equal ["B1"]

    select("B1", :from=>"Disassociate From")
    Album.where(:name=>'B1').update(:name=>'Z1')
    proc{click_button "Update"}.must_raise(Sequel::NoMatchingRow)

    visit('/Artist/mtm_edit')
    select("Artist1")
    click_button "Edit"
    select("E1", :from=>"Associate With")
    Album.where(:name=>'E1').update(:name=>'Y1')
    proc{click_button "Update"}.must_raise(Sequel::NoMatchingRow)

    visit('/Artist/mtm_edit')
    select("Artist1")
    click_button "Edit"
    page.all('select')[0].all('option').map{|s| s.text}.must_equal []
    page.all('select')[1].all('option').map{|s| s.text}.must_equal []
  end

  it "should support :remove column option on mtm_edit page" do
    app_setup do
      model Artist do
        mtm_associations :albums
        column_options :albums=>{:as=>:checkbox, :remove=>{:name_method=>proc{|obj| obj.name * 2}}}
      end
      model Album do
        display_name{|obj, req| obj.name + "2"}
      end
    end

    Artist.create(:name=>'Artist1')
    Album.create(:name=>'Album1')
    Album.create(:name=>'Album2')
    Album.create(:name=>'Album3')

    visit("/Artist/mtm_edit")
    select("Artist1")
    click_button "Edit"

    check "Album12"
    click_button "Update"
    Artist.first.albums.map{|x| x.name}.must_equal %w'Album1'

    check "Album1Album1"
    check "Album22"
    check "Album32"
    click_button "Update"
    Artist.first.refresh.albums.map{|x| x.name}.must_equal %w'Album2 Album3'

    check "Album12"
    check "Album2Album2"
    check "Album3Album3"
  end

  it "should support :add column option on mtm_edit page" do
    app_setup do
      model Artist do
        mtm_associations :albums
        column_options :albums=>{:as=>:checkbox, :add=>{:name_method=>proc{|obj| obj.name * 2}}}
      end
      model Album do
        display_name{|obj, req| obj.name + "2"}
      end
    end

    Artist.create(:name=>'Artist1')
    Album.create(:name=>'Album1')
    Album.create(:name=>'Album2')
    Album.create(:name=>'Album3')

    visit("/Artist/mtm_edit")
    select("Artist1")
    click_button "Edit"

    check "Album1Album1"
    click_button "Update"
    Artist.first.albums.map{|x| x.name}.must_equal %w'Album1'

    check "Album12"
    check "Album2Album2"
    check "Album3Album3"
    click_button "Update"
    Artist.first.refresh.albums.map{|x| x.name}.must_equal %w'Album2 Album3'

    check "Album1Album1"
    check "Album22"
    check "Album32"
  end

  it "should support :add column option for inline mtm associations" do
    app_setup do
      model Artist do
        inline_mtm_associations :albums
        column_options :albums=>{:add=>{:name_method=>proc{|obj| obj.name * 2}}}
      end
      model Album
    end

    Artist.create(:name=>'Artist1')
    Album.create(:name=>'Album1')
    Album.create(:name=>'Album2')
    Album.create(:name=>'Album3')

    visit("/Artist/edit")
    select("Artist1")
    click_button "Edit"
    select 'Album1Album1'
    click_button 'Add'
    page.html.must_include 'Updated albums association for Artist'
    Artist.first.albums.map{|x| x.name}.must_equal %w'Album1'

    select 'Album2Album2'
    click_button 'Add'
    Artist.first.refresh.albums.map{|x| x.name}.sort.must_equal %w'Album1 Album2'

    click_button 'Remove', :match=>:first
    Artist.first.refresh.albums.map{|x| x.name}.must_equal %w'Album2'

    select 'Album3Album3'
    click_button 'Add'
  end
end

describe AutoForme do
  before(:all) do
    db_setup(:artists=>proc{primary_key :artist_id; String :name}, :albums=>[[:name, :string]], :albums_artists=>[[:album_id, :integer, {:table=>:albums}], [:artist_id, :integer, {:table=>:artists}]])
    model_setup(:Artist=>[:artists, [[:many_to_many, :albums]]], :Album=>[:albums, [[:many_to_many, :artists]]])
  end
  after(:all) do
    Object.send(:remove_const, :Album)
    Object.send(:remove_const, :Artist)
  end

  it "should have basic many to many association editing working" do
    app_setup do
      model Artist do
        mtm_associations :albums
      end
      model Album
    end

    Artist.create(:name=>'Artist1')
    Album.create(:name=>'Album1')
    Album.create(:name=>'Album2')
    Album.create(:name=>'Album3')

    visit("/Artist/mtm_edit")
    page.title.must_equal 'Artist - Many To Many Edit'
    click_button "Edit"
    select("Artist1")
    click_button "Edit"

    find('h2').text.must_equal 'Edit Albums for Artist1'
    page.all('select')[0].all('option').map{|s| s.text}.must_equal ["Album1", "Album2", "Album3"]
    page.all('select')[1].all('option').map{|s| s.text}.must_equal []
    select("Album1", :from=>"Associate With")
    click_button "Update"
    page.html.must_include 'Updated albums association for Artist'
    Artist.first.albums.map{|x| x.name}.must_equal %w'Album1'

    page.all('select')[0].all('option').map{|s| s.text}.must_equal ["Album2", "Album3"]
    page.all('select')[1].all('option').map{|s| s.text}.must_equal ["Album1"]
    select("Album2", :from=>"Associate With")
    select("Album3", :from=>"Associate With")
    select("Album1", :from=>"Disassociate From")
    click_button "Update"
    Artist.first.refresh.albums.map{|x| x.name}.must_equal %w'Album2 Album3'

    page.all('select')[0].all('option').map{|s| s.text}.must_equal ["Album1"]
    page.all('select')[1].all('option').map{|s| s.text}.must_equal ["Album2", "Album3"]
  end

end

describe AutoForme do
  before(:all) do
    db_setup(:artists=>[[:name, :string]], :albums=>[[:name, :string]], :albums_artists=>[[:album_id, :integer, {:table=>:albums}], [:artist_id, :integer, {:table=>:artists}]])
    model_setup(:Artist=>[:artists, [[:many_to_many, :albums]], [[:many_to_many, :other_albums, {:clone=>:albums}]]], :Album=>[:albums, [[:many_to_many, :artists]]])
  end
  after(:all) do
    Object.send(:remove_const, :Album)
    Object.send(:remove_const, :Artist)
  end

  it "should have basic many to many association editing working" do
    app_setup do
      model Artist do
        mtm_associations [:albums, :other_albums]
      end
      model Album
    end

    Artist.create(:name=>'Artist1')
    Album.create(:name=>'Album1')
    Album.create(:name=>'Album2')
    Album.create(:name=>'Album3')

    visit("/Artist/mtm_edit")
    page.title.must_equal 'Artist - Many To Many Edit'
    select("Artist1")
    click_button "Edit"

    select('albums')
    click_button "Edit"

    find('h2').text.must_equal 'Edit Albums for Artist1'
    page.all('select')[0].all('option').map{|s| s.text}.must_equal ["Album1", "Album2", "Album3"]
    page.all('select')[1].all('option').map{|s| s.text}.must_equal []
    select("Album1", :from=>"Associate With")
    click_button "Update"
    page.html.must_include 'Updated albums association for Artist'
    Artist.first.albums.map{|x| x.name}.must_equal %w'Album1'

    page.all('select')[0].all('option').map{|s| s.text}.must_equal ["Album2", "Album3"]
    page.all('select')[1].all('option').map{|s| s.text}.must_equal ["Album1"]
    select("Album2", :from=>"Associate With")
    select("Album3", :from=>"Associate With")
    select("Album1", :from=>"Disassociate From")
    click_button "Update"
    Artist.first.refresh.albums.map{|x| x.name}.must_equal %w'Album2 Album3'

    page.all('select')[0].all('option').map{|s| s.text}.must_equal ["Album1"]
    page.all('select')[1].all('option').map{|s| s.text}.must_equal ["Album2", "Album3"]
  end
end

describe AutoForme do
  before(:all) do
    db_setup(:artists=>[[:name, :string]], :albums=>[[:name, :string]], :albums_artists=>proc{column :album_id, :integer, :table=>:albums; column :artist_id, :integer, :table=>:artists; primary_key [:album_id, :artist_id]})
    model_setup(:Artist=>[:artists, [[:many_to_many, :albums]]], :Album=>[:albums, [[:many_to_many, :artists]]])
  end
  after(:all) do
    Object.send(:remove_const, :Album)
    Object.send(:remove_const, :Artist)
  end

  it "should handle unique constraint violation errors when adding associated objects" do
    app_setup do
      model Artist do
        mtm_associations :albums
      end
      model Album
    end

    artist = Artist.create(:name=>'Artist1')
    album = Album.create(:name=>'Album1')

    visit("/Artist/mtm_edit")
    page.title.must_equal 'Artist - Many To Many Edit'
    select("Artist1")
    click_button "Edit"

    find('h2').text.must_equal 'Edit Albums for Artist1'
    page.all('select')[0].all('option').map{|s| s.text}.must_equal ["Album1"]
    page.all('select')[1].all('option').map{|s| s.text}.must_equal []
    select("Album1", :from=>"Associate With")
    artist.add_album(album)
    click_button "Update"
    page.html.must_include 'Updated albums association for Artist'
    Artist.first.albums.map{|x| x.name}.must_equal %w'Album1'
  end

  it "should handle unique constraint violation errors when adding associated objects" do
    app_setup do
      model Artist do
        mtm_associations :albums
      end
      model Album
    end

    artist = Artist.create(:name=>'Artist1')
    album = Album.create(:name=>'Album1')
    artist.add_album(album)

    visit("/Artist/mtm_edit")
    page.title.must_equal 'Artist - Many To Many Edit'
    select("Artist1")
    click_button "Edit"

    find('h2').text.must_equal 'Edit Albums for Artist1'
    page.all('select')[0].all('option').map{|s| s.text}.must_equal []
    page.all('select')[1].all('option').map{|s| s.text}.must_equal ["Album1"]
    select("Album1", :from=>"Disassociate From")
    artist.remove_album(album)
    click_button "Update"
    page.html.must_include 'Updated albums association for Artist'
    Artist.first.albums.map{|x| x.name}.must_equal []
  end
end

describe AutoForme do
  before(:all) do
    db_setup(:artists=>[[:name, :string]], :albums=>[[:name, :string]], :albums_artists=>[[:album_id, :integer, {:table=>:albums}], [:artist_id, :integer, {:table=>:artists}]])
    model_setup(:Artist=>[:artists, [[:many_to_many, :albums, :read_only=>true]]], :Album=>[:albums, [[:many_to_many, :artists, :read_only=>true]]])
  end
  after(:all) do
    Object.send(:remove_const, :Album)
    Object.send(:remove_const, :Artist)
  end

  it "should not automatically setup mtm support for read-only associations" do
    app_setup do
      model Artist do
        mtm_associations :all
        association_links :all
      end
      model Album do
        mtm_associations :all
        association_links :all
      end
    end

    visit("/Artist/new")
    page.html.wont_include 'Artist/mtm_edit'
    fill_in 'Name', :with=>'Artist1'
    click_button 'Create'
    click_link 'Edit'
    select 'Artist1'
    click_button 'Edit'
    page.html.must_include 'Albums'
    page.html.wont_include '>associate<'
    visit("/Artist/mtm_edit")
    page.html.must_include 'Unhandled Request'

    visit("/Album/new")
    page.html.wont_include 'Album/mtm_edit'
    fill_in 'Name', :with=>'Album1'
    click_button 'Create'
    click_link 'Edit'
    select 'Album1'
    click_button 'Edit'
    page.html.must_include 'Artists'
    page.html.wont_include '>associate<'
    visit("/Album/mtm_edit")
    page.html.must_include 'Unhandled Request'
  end
end
