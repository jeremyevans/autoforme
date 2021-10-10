require_relative 'spec_helper'

describe AutoForme do
  before(:all) do
    db_setup(:artists=>[[:name, :string]])
    model_setup(:Artist=>[:artists])
  end
  after(:all) do
    Object.send(:remove_const, :Artist)
  end

  it "should support erb_options" do
    app_setup(Artist, erb_options: {:layout => "<h1>Change Layout</h1><%= yield %>"}) do
    end
    visit("/Artist/browse")
    page.html.must_include '<h1>Change Layout</h1>'
    page.all('table').first['id'].must_equal 'autoforme_table'
  end

end
