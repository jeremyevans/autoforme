require './spec/spec_helper'

describe AutoForme do
  before(:all) do
    db_setup(:artists=>[[:name, :string]])
    model_setup(:Artist=>[:artists])
    app_setup(Artist)
  end
  after(:all) do
    Object.remove_const(:Artist)
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
