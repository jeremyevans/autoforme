require './spec/spec_helper'

describe AutoForme do
  before(:all) do
    db_setup(:artists=>[[:name, :string]])
    model_setup(:Artist=>[:artists])
    app_setup(Artist)
  end
  after(:all) do
    Object.send(:remove_const, :Artist)
  end

  it "should have basic functionality working" do
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
    cols = Artist.columns - [:id]
    app_setup(Artist) do
      new_columns(cols - [:n5])
      edit_columns(cols - [:n4])
      show_columns(cols - [:n3])
      browse_columns(cols - [:n2])
      search_columns(cols - [:n1])
    end
  end
  after(:all) do
    Object.send(:remove_const, :Artist)
  end

  it "should support different columns per action type" do
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
    all('td').map{|s| s.text}.should == ["Q0", "Q2", "Q3", "V4", "Q5", "Show", "Edit", ""]

    click_link 'Artist'
    all('td').map{|s| s.text}.should == ["Q0", "Q1", "Q3", "V4", "Q5", "Show", "Edit", ""]
  end
end
