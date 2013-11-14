require './spec/spec_helper'

describe AutoForme do
  before(:all) do
    db_setup(:artists=>[[:name, :string]], :albums=>[[:name, :string]], :albums_artists=>[[:album_id, :integer, {:table=>:albums}], [:artist_id, :integer, {:table=>:artists}]])
    model_setup(:Artist=>[:artists, [[:many_to_many, :albums]]], :Album=>[:albums, [[:many_to_many, :artists]]])
  end
  after(:all) do
    Object.send(:remove_const, :Album)
    Object.send(:remove_const, :Artist)
  end

  it "should have basic many to many association editing working" do
    app_setup do
      autoforme Artist do
        mtm_associations :albums
      end
      autoforme Album
    end

    Artist.create(:name=>'Artist1')
    Album.create(:name=>'Album1')
    Album.create(:name=>'Album2')
    Album.create(:name=>'Album3')

    visit("/Artist/mtm_edit")
    select("Artist1")
    click_button "Edit"

    select("albums")
    click_button "Edit"

    all('select')[0].all('option').map{|s| s.text}.should == ["Album1", "Album2", "Album3"]
    all('select')[1].all('option').map{|s| s.text}.should == []
    select("Album1", :from=>"Associate With")
    click_button "Update"
    page.html.should =~ /Updated albums association for Artist/
    Artist.first.albums.map{|x| x.name}.should == %w'Album1'

    all('select')[0].all('option').map{|s| s.text}.should == ["Album2", "Album3"]
    all('select')[1].all('option').map{|s| s.text}.should == ["Album1"]
    select("Album2", :from=>"Associate With")
    select("Album3", :from=>"Associate With")
    select("Album1", :from=>"Disassociate From")
    click_button "Update"
    Artist.first.refresh.albums.map{|x| x.name}.should == %w'Album2 Album3'

    all('select')[0].all('option').map{|s| s.text}.should == ["Album1"]
    all('select')[1].all('option').map{|s| s.text}.should == ["Album2", "Album3"]
  end

  it "should have working many to many association links on show and edit pages" do
    app_setup do
      autoforme Artist do
        mtm_associations :albums
        association_links [:albums]
      end
      autoforme Album do
        mtm_associations [:artists]
        association_links :artists
      end
    end

    visit("/Artist/new")
    fill_in 'Name', :with=>'Artist1'
    click_button 'Create'

    click_link 'Edit'
    select 'Artist1'
    click_button 'Edit'
    click_link 'Albums'
    click_link 'New'
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
    page.current_path.should =~ %r{Artist/show/\d+}
    click_link 'Album1'
    page.current_path.should =~ %r{Album/show/\d+}
  end

  it "should have many to many association editing working when associated class is not using autoforme" do
    app_setup do
      autoforme Artist do
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

    select("albums")
    click_button "Edit"

    all('select')[0].all('option').map{|s| s.text}.should == ["Album1", "Album2", "Album3"]
    all('select')[1].all('option').map{|s| s.text}.should == []
    select("Album1", :from=>"Associate With")
    click_button "Update"
    Artist.first.refresh.albums.map{|x| x.name}.should == %w'Album1'

    all('select')[0].all('option').map{|s| s.text}.should == ["Album2", "Album3"]
    all('select')[1].all('option').map{|s| s.text}.should == ["Album1"]
    select("Album2", :from=>"Associate With")
    select("Album3", :from=>"Associate With")
    select("Album1", :from=>"Disassociate From")
    click_button "Update"
    Artist.first.refresh.albums.map{|x| x.name}.should == %w'Album2 Album3'

    all('select')[0].all('option').map{|s| s.text}.should == ["Album1"]
    all('select')[1].all('option').map{|s| s.text}.should == ["Album2", "Album3"]
  end

  it "should use filter/order from associated class" do
    app_setup do
      autoforme Artist do
        mtm_associations :all
      end
      autoforme Album do
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
    select("albums")
    click_button "Edit"

    all('select')[0].all('option').map{|s| s.text}.should == ["B1", "E1"]
    all('select')[1].all('option').map{|s| s.text}.should == []
    select("E1", :from=>"Associate With")
    click_button "Update"
    Artist.first.albums.map{|x| x.name}.should == %w'E1'

    all('select')[0].all('option').map{|s| s.text}.should == ["B1"]
    all('select')[1].all('option').map{|s| s.text}.should == ["E1"]
    select("B1", :from=>"Associate With")
    select("E1", :from=>"Disassociate From")
    click_button "Update"
    Artist.first.refresh.albums.map{|x| x.name}.should == %w'B1'

    all('select')[0].all('option').map{|s| s.text}.should == ["E1"]
    all('select')[1].all('option').map{|s| s.text}.should == ["B1"]

    select("B1", :from=>"Disassociate From")
    Album.where(:name=>'B1').update(:name=>'Z1')
    proc{click_button "Update"}.should raise_error(Sequel::NoMatchingRow)

    visit('/Artist/mtm_edit')
    select("Artist1")
    click_button "Edit"
    select("albums")
    click_button "Edit"
    select("E1", :from=>"Associate With")
    Album.where(:name=>'E1').update(:name=>'Y1')
    proc{click_button "Update"}.should raise_error(Sequel::NoMatchingRow)

    visit('/Artist/mtm_edit')
    select("Artist1")
    click_button "Edit"
    select("albums")
    click_button "Edit"
    all('select')[0].all('option').map{|s| s.text}.should == []
    all('select')[1].all('option').map{|s| s.text}.should == []
  end

  it "should support column options on mtm_edit page" do
    app_setup do
      autoforme Artist do
        mtm_associations :albums
        mtm_edit_column_options :albums=>{:as=>:checkbox, :remove=>{:name_method=>proc{|obj| obj.name * 2}}}
      end
      autoforme Album do
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

    select("albums")
    click_button "Edit"

    check "Album12"
    click_button "Update"
    Artist.first.albums.map{|x| x.name}.should == %w'Album1'

    check "Album1Album1"
    check "Album22"
    check "Album32"
    click_button "Update"
    Artist.first.refresh.albums.map{|x| x.name}.should == %w'Album2 Album3'

    check "Album12"
    check "Album2Album2"
    check "Album3Album3"
  end
end
