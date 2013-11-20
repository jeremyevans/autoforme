require './spec/spec_helper'

describe AutoForme do
  before(:all) do
    db_setup(:artists=>[[:name, :string]])
    model_setup(:Artist=>[:artists])
  end
  after(:all) do
    Object.send(:remove_const, :Artist)
  end

  before do
    app_setup(Artist)
  end

  it "should handle table class lookup" do
    model.table_class_for(:browse, nil).should == 'table table-bordered table-striped'
    framework.table_class 'foo'
    model.table_class_for(:browse, nil).should == 'foo'
    framework.table_class{|model, type, req| "#{model.name} #{type} #{req}"}
    model.table_class_for(:browse, 1).should == 'Artist browse 1'
    model.table_class 'baz'
    model.table_class_for(:browse, nil).should == 'baz'
    model.table_class{|type, req| "#{type} #{req}"}
    model.table_class_for(:browse, :foo).should == 'browse foo'
  end

  it "should handle per page lookup" do
    model.limit_for(:browse, nil).should == 25
    framework.per_page 1
    model.limit_for(:browse, nil).should == 1
    framework.per_page{|model, type, req| model.name.length + type.to_s.length + req}
    model.limit_for(:browse, 3).should == 15
    model.per_page 3
    model.limit_for(:browse, nil).should == 3
    model.per_page{|type, req| type.to_s.length + req}
    model.limit_for(:browse, -1).should == 5
  end

  it "should handle columns lookup" do
    model.columns_for(:browse, nil).should == [:name]
    framework.columns{|model, type, req| [model.name.to_sym, type, req]}
    model.columns_for(:browse, :foo).should == [:Artist, :browse, :foo]
    model.columns [:foo]
    model.columns_for(:browse, nil).should == [:foo]
    model.columns{|type, req| req ? [type] : [:foo]}
    model.columns_for(:browse, true).should == [:browse]
    model.columns_for(:browse, nil).should == [:foo]
  end

  it "should handle column options lookup" do
    model.column_options_for(:browse, nil, :foo).should == {}
    framework.column_options :foo=>{7=>8}
    model.column_options_for(:browse, :bar, :foo).should == {7=>8}
    framework.column_options :foo=>proc{|type, req| {:type=>type, :req=>req}}
    model.column_options_for(:browse, :bar, :foo).should == {:type=>:browse, :req=>:bar}
    framework.column_options{|model, column, type, req| {model.name.to_sym=>[type, req, column]}}
    model.column_options_for(:browse, :bar, :foo).should == {:Artist=>[:browse, :bar, :foo]}
    framework.column_options{|model, column, type, req| {5=>6}}
    model.column_options :foo=>{1=>2}
    model.column_options_for(:browse, nil, :foo).should == {1=>2, 5=>6}
    model.column_options :foo=>proc{|type, req| {:type=>type, :req=>req}}
    model.column_options_for(:browse, nil, :foo).should == {:type=>:browse, :req=>nil, 5=>6}
    model.column_options{|col, type, req| {:type=>type, :req=>req, :col=>col}}
    model.column_options_for(:browse, nil, :foo).should == {:type=>:browse, :req=>nil, :col=>:foo, 5=>6}
  end

  it "should handle order lookup" do
    model.order_for(:browse, nil).should == nil
    framework.order :bar
    model.order_for(:browse, nil).should == :bar
    framework.order{|model, type, req| [model.name.to_sym, type, req]}
    model.order_for(:browse, :foo).should == [:Artist, :browse, :foo]
    model.order [:foo]
    model.order_for(:browse, nil).should == [:foo]
    model.order{|type, req| [type, req]}
    model.order_for(:browse, :foo).should == [:browse, :foo]
  end

  it "should handle eager lookup" do
    model.eager_for(:browse, nil).should == nil
    model.eager [:foo]
    model.eager_for(:browse, nil).should == [:foo]
    model.eager{|type, req| [type, req]}
    model.eager_for(:browse, 1).should == [:browse, 1]
  end

  it "should handle eager_graph lookup" do
    model.eager_graph_for(:browse, nil).should == nil
    model.eager_graph [:foo]
    model.eager_graph_for(:browse, nil).should == [:foo]
    model.eager_graph{|type, req| [type, req]}
    model.eager_graph_for(:browse, 1).should == [:browse, 1]
  end

  it "should handle filter lookup" do
    model.filter_for.should == nil
    framework.filter{|model| lambda{|ds, type, req| [ds, model.name.to_sym, type, req]}}
    model.filter_for.call(1, :browse, 2).should == [1, :Artist, :browse, 2]
    model.filter{|ds, type, req| [ds, type, req]}
    model.filter_for.call(1, :browse, 2).should == [1, :browse, 2]
  end

  it "should handle display_name lookup" do
    model.display_name_for.should == nil
    framework.display_name :foo
    model.display_name_for.should == :foo
    framework.display_name{|model| model.name.to_sym}
    model.display_name_for.should == :Artist

    framework.display_name{|model| proc{|obj, type, req| "#{obj} #{type} #{req}"}}
    model.object_display_name(:show, 1, :foo).should == 'foo show 1'

    model.display_name :foo
    model.display_name_for.should == :foo
    model.display_name{|obj| obj.to_s}
    model.object_display_name(:show, nil, :foo).should == 'foo'
    model.display_name{|obj, type| "#{obj} #{type}"}
    model.object_display_name(:show, nil, :foo).should == 'foo show'
    model.display_name{|obj, type, req| "#{obj} #{type} #{req}"}
    model.object_display_name(:show, 1, :foo).should == 'foo show 1'
  end

  it "should handle supported_actions lookup" do
    model.supported_action?('new', nil).should be_true
    model.supported_action?('edit', nil).should be_true
    model.supported_action?('search', nil).should be_true
    framework.supported_actions ['new', 'search']
    model.supported_action?('new', nil).should be_true
    model.supported_action?('edit', nil).should be_false
    model.supported_action?('search', nil).should be_true
    framework.supported_actions{|model, req| req ? ['new'] : []}
    model.supported_action?('new', nil).should be_false
    model.supported_action?('new', true).should be_true
    model.supported_actions ['edit', 'search']
    model.supported_action?('new', nil).should be_false
    model.supported_action?('edit', nil).should be_true
    model.supported_action?('search', nil).should be_true
    model.supported_actions{|req| req ? ['new'] : []}
    model.supported_action?('new', nil).should be_false
    model.supported_action?('new', true).should be_true
  end

  it "should handle mtm_associations lookup" do
    model.supported_mtm_edit?('foos', nil).should be_false
    model.supported_mtm_edit?('bars', nil).should be_false
    framework.mtm_associations [:foos]
    model.supported_mtm_edit?('foos', nil).should be_true
    model.supported_mtm_edit?('bars', nil).should be_false
    framework.mtm_associations{|model, req| req ? [:foos] : [:bars]}
    model.supported_mtm_edit?('foos', nil).should be_false
    model.supported_mtm_edit?('bars', nil).should be_true
    model.supported_mtm_edit?('foos', true).should be_true
    model.supported_mtm_edit?('bars', true).should be_false
    model.mtm_associations ['bars']
    model.supported_mtm_edit?('foos', nil).should be_false
    model.supported_mtm_edit?('bars', nil).should be_true
    model.mtm_associations{|req| req ? ['foos'] : ['bars']}
    model.supported_mtm_edit?('foos', nil).should be_false
    model.supported_mtm_edit?('bars', nil).should be_true
    model.supported_mtm_edit?('foos', true).should be_true
    model.supported_mtm_edit?('bars', true).should be_false
  end

  it "should handle inline_mtm_associations lookup" do
    model.supported_mtm_update?('foos', nil).should be_false
    model.supported_mtm_update?('bars', nil).should be_false
    framework.inline_mtm_associations [:foos]
    model.supported_mtm_update?('foos', nil).should be_true
    model.supported_mtm_update?('bars', nil).should be_false
    framework.inline_mtm_associations{|model, req| req ? [:foos] : [:bars]}
    model.supported_mtm_update?('foos', nil).should be_false
    model.supported_mtm_update?('bars', nil).should be_true
    model.supported_mtm_update?('foos', true).should be_true
    model.supported_mtm_update?('bars', true).should be_false
    model.inline_mtm_associations ['bars']
    model.supported_mtm_update?('foos', nil).should be_false
    model.supported_mtm_update?('bars', nil).should be_true
    model.inline_mtm_associations{|req| req ? ['foos'] : ['bars']}
    model.supported_mtm_update?('foos', nil).should be_false
    model.supported_mtm_update?('bars', nil).should be_true
    model.supported_mtm_update?('foos', true).should be_true
    model.supported_mtm_update?('bars', true).should be_false
  end

  it "should handle association_links lookup" do
    model.association_links_for(:show, nil).should == []
    framework.association_links :foo
    model.association_links_for(:show, nil).should == [:foo]
    framework.association_links{|model, type, req| [model.name.to_sym, type, req]}
    model.association_links_for(:show, :foo).should == [:Artist, :show, :foo]
    model.association_links [:bar]
    model.association_links_for(:show, nil).should == [:bar]
    model.show_association_links []
    model.association_links_for(:show, nil).should == []
    model.show_association_links{|type, req| [type, req]}
    model.association_links_for(:show, :foo).should == [:show, :foo]
  end

  it "should handle lazy_load_association_links lookup" do
    model.lazy_load_association_links?(:show, nil).should be_false
    framework.lazy_load_association_links true
    model.lazy_load_association_links?(:show, nil).should be_true
    framework.lazy_load_association_links{|model, type, req| req > 2}
    model.lazy_load_association_links?(:show, 1).should be_false
    model.lazy_load_association_links?(:show, 3).should be_true
    model.lazy_load_association_links false
    model.lazy_load_association_links?(:show, nil).should be_false
    model.lazy_load_association_links{|type, req| req > 2}
    model.lazy_load_association_links?(:show, 1).should be_false
    model.lazy_load_association_links?(:show, 3).should be_true
  end

  it "should handle autocompletion options" do
    model.autocomplete_options({})
    model.autocomplete(:type=>'show', :query=>'foo').should == []
    a = Artist.create(:name=>'FooBar')
    model.autocomplete(:type=>'show', :query=>'foo').should == ["#{a.id} - FooBar"]
    model.autocomplete(:type=>'show', :query=>'boo').should == []
    b = Artist.create(:name=>'BooFar')
    model.autocomplete(:type=>'show', :query=>'boo').should == ["#{b.id} - BooFar"]
    model.autocomplete(:type=>'show', :query=>'oo').sort.should == ["#{a.id} - FooBar", "#{b.id} - BooFar"]

    framework.autocomplete_options :display=>:id
    model.autocomplete(:type=>'show', :query=>'oo').sort.should == ["#{a.id} - #{a.id}", "#{b.id} - #{b.id}"]
    framework.autocomplete_options{|model, type, req| {:limit=>req}}
    model.autocomplete(:type=>'show', :query=>'oo', :request=>1).sort.should == ["#{a.id} - FooBar"]
    model.autocomplete_options :display=>:id
    model.autocomplete(:type=>'show', :query=>'oo', :request=>1).sort.should == ["#{a.id} - #{a.id}"]

    framework.autocomplete_options({})
    model.autocomplete(:type=>'show', :query=>'oo').sort.should == ["#{a.id} - #{a.id}", "#{b.id} - #{b.id}"]
    model.autocomplete_options :display=>proc{:id}
    model.autocomplete(:type=>'show', :query=>'oo').sort.should == ["#{a.id} - #{a.id}", "#{b.id} - #{b.id}"]
    model.autocomplete_options :limit=>1
    model.autocomplete(:type=>'show', :query=>'oo').should == ["#{a.id} - FooBar"]
    model.autocomplete_options :limit=>proc{1}
    model.autocomplete(:type=>'show', :query=>'oo').should == ["#{a.id} - FooBar"]
    model.autocomplete_options :callback=>proc{|ds, opts| ds.reverse_order(:id)}
    model.autocomplete(:type=>'show', :query=>'oo').should == ["#{b.id} - BooFar", "#{a.id} - FooBar"]

    model.autocomplete_options :filter=>proc{|ds, opts| ds.where(:name=>opts[:query])}
    model.autocomplete(:type=>'show', :query=>'foo').should == []
    model.autocomplete(:type=>'show', :query=>'FooBar').should == ["#{a.id} - FooBar"]

    model.autocomplete_options{|type, req| {:limit=>req}}
    model.autocomplete(:type=>'show', :query=>'oo', :request=>1).should == ["#{a.id} - FooBar"]
  end
end

describe AutoForme do
  before(:all) do
    db_setup(:artists=>[[:name, :string]], :albums=>[[:name, :string], [:artist_id, :integer, {:table=>:artists}]])
    model_setup(:Artist=>[:artists, [[:one_to_many, :albums]]], :Album=>[:albums, [[:many_to_one, :artist]]])
  end
  after(:all) do
    Object.send(:remove_const, :Album)
    Object.send(:remove_const, :Artist)
  end

  it "should handle autocompletion options with associations" do
    artist = nil
    model = nil
    app_setup do
      model Artist do
        artist = self
      end
      model Album do
        model = self
        columns [:name, :artist]
      end
    end

    artist.autocomplete_options({})
    model.autocomplete(:type=>'show', :query=>'foo', :association=>'artist').should == []
    a = Artist.create(:name=>'FooBar')
    model.autocomplete(:type=>'show', :query=>'foo', :association=>'artist').should == ["#{a.id} - FooBar"]
    model.autocomplete(:type=>'show', :query=>'boo', :association=>'artist').should == []
    b = Artist.create(:name=>'BooFar')
    model.autocomplete(:type=>'show', :query=>'boo', :association=>'artist').should == ["#{b.id} - BooFar"]
    model.autocomplete(:type=>'show', :query=>'oo', :association=>'artist').sort.should == ["#{a.id} - FooBar", "#{b.id} - BooFar"]
    artist.autocomplete_options :display=>:id
    model.autocomplete(:type=>'show', :query=>'oo', :association=>'artist').sort.should == ["#{a.id} - #{a.id}", "#{b.id} - #{b.id}"]
    artist.autocomplete_options :display=>proc{:id}
    model.autocomplete(:type=>'show', :query=>'oo', :association=>'artist').sort.should == ["#{a.id} - #{a.id}", "#{b.id} - #{b.id}"]
    artist.autocomplete_options :limit=>1
    model.autocomplete(:type=>'show', :query=>'oo', :association=>'artist').should == ["#{a.id} - FooBar"]
    artist.autocomplete_options :limit=>proc{1}
    model.autocomplete(:type=>'show', :query=>'oo', :association=>'artist').should == ["#{a.id} - FooBar"]
    artist.autocomplete_options :callback=>proc{|ds, opts| ds.reverse_order(:id)}
    model.autocomplete(:type=>'show', :query=>'oo', :association=>'artist').should == ["#{b.id} - BooFar", "#{a.id} - FooBar"]

    artist.autocomplete_options :filter=>proc{|ds, opts| ds.where(:name=>opts[:query])}
    model.autocomplete(:type=>'show', :query=>'foo', :association=>'artist').should == []
    model.autocomplete(:type=>'show', :query=>'FooBar', :association=>'artist').should == ["#{a.id} - FooBar"]
  end
end

describe AutoForme do
  before(:all) do
    db_setup(:artists=>[[:name, :string]], :albums=>[[:name, :string]], :albums_artists=>[[:album_id, :integer, {:table=>:albums}], [:artist_id, :integer, {:table=>:artists}]])
    model_setup(:Artist=>[:artists, [[:many_to_many, :albums]]], :Album=>[:albums, [[:many_to_many, :artists]]])
  end
  after(:all) do
    Object.send(:remove_const, :Album)
    Object.send(:remove_const, :Artist)
  end

  it "should handle autocompletion options with many to many exclusions" do
    artist = nil
    model = nil
    app_setup do
      model Artist do
        artist = self
      end
      model Album do
        model = self
      end
    end

    artist.autocomplete_options({})
    model.autocomplete(:type=>'show', :query=>'foo', :association=>'artists').should == []
    a = Artist.create(:name=>'FooBar')
    model.autocomplete(:type=>'show', :query=>'foo', :association=>'artists').should == ["#{a.id} - FooBar"]
    model.autocomplete(:type=>'show', :query=>'boo', :association=>'artists').should == []
    b = Artist.create(:name=>'BooFar')
    model.autocomplete(:type=>'show', :query=>'boo', :association=>'artists').should == ["#{b.id} - BooFar"]
    model.autocomplete(:type=>'show', :query=>'oo', :association=>'artists').sort.should == ["#{a.id} - FooBar", "#{b.id} - BooFar"]
    c = Album.create(:name=>'Quux')
    c.add_artist(a)
    model.autocomplete(:type=>'show', :query=>'oo', :association=>'artists', :exclude=>c.id).sort.should == ["#{b.id} - BooFar"]
    artist.autocomplete_options :display=>:id
    model.autocomplete(:type=>'show', :query=>'oo', :association=>'artists').sort.should == ["#{a.id} - #{a.id}", "#{b.id} - #{b.id}"]
    model.autocomplete(:type=>'show', :query=>'oo', :association=>'artists', :exclude=>c.id).sort.should == ["#{b.id} - #{b.id}"]
    artist.autocomplete_options :display=>proc{:id}
    model.autocomplete(:type=>'show', :query=>'oo', :association=>'artists').sort.should == ["#{a.id} - #{a.id}", "#{b.id} - #{b.id}"]
    model.autocomplete(:type=>'show', :query=>'oo', :association=>'artists', :exclude=>c.id).sort.should == ["#{b.id} - #{b.id}"]
    artist.autocomplete_options :limit=>1
    model.autocomplete(:type=>'show', :query=>'oo', :association=>'artists').should == ["#{a.id} - FooBar"]
    model.autocomplete(:type=>'show', :query=>'oo', :association=>'artists', :exclude=>c.id).should == ["#{b.id} - BooFar"]
    artist.autocomplete_options :limit=>proc{1}
    model.autocomplete(:type=>'show', :query=>'oo', :association=>'artists').should == ["#{a.id} - FooBar"]
    model.autocomplete(:type=>'show', :query=>'oo', :association=>'artists', :exclude=>c.id).should == ["#{b.id} - BooFar"]
    artist.autocomplete_options :callback=>proc{|ds, opts| ds.reverse_order(:id)}
    model.autocomplete(:type=>'show', :query=>'oo', :association=>'artists').should == ["#{b.id} - BooFar", "#{a.id} - FooBar"]
    model.autocomplete(:type=>'show', :query=>'oo', :association=>'artists', :exclude=>c.id).should == ["#{b.id} - BooFar"]

    artist.autocomplete_options :filter=>proc{|ds, opts| ds.where(:name=>opts[:query])}
    model.autocomplete(:type=>'show', :query=>'foo', :association=>'artists').should == []
    model.autocomplete(:type=>'show', :query=>'FooBar', :association=>'artists').should == ["#{a.id} - FooBar"]
    model.autocomplete(:type=>'show', :query=>'FooBar', :association=>'artists', :exclude=>c.id).should == []
  end
end


describe AutoForme::OptsAttributes do
  before do
    @c = Class.new do
      extend AutoForme::OptsAttributes 
      opts_attribute :foo
      opts_attribute :bar, %w'baz'
      attr_accessor :opts
    end
    @o = @c.new
    @o.opts = {}
  end

  it "should act as a getter if given no arguments, and setter if given arguments or a block" do
    @o.foo.should be_nil
    @o.foo(1).should == 1
    @o.foo.should == 1
    p = proc{}
    @o.foo(&p).should == p
    @o.foo.should == p
  end

  it "should should raise an error if given more than one argument" do
    proc{@o.foo(1, 2)}.should raise_error(ArgumentError)
  end

  it "should should raise an error if given block and argument" do
    proc{@o.foo(1){}}.should raise_error(ArgumentError)
  end

  it "should create methods for the prefixes given" do
    @o.baz_bar.should be_nil
    @o.baz_bar(1).should == 1
    @o.bar.should be_nil
    @o.bar(1).should == 1
  end

  it "should have prefix methods default to calling base method" do
    @o.bar(1)
    @o.baz_bar.should == 1
  end

  it "should accept a block specifying a default for the base method" do
    @c.opts_attribute(:q, %w'b'){1}
    @o.q.should == 1
    @o.b_q.should == 1
  end
end
