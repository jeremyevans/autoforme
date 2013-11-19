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
    framework.browse_table_class 'bar'
    model.table_class_for(:browse, nil).should == 'bar'
    model.table_class 'baz'
    model.table_class_for(:browse, nil).should == 'baz'
    model.browse_table_class 'quux'
    model.table_class_for(:browse, nil).should == 'quux'
    model.browse_table_class{|type, req| "#{type} #{req}"}
    model.table_class_for(:browse, :foo).should == 'browse foo'
  end

  it "should handle per page lookup" do
    model.limit_for(:browse).should == 25
    framework.per_page 1
    model.limit_for(:browse).should == 1
    framework.browse_per_page 2
    model.limit_for(:browse).should == 2
    model.per_page 3
    model.limit_for(:browse).should == 3
    model.browse_per_page 4
    model.limit_for(:browse).should == 4
  end

  it "should handle columns lookup" do
    model.columns_for(:browse, nil).should == [:name]
    def (framework).columns_for(type, model)
      [type, model.name.to_sym]
    end
    model.columns_for(:browse, nil).should == [:browse, :Artist]
    model.columns [:foo]
    model.columns_for(:browse, nil).should == [:foo]
    model.browse_columns [:bar]
    model.columns_for(:browse, nil).should == [:bar]
    model.browse_columns{|type, req| req ? [type] : [:foo]}
    model.columns_for(:browse, true).should == [:browse]
    model.columns_for(:browse, nil).should == [:foo]
  end

  it "should handle column options lookup" do
    model.column_options_for(:browse, nil, :foo).should == {}
    def (framework).column_options_for(type, model)
      {:foo=>{type=>model.name.to_sym}}
    end
    model.column_options_for(:browse, nil, :foo).should == {:browse=>:Artist}
    model.column_options :foo=>{1=>2}
    model.column_options_for(:browse, nil, :foo).should == {1=>2}
    model.browse_column_options :foo=>{3=>4}
    model.column_options_for(:browse, nil, :foo).should == {3=>4}
    model.browse_column_options :foo=>proc{|type, req| {:type=>type, :req=>req}}
    model.column_options_for(:browse, nil, :foo).should == {:type=>:browse, :req=>nil}
    model.browse_column_options{|type, req, col| {:type=>type, :req=>req, :col=>col}}
    model.column_options_for(:browse, nil, :foo).should == {:type=>:browse, :req=>nil, :col=>:foo}
  end

  it "should handle order lookup" do
    model.order_for(:browse, nil).should == nil
    def (framework).order_for(type, model)
      [type, model.name.to_sym]
    end
    model.order_for(:browse, nil).should == [:browse, :Artist]
    model.order [:foo]
    model.order_for(:browse, nil).should == [:foo]
    model.browse_order :bar
    model.order_for(:browse, nil).should == :bar
    model.browse_order{|type, req| [type, req]}
    model.order_for(:browse, nil).should == [:browse, nil]
  end

  it "should handle eager lookup" do
    model.eager_for(:browse, nil).should == nil
    model.eager [:foo]
    model.eager_for(:browse, nil).should == [:foo]
    model.browse_eager :bar
    model.eager_for(:browse, nil).should == :bar
    model.browse_eager{|type, req| [type, req]}
    model.eager_for(:browse, nil).should == [:browse, nil]
  end

  it "should handle eager_graph lookup" do
    model.eager_graph_for(:browse, nil).should == nil
    model.eager_graph [:foo]
    model.eager_graph_for(:browse, nil).should == [:foo]
    model.browse_eager_graph :bar
    model.eager_graph_for(:browse, nil).should == :bar
    model.browse_eager_graph{|type, req| [type, req]}
    model.eager_graph_for(:browse, nil).should == [:browse, nil]
  end

  it "should handle filter lookup" do
    model.filter_for(:browse).should == nil
    def (framework).filter_for(type, model)
      lambda{|ds, req| 1}
    end
    model.filter_for(:browse).call(nil, nil).should == 1
    model.filter{|ds, req| 2}
    model.filter_for(:browse).call(nil, nil).should == 2
    model.browse_filter{|ds, req| 3}
    model.filter_for(:browse).call(nil, nil).should == 3
  end

  it "should handle display_name lookup" do
    model.display_name_for(:edit).should == nil
    def (framework).display_name_for(type, model)
      :"#{type}_#{model.name}"
    end
    model.display_name_for(:edit).should == :edit_Artist
    model.display_name :foo
    model.display_name_for(:edit).should == :foo
    model.edit_display_name :bar
    model.display_name_for(:edit).should == :bar
  end

  it "should handle supported_actions lookup" do
    model.supported_action?('new', nil).should be_true
    model.supported_action?('edit', nil).should be_true
    model.supported_action?('search', nil).should be_true
    framework.supported_actions ['new', 'search']
    model.supported_action?('new', nil).should be_true
    model.supported_action?('edit', nil).should be_false
    model.supported_action?('search', nil).should be_true
    model.supported_actions ['edit', 'search']
    model.supported_action?('new', nil).should be_false
    model.supported_action?('edit', nil).should be_true
    model.supported_action?('search', nil).should be_true
    model.supported_actions{|type, req| req ? [type] : []}
    model.supported_action?('new', nil).should be_false
    model.supported_action?('new', true).should be_true
  end

  it "should handle mtm_associations lookup" do
    model.supported_mtm_edit?('foos', nil).should be_false
    model.supported_mtm_edit?('bars', nil).should be_false
    def (framework).mtm_associations_for(model)
      ['foos']
    end
    model.supported_mtm_edit?('foos', nil).should be_true
    model.supported_mtm_edit?('bars', nil).should be_false
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
    def (framework).inline_mtm_associations_for(model)
      ['foos']
    end
    model.supported_mtm_update?('foos', nil).should be_true
    model.supported_mtm_update?('bars', nil).should be_false
    model.inline_mtm_associations ['bars']
    model.supported_mtm_update?('foos', nil).should be_false
    model.supported_mtm_update?('bars', nil).should be_true
    model.inline_mtm_associations{|req| req ? ['foos'] : ['bars']}
    model.supported_mtm_update?('foos', nil).should be_false
    model.supported_mtm_update?('bars', nil).should be_true
    model.supported_mtm_update?('foos', true).should be_true
    model.supported_mtm_update?('bars', true).should be_false
  end

  it "should handle ajax_inline_mtm_associations lookup" do
    model.ajax_inline_mtm_associations?( nil).should be_false
    def (framework).ajax_inline_mtm_associations?(model)
      true
    end
    model.ajax_inline_mtm_associations?(nil).should be_true
    model.ajax_inline_mtm_associations false
    model.ajax_inline_mtm_associations?(nil).should be_false
    model.ajax_inline_mtm_associations{|req| req > 2}
    model.ajax_inline_mtm_associations?(1).should be_false
    model.ajax_inline_mtm_associations?(3).should be_true
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
    model.autocomplete_options :display=>:id
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
      autoforme Artist do
        artist = self
      end
      autoforme Album do
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
      autoforme Artist do
        artist = self
      end
      autoforme Album do
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
