require './spec/spec_helper'

describe AutoForme do
  before(:all) do
    db_setup(:artists=>[[:name, :string]])
    model_setup(:Artist=>[:artists])
  end
  after(:all) do
    Object.send(:remove_const, :Artist)
  end

  it "should have basic functionality working in Roda subclass" do
    app_setup(Artist)
    self.app = Class.new(app)
    visit("/Artist/new")
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

    visit("/Artist/browse")
    page.all('td').last.find('a').click
    click_button 'Delete'
    page.title.must_equal 'Artist - Delete'
    page.html.must_include 'Deleted Artist'
    page.current_path.must_equal '/Artist/delete'

    click_link 'Artist'
    page.all('td').map{|s| s.text}.must_equal []
  end
end if ENV['FRAMEWORK'] == 'roda'
