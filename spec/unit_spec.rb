describe AutoForme do
  before(:all) do
    db_setup(:artists=>[[:name, :string]])
    model_setup(:Artist=>[:artists])
  end
  after(:all) do
    Object.send(:remove_const, :Artist)
  end

  it "should handle table class lookup" do
    app_setup(Artist)
    model.table_class_for(:browse).should == 'table table-bordered table-striped'
    framework.table_class 'foo'
    model.table_class_for(:browse).should == 'foo'
    framework.browse_table_class 'bar'
    model.table_class_for(:browse).should == 'bar'
    model.table_class 'baz'
    model.table_class_for(:browse).should == 'baz'
    model.browse_table_class 'quux'
    model.table_class_for(:browse).should == 'quux'
  end

  it "should handle per page lookup" do
    app_setup(Artist)
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
    app_setup(Artist)
    model.columns_for(:browse).should == [:name]
    def (framework).columns_for(type, model)
      [type, model.name.to_sym]
    end
    model.columns_for(:browse).should == [:browse, :Artist]
    model.columns [:foo]
    model.columns_for(:browse).should == [:foo]
    model.browse_columns [:bar]
    model.columns_for(:browse).should == [:bar]
  end
end
