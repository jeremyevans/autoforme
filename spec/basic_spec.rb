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
    fill_in 'Name', :with=>'TestArtistNew'
    click_button 'Create'
    page.current_path.should == '/Artist/new'

    click_link 'Show'
    select 'TestArtistNew'
    click_button 'Show'
    page.html.should =~ /Name.+TestArtistNew/m

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
    all('td').map{|s| s.text}.should == ["TestArtistUpdate", "Show", "Edit", "Delete"]

    click_link 'Artist'
    all('td').map{|s| s.text}.should == ["TestArtistUpdate", "Show", "Edit", "Delete"]

    all('td').last.find('a').click
    click_button 'Delete'
    page.current_path.should == '/Artist/delete'

    click_link 'Artist'
    all('td').map{|s| s.text}.should == []
  end

  it "should support specifying table class for data tables per type" do
    app_setup(Artist) do
      browse_table_class 'foo'
      search_table_class 'bar'
    end
    visit("/Artist/browse")
    first('table')['class'].should == 'foo'
    click_link 'Search'
    click_button 'Search'
    first('table')['class'].should == 'bar'
  end

  it "should support specifying numbers of rows per page per type" do
    app_setup(Artist) do
      browse_per_page 2
      search_per_page 3
    end
    5.times{|i| Artist.create(:name=>i.to_s)}
    visit("/Artist/browse")
    first('li.disabled a').text.should == 'Previous'
    all('tr td:first-child').map{|s| s.text}.should == %w'0 1'
    click_link 'Next'
    all('tr td:first-child').map{|s| s.text}.should == %w'2 3'
    click_link 'Next'
    all('tr td:first-child').map{|s| s.text}.should == %w'4'
    first('li.disabled a').text.should == 'Next'
    click_link 'Previous'
    all('tr td:first-child').map{|s| s.text}.should == %w'2 3'
    click_link 'Previous'
    all('tr td:first-child').map{|s| s.text}.should == %w'0 1'
    first('li.disabled a').text.should == 'Previous'

    click_link 'Search'
    click_button 'Search'
    all('tr td:first-child').map{|s| s.text}.should == %w'0 1 2'
    click_link 'Next'
    all('tr td:first-child').map{|s| s.text}.should == %w'3 4'
    first('li.disabled a').text.should == 'Next'
    click_link 'Previous'
    all('tr td:first-child').map{|s| s.text}.should == %w'0 1 2'
    first('li.disabled a').text.should == 'Previous'
  end

  it "should support specifying supported actions" do
    app_setup(Artist) do
      supported_actions %w'new edit browse search'
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
    all('td').map{|s| s.text}.should == ["TestArtistUpdate", "Edit"]

    click_link 'Artist'
    all('td').map{|s| s.text}.should == ["TestArtistUpdate", "Edit"]
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
    app_setup(Artist) do
      new_columns(cols - [:n5])
      edit_columns(cols - [:n4])
      show_columns(cols - [:n3])
      browse_columns(cols - [:n2])
      search_form_columns(cols - [:n1])
      search_columns(cols - [:n0])
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
    all('td').map{|s| s.text}.should == ["Q1", "Q2", "Q3", "V4", "Q5", "Show", "Edit", "Delete"]

    click_link 'Artist'
    all('td').map{|s| s.text}.should == ["Q0", "Q1", "Q3", "V4", "Q5", "Show", "Edit", "Delete"]
  end

  it "should support specifying order per type" do
    app_setup(Artist) do
      edit_order :n0
      show_order [:n1, :n2]
      delete_order :n3
      browse_order [:n1, :n0]
      search_order :n4
    end

    Artist.create(:n0=>'1', :n1=>'2', :n2=>'3', :n3=>'7', :n4=>'5')
    Artist.create(:n0=>'2', :n1=>'2', :n2=>'1', :n3=>'3', :n4=>'4')
    Artist.create(:n0=>'0', :n1=>'4', :n2=>'1', :n3=>'5', :n4=>'3')

    visit("/Artist/show")
    all('option').map{|s| s.text}.should == %w'2 1 0'

    click_link 'Edit'
    all('option').map{|s| s.text}.should == %w'0 1 2'

    click_link 'Delete'
    all('option').map{|s| s.text}.should == %w'2 0 1'

    click_link 'Search'
    click_button 'Search'
    all('tr td:first-child').map{|s| s.text}.should == %w'0 2 1'

    click_link 'Artist'
    all('tr td:first-child').map{|s| s.text}.should == %w'1 2 0'
  end

  it "should support specifying filter per type" do
    app_setup(Artist) do
      edit_filter{|ds, action| ds.where{n0 > 1}}
      show_filter{|ds, action| ds.where{n1 > 3}}
      delete_filter{|ds, action| ds.where{n2 > 2}}
      browse_filter{|ds, action| ds.where{n3 > 6}}
      search_filter{|ds, action| ds.where{n4 > 4}}
    end

    Artist.create(:n0=>'1', :n1=>'2', :n2=>'3', :n3=>'7', :n4=>'5')
    Artist.create(:n0=>'2', :n1=>'2', :n2=>'1', :n3=>'3', :n4=>'4')
    Artist.create(:n0=>'0', :n1=>'4', :n2=>'1', :n3=>'5', :n4=>'3')

    visit("/Artist/show")
    all('option').map{|s| s.text}.should == %w'0'

    click_link 'Edit'
    all('option').map{|s| s.text}.should == %w'2'
    select '2'
    click_button 'Edit'
    click_button 'Update'

    click_link 'Delete'
    all('option').map{|s| s.text}.should == %w'1'
    click_button 'Delete'
    Artist.create(:n0=>'1', :n1=>'2', :n2=>'3', :n3=>'7', :n4=>'5')

    click_link 'Search'
    click_button 'Search'
    all('tr td:first-child').map{|s| s.text}.should == %w'1'

    click_link 'Artist'
    all('tr td:first-child').map{|s| s.text}.should == %w'1'
  end

  it "should support specifying filter per type using request params" do
    app_setup(Artist) do
      edit_filter{|ds, action| ds.where{n0 > action.request.params[:f]}}
      show_filter{|ds, action| ds.where{n1 > action.request.params[:f]}}
      delete_filter{|ds, action| ds.where{n2 > action.request.params[:f]}}
      browse_filter{|ds, action| ds.where{n3 > action.request.params[:f]}}
      search_filter{|ds, action| ds.where{n4 > action.request.params[:f]}}
    end

    Artist.create(:n0=>'1', :n1=>'2', :n2=>'3', :n3=>'7', :n4=>'5')
    Artist.create(:n0=>'2', :n1=>'2', :n2=>'1', :n3=>'3', :n4=>'4')
    Artist.create(:n0=>'0', :n1=>'4', :n2=>'1', :n3=>'5', :n4=>'3')

    visit("/Artist/show?f=3")
    all('option').map{|s| s.text}.should == %w'0'

    visit("/Artist/edit?f=1")
    all('option').map{|s| s.text}.should == %w'2'

    visit("/Artist/delete?f=2")
    all('option').map{|s| s.text}.should == %w'1'

    visit("/Artist/search/1?f=4")
    all('tr td:first-child').map{|s| s.text}.should == %w'1'

    visit("/Artist/browse?f=6")
    all('tr td:first-child').map{|s| s.text}.should == %w'1'
  end

  it "should support specifying filter per type using request session" do
    app_setup(Artist) do
      filter{|ds, action| ds.where(:n1=>action.request.session['n1'])}
      order :n2
    end

    Artist.create(:n0=>'1', :n1=>'2', :n2=>'3', :n3=>'7', :n4=>'5')
    Artist.create(:n0=>'2', :n1=>'2', :n2=>'1', :n3=>'3', :n4=>'4')
    Artist.create(:n0=>'0', :n1=>'4', :n2=>'1', :n3=>'5', :n4=>'3')
    visit '/session/set?n1=2'

    visit("/Artist/show")
    all('option').map{|s| s.text}.should == %w'2 1'

    click_link 'Edit'
    all('option').map{|s| s.text}.should == %w'2 1'
    select '2'
    click_button 'Edit'
    click_button 'Update'

    click_link 'Delete'
    all('option').map{|s| s.text}.should == %w'2 1'
    select '1'
    click_button 'Delete'
    Artist.create(:n0=>'1', :n1=>'2', :n2=>'3', :n3=>'7', :n4=>'5')

    click_link 'Search'
    click_button 'Search'
    all('tr td:first-child').map{|s| s.text}.should == %w'2 1'

    click_link 'Artist'
    all('tr td:first-child').map{|s| s.text}.should == %w'2 1'
  end
end
