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
    model.table_class_for(:browse, nil).must_equal 'table table-bordered table-striped'
    framework.table_class 'foo'
    model.table_class_for(:browse, nil).must_equal 'foo'
    framework.table_class{|mod, type, req| "#{mod.name} #{type} #{req}"}
    model.table_class_for(:browse, 1).must_equal 'Artist browse 1'
    model.table_class 'baz'
    model.table_class_for(:browse, nil).must_equal 'baz'
    model.table_class{|type, req| "#{type} #{req}"}
    model.table_class_for(:browse, :foo).must_equal 'browse foo'
  end

  it "should handle per page lookup" do
    model.limit_for(:browse, nil).must_equal 25
    framework.per_page 1
    model.limit_for(:browse, nil).must_equal 1
    framework.per_page{|mod, type, req| mod.name.length + type.to_s.length + req}
    model.limit_for(:browse, 3).must_equal 15
    model.per_page 3
    model.limit_for(:browse, nil).must_equal 3
    model.per_page{|type, req| type.to_s.length + req}
    model.limit_for(:browse, -1).must_equal 5
  end

  it "should handle columns lookup" do
    model.columns_for(:browse, nil).must_equal [:name]
    framework.columns{|mod, type, req| [mod.name.to_sym, type, req]}
    model.columns_for(:browse, :foo).must_equal [:Artist, :browse, :foo]
    model.columns [:foo]
    model.columns_for(:browse, nil).must_equal [:foo]
    model.columns{|type, req| req ? [type] : [:foo]}
    model.columns_for(:browse, true).must_equal [:browse]
    model.columns_for(:browse, nil).must_equal [:foo]
  end

  it "should handle column options lookup" do
    model.column_options_for(:show, nil, :foo).must_equal(:required=>false)
    model.column_options_for(:browse, nil, :foo).must_equal({})
    framework.column_options :foo=>{:as=>:textarea}
    model.column_options_for(:browse, :bar, :foo).must_equal(:as=>:textarea)
    model.column_options_for(:search_form, nil, :foo).must_equal(:required=>false)
    framework.column_options :foo=>proc{|type, req| {:type=>type, :req=>req}}
    model.column_options_for(:browse, :bar, :foo).must_equal(:type=>:browse, :req=>:bar)
    framework.column_options{|mod, column, type, req| {mod.name.to_sym=>[type, req, column]}}
    model.column_options_for(:browse, :bar, :foo).must_equal(:Artist=>[:browse, :bar, :foo])
    framework.column_options{|mod, column, type, req| {5=>6}}
    model.column_options :foo=>{1=>2}
    model.column_options_for(:browse, nil, :foo).must_equal(1=>2, 5=>6)
    model.column_options :foo=>proc{|type, req| {:type=>type, :req=>req}}
    model.column_options_for(:browse, nil, :foo).must_equal(:type=>:browse, :req=>nil, 5=>6)
    model.column_options{|col, type, req| {:type=>type, :req=>req, :col=>col}}
    model.column_options_for(:browse, nil, :foo).must_equal(:type=>:browse, :req=>nil, :col=>:foo, 5=>6)
  end

  it "should handle order lookup" do
    model.order_for(:browse, nil).must_equal nil
    framework.order :bar
    model.order_for(:browse, nil).must_equal :bar
    framework.order{|mod, type, req| [mod.name.to_sym, type, req]}
    model.order_for(:browse, :foo).must_equal [:Artist, :browse, :foo]
    model.order [:foo]
    model.order_for(:browse, nil).must_equal [:foo]
    model.order{|type, req| [type, req]}
    model.order_for(:browse, :foo).must_equal [:browse, :foo]
  end

  it "should handle eager lookup" do
    model.eager_for(:browse, nil).must_equal nil
    model.eager [:foo]
    model.eager_for(:browse, nil).must_equal [:foo]
    model.eager{|type, req| [type, req]}
    model.eager_for(:browse, 1).must_equal [:browse, 1]
  end

  it "should handle eager_graph lookup" do
    model.eager_graph_for(:browse, nil).must_equal nil
    model.eager_graph [:foo]
    model.eager_graph_for(:browse, nil).must_equal [:foo]
    model.eager_graph{|type, req| [type, req]}
    model.eager_graph_for(:browse, 1).must_equal [:browse, 1]
  end

  it "should handle filter lookup" do
    model.filter_for.must_equal nil
    framework.filter{|mod| lambda{|ds, type, req| [ds, mod.name.to_sym, type, req]}}
    model.filter_for.call(1, :browse, 2).must_equal [1, :Artist, :browse, 2]
    model.filter{|ds, type, req| [ds, type, req]}
    model.filter_for.call(1, :browse, 2).must_equal [1, :browse, 2]
  end

  it "should handle redirect lookup" do
    model.redirect_for.must_equal nil
    framework.redirect{|mod| lambda{|obj, type, req| [obj, mod.name.to_sym, type, req]}}
    model.redirect_for.call(1, :new, 2).must_equal [1, :Artist, :new, 2]
    model.redirect{|obj, type, req| [obj, type, req]}
    model.redirect_for.call(1, :new, 2).must_equal [1, :new, 2]
  end

  it "should handle display_name lookup" do
    model.display_name_for.must_equal nil
    framework.display_name :foo
    model.display_name_for.must_equal :foo
    framework.display_name{|mod| mod.name.to_sym}
    model.display_name_for.must_equal :Artist

    framework.display_name{|mod| proc{|obj, type, req| "#{obj} #{type} #{req}"}}
    model.object_display_name(:show, 1, :foo).must_equal 'foo show 1'

    model.display_name :foo
    model.display_name_for.must_equal :foo
    model.display_name{|obj| obj.to_s}
    model.object_display_name(:show, nil, :foo).must_equal 'foo'
    model.display_name{|obj, type| "#{obj} #{type}"}
    model.object_display_name(:show, nil, :foo).must_equal 'foo show'
    model.display_name{|obj, type, req| "#{obj} #{type} #{req}"}
    model.object_display_name(:show, 1, :foo).must_equal 'foo show 1'
  end

  it "should handle supported_actions lookup" do
    model.supported_action?(:new, nil).must_equal true
    model.supported_action?(:edit, nil).must_equal true
    model.supported_action?(:search, nil).must_equal true
    framework.supported_actions [:new, :search]
    model.supported_action?(:new, nil).must_equal true
    model.supported_action?(:edit, nil).must_equal false
    model.supported_action?(:search, nil).must_equal true
    framework.supported_actions{|mod, req| req ? [:new] : []}
    model.supported_action?(:new, nil).must_equal false
    model.supported_action?(:new, true).must_equal true
    model.supported_actions [:edit, :search]
    model.supported_action?(:new, nil).must_equal false
    model.supported_action?(:edit, nil).must_equal true
    model.supported_action?(:search, nil).must_equal true
    model.supported_actions{|req| req ? [:new] : []}
    model.supported_action?(:new, nil).must_equal false
    model.supported_action?(:new, true).must_equal true
  end

  it "should handle mtm_associations lookup" do
    model.supported_mtm_edit?('foos', nil).must_equal false
    model.supported_mtm_edit?('bars', nil).must_equal false
    framework.mtm_associations [:foos]
    model.supported_mtm_edit?('foos', nil).must_equal true
    model.supported_mtm_edit?('bars', nil).must_equal false
    framework.mtm_associations{|mod, req| req ? [:foos] : [:bars]}
    model.supported_mtm_edit?('foos', nil).must_equal false
    model.supported_mtm_edit?('bars', nil).must_equal true
    model.supported_mtm_edit?('foos', true).must_equal true
    model.supported_mtm_edit?('bars', true).must_equal false
    model.mtm_associations ['bars']
    model.supported_mtm_edit?('foos', nil).must_equal false
    model.supported_mtm_edit?('bars', nil).must_equal true
    model.mtm_associations{|req| req ? ['foos'] : ['bars']}
    model.supported_mtm_edit?('foos', nil).must_equal false
    model.supported_mtm_edit?('bars', nil).must_equal true
    model.supported_mtm_edit?('foos', true).must_equal true
    model.supported_mtm_edit?('bars', true).must_equal false
  end

  it "should handle inline_mtm_associations lookup" do
    model.supported_mtm_update?('foos', nil).must_equal false
    model.supported_mtm_update?('bars', nil).must_equal false
    framework.inline_mtm_associations [:foos]
    model.supported_mtm_update?('foos', nil).must_equal true
    model.supported_mtm_update?('bars', nil).must_equal false
    framework.inline_mtm_associations{|mod, req| req ? [:foos] : [:bars]}
    model.supported_mtm_update?('foos', nil).must_equal false
    model.supported_mtm_update?('bars', nil).must_equal true
    model.supported_mtm_update?('foos', true).must_equal true
    model.supported_mtm_update?('bars', true).must_equal false
    model.inline_mtm_associations ['bars']
    model.supported_mtm_update?('foos', nil).must_equal false
    model.supported_mtm_update?('bars', nil).must_equal true
    model.inline_mtm_associations{|req| req ? ['foos'] : ['bars']}
    model.supported_mtm_update?('foos', nil).must_equal false
    model.supported_mtm_update?('bars', nil).must_equal true
    model.supported_mtm_update?('foos', true).must_equal true
    model.supported_mtm_update?('bars', true).must_equal false
  end

  it "should handle association_links lookup" do
    model.association_links_for(:show, nil).must_equal []
    framework.association_links :foo
    model.association_links_for(:show, nil).must_equal [:foo]
    framework.association_links{|mod, type, req| [mod.name.to_sym, type, req]}
    model.association_links_for(:show, :foo).must_equal [:Artist, :show, :foo]
    model.association_links [:bar]
    model.association_links_for(:show, nil).must_equal [:bar]
    model.association_links{|type, req| [type, req]}
    model.association_links_for(:show, :foo).must_equal [:show, :foo]
  end

  it "should handle lazy_load_association_links lookup" do
    model.lazy_load_association_links?(:show, nil).must_equal false
    framework.lazy_load_association_links true
    model.lazy_load_association_links?(:show, nil).must_equal true
    framework.lazy_load_association_links{|mod, type, req| req > 2}
    model.lazy_load_association_links?(:show, 1).must_equal false
    model.lazy_load_association_links?(:show, 3).must_equal true
    model.lazy_load_association_links false
    model.lazy_load_association_links?(:show, nil).must_equal false
    model.lazy_load_association_links{|type, req| req > 2}
    model.lazy_load_association_links?(:show, 1).must_equal false
    model.lazy_load_association_links?(:show, 3).must_equal true
  end

  it "should handle form_attributes lookup" do
    model.form_attributes_for(:show, nil).must_equal({})
    framework.form_attributes :class=>'foo'
    model.form_attributes_for(:show, nil).must_equal(:class=>'foo')
    framework.form_attributes{|mod, type, req| {:class=>"#{mod} #{type} #{req}"}}
    model.form_attributes_for(:show, 1).must_equal(:class=>'Artist show 1')

    framework.form_attributes :class=>'foo'
    model.form_attributes :data=>"bar"
    model.form_attributes_for(:show, nil).must_equal(:class=>'foo', :data=>'bar')
    model.form_attributes{|type, req| {:data=>"#{type} #{req}"}}
    model.form_attributes_for(:show, 1).must_equal(:class=>'foo', :data=>'show 1')
  end

  it "should handle form_options lookup" do
    model.form_options_for(:show, nil).must_equal({})
    framework.form_options :class=>'foo'
    model.form_options_for(:show, nil).must_equal(:class=>'foo')
    framework.form_options{|mod, type, req| {:class=>"#{mod} #{type} #{req}"}}
    model.form_options_for(:show, 1).must_equal(:class=>'Artist show 1')

    framework.form_options :class=>'foo'
    model.form_options :data=>"bar"
    model.form_options_for(:show, nil).must_equal(:class=>'foo', :data=>'bar')
    model.form_options{|type, req| {:data=>"#{type} #{req}"}}
    model.form_options_for(:show, 1).must_equal(:class=>'foo', :data=>'show 1')
  end

  it "should handle page_header lookup" do
    model.page_header_for(:show, nil).must_equal nil
    framework.page_header "foo"
    model.page_header_for(:show, nil).must_equal 'foo'
    framework.page_header{|mod, type, req| "#{mod} #{type} #{req}"}
    model.page_header_for(:show, 1).must_equal 'Artist show 1'
    model.page_header "bar"
    model.page_header_for(:show, nil).must_equal 'bar'
    model.page_header{|type, req| "#{type} #{req}"}
    model.page_header_for(:show, 1).must_equal 'show 1'
  end

  it "should handle page_footer lookup" do
    model.page_footer_for(:show, nil).must_equal nil
    framework.page_footer "foo"
    model.page_footer_for(:show, nil).must_equal 'foo'
    framework.page_footer{|mod, type, req| "#{mod} #{type} #{req}"}
    model.page_footer_for(:show, 1).must_equal 'Artist show 1'
    model.page_footer "bar"
    model.page_footer_for(:show, nil).must_equal 'bar'
    model.page_footer{|type, req| "#{type} #{req}"}
    model.page_footer_for(:show, 1).must_equal 'show 1'
  end

  it "should handle autocompletion options" do
    model.autocomplete_options({})
    model.autocomplete(:type=>:show, :query=>'foo').must_equal []
    a = Artist.create(:name=>'FooBar')
    model.autocomplete(:type=>:show, :query=>'foo').must_equal ["#{a.id} - FooBar"]
    model.autocomplete(:type=>:show, :query=>'boo').must_equal []
    b = Artist.create(:name=>'BooFar')
    model.autocomplete(:type=>:show, :query=>'boo').must_equal ["#{b.id} - BooFar"]
    model.autocomplete(:type=>:show, :query=>'oo').sort.must_equal ["#{a.id} - FooBar", "#{b.id} - BooFar"]

    framework.autocomplete_options :display=>:id
    model.autocomplete(:type=>:show, :query=>a.id.to_s).must_equal ["#{a.id} - #{a.id}"]
    framework.autocomplete_options{|mod, type, req| {:limit=>req}}
    model.autocomplete(:type=>:show, :query=>'oo', :request=>1).must_equal ["#{a.id} - FooBar"]
    model.autocomplete_options :display=>:id
    model.autocomplete(:type=>:show, :query=>a.id.to_s).must_equal ["#{a.id} - #{a.id}"]

    framework.autocomplete_options({})
    model.autocomplete(:type=>:show, :query=>a.id.to_s).must_equal ["#{a.id} - #{a.id}"]
    model.autocomplete_options :display=>proc{:id}
    model.autocomplete(:type=>:show, :query=>b.id.to_s).must_equal ["#{b.id} - #{b.id}"]
    model.autocomplete_options :limit=>1
    model.autocomplete(:type=>:show, :query=>'oo').must_equal ["#{a.id} - FooBar"]
    model.autocomplete_options :limit=>proc{1}
    model.autocomplete(:type=>:show, :query=>'oo').must_equal ["#{a.id} - FooBar"]
    model.autocomplete_options :callback=>proc{|ds, opts| ds.reverse_order(:id)}
    model.autocomplete(:type=>:show, :query=>'oo').must_equal ["#{b.id} - BooFar", "#{a.id} - FooBar"]

    model.autocomplete_options :filter=>proc{|ds, opts| ds.where(:name=>opts[:query])}
    model.autocomplete(:type=>:show, :query=>'foo').must_equal []
    model.autocomplete(:type=>:show, :query=>'FooBar').must_equal ["#{a.id} - FooBar"]

    model.autocomplete_options{|type, req| {:limit=>req}}
    model.autocomplete(:type=>:show, :query=>'oo', :request=>1).must_equal ["#{a.id} - FooBar"]
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
    model.autocomplete(:query=>'foo', :association=>:artist).must_equal []
    a = Artist.create(:name=>'FooBar')
    model.autocomplete(:query=>'foo', :association=>:artist).must_equal ["#{a.id} - FooBar"]
    model.autocomplete(:query=>'boo', :association=>:artist).must_equal []
    b = Artist.create(:name=>'BooFar')
    model.autocomplete(:query=>'boo', :association=>:artist).must_equal ["#{b.id} - BooFar"]
    model.autocomplete(:query=>'oo', :association=>:artist).sort.must_equal ["#{a.id} - FooBar", "#{b.id} - BooFar"]
    artist.autocomplete_options :display=>:id
    model.autocomplete(:query=>a.id.to_s, :association=>:artist).must_equal ["#{a.id} - #{a.id}"]
    artist.autocomplete_options :display=>proc{:id}
    model.autocomplete(:query=>b.id.to_s, :association=>:artist).must_equal ["#{b.id} - #{b.id}"]
    artist.autocomplete_options :limit=>1
    model.autocomplete(:query=>'oo', :association=>:artist).must_equal ["#{a.id} - FooBar"]
    artist.autocomplete_options :limit=>proc{1}
    model.autocomplete(:query=>'oo', :association=>:artist).must_equal ["#{a.id} - FooBar"]
    artist.autocomplete_options :callback=>proc{|ds, opts| ds.reverse_order(:id)}
    model.autocomplete(:query=>'oo', :association=>:artist).must_equal ["#{b.id} - BooFar", "#{a.id} - FooBar"]

    artist.autocomplete_options :filter=>proc{|ds, opts| ds.where(:name=>opts[:query])}
    model.autocomplete(:query=>'foo', :association=>:artist).must_equal []
    model.autocomplete(:query=>'FooBar', :association=>:artist).must_equal ["#{a.id} - FooBar"]
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
    model.autocomplete(:query=>'foo', :association=>:artists).must_equal []
    a = Artist.create(:name=>'FooBar')
    model.autocomplete(:query=>'foo', :association=>:artists).must_equal ["#{a.id} - FooBar"]
    model.autocomplete(:query=>'boo', :association=>:artists).must_equal []
    b = Artist.create(:name=>'BooFar')
    model.autocomplete(:query=>'boo', :association=>:artists).must_equal ["#{b.id} - BooFar"]
    model.autocomplete(:query=>'oo', :association=>:artists).sort.must_equal ["#{a.id} - FooBar", "#{b.id} - BooFar"]
    c = Album.create(:name=>'Quux')
    c.add_artist(a)
    model.autocomplete(:query=>'oo', :association=>:artists, :exclude=>c.id).sort.must_equal ["#{b.id} - BooFar"]
    artist.autocomplete_options :display=>:id
    model.autocomplete(:query=>a.id.to_s, :association=>:artists).must_equal ["#{a.id} - #{a.id}"]
    model.autocomplete(:query=>b.id.to_s, :association=>:artists, :exclude=>c.id).must_equal ["#{b.id} - #{b.id}"]
    artist.autocomplete_options :display=>proc{:id}
    model.autocomplete(:query=>b.id.to_s, :association=>:artists).must_equal ["#{b.id} - #{b.id}"]
    model.autocomplete(:query=>a.id.to_s, :association=>:artists, :exclude=>c.id).must_equal []
    artist.autocomplete_options :limit=>1
    model.autocomplete(:query=>'oo', :association=>:artists).must_equal ["#{a.id} - FooBar"]
    model.autocomplete(:query=>'oo', :association=>:artists, :exclude=>c.id).must_equal ["#{b.id} - BooFar"]
    artist.autocomplete_options :limit=>proc{1}
    model.autocomplete(:query=>'oo', :association=>:artists).must_equal ["#{a.id} - FooBar"]
    model.autocomplete(:query=>'oo', :association=>:artists, :exclude=>c.id).must_equal ["#{b.id} - BooFar"]
    artist.autocomplete_options :callback=>proc{|ds, opts| ds.reverse_order(:id)}
    model.autocomplete(:query=>'oo', :association=>:artists).must_equal ["#{b.id} - BooFar", "#{a.id} - FooBar"]
    model.autocomplete(:query=>'oo', :association=>:artists, :exclude=>c.id).must_equal ["#{b.id} - BooFar"]

    artist.autocomplete_options :filter=>proc{|ds, opts| ds.where(:name=>opts[:query])}
    model.autocomplete(:query=>'foo', :association=>:artists).must_equal []
    model.autocomplete(:query=>'FooBar', :association=>:artists).must_equal ["#{a.id} - FooBar"]
    model.autocomplete(:query=>'FooBar', :association=>:artists, :exclude=>c.id).must_equal []
  end
end


describe AutoForme::OptsAttributes do
  before do
    @c = Class.new do
      extend AutoForme::OptsAttributes 
      opts_attribute :foo
      attr_accessor :opts
    end
    @o = @c.new
    @o.opts = {}
  end

  it "should act as a getter if given no arguments, and setter if given arguments or a block" do
    @o.foo.must_equal nil
    @o.foo(1).must_equal 1
    @o.foo.must_equal 1
    p = proc{}
    # Work around minitest bug
    assert_equal @o.foo(&p), p
    assert_equal @o.foo, p
  end

  it "should should raise an error if given more than one argument" do
    proc{@o.foo(1, 2)}.must_raise(ArgumentError)
  end

  it "should should raise an error if given block and argument" do
    proc{@o.foo(1){}}.must_raise(ArgumentError)
  end
end

describe AutoForme do
  it ".version should return a typical version string" do
    AutoForme.version.must_match /\A\d+\.\d+\.\d+\z/
  end
end
