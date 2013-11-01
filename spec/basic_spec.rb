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
    all('td').map{|s| s.text}.should == ["TestArtistUpdate", "Show", "Edit", ""]
    all('td').last.find('input')[:value].should == 'Delete'

    click_link 'Artist'
    all('td').map{|s| s.text}.should == ["TestArtistUpdate", "Show", "Edit", ""]
    all('td').last.find('input')[:value].should == 'Delete'

    click_link 'Delete'
    select 'TestArtistUpdate'
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
    page.body.should_not =~ /N5/i
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
    page.body.should_not =~ /[VN]4/i
    fill_in 'N5', :with=>'Q5'
    click_button 'Update'

    click_link 'Search'
    fill_in 'N0', :with=>'Q0'
    page.body.should_not =~ /[QN]1/i
    fill_in 'N2', :with=>'Q2'
    fill_in 'N3', :with=>'Q3'
    fill_in 'N4', :with=>'V4'
    fill_in 'N5', :with=>'Q5'
    click_button 'Search'
    all('td').map{|s| s.text}.should == ["Q1", "Q2", "Q3", "V4", "Q5", "Show", "Edit", ""]

    click_link 'Artist'
    all('td').map{|s| s.text}.should == ["Q0", "Q1", "Q3", "V4", "Q5", "Show", "Edit", ""]
  end
end
