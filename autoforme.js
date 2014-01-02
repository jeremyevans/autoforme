$(function() {
  var autoforme = $('#autoforme_content');
  var base_url = autoforme.data('url');

  function autoforme_fix_autocomplete(e) {
    $(e).find('.autoforme_autocomplete').each(function(){
      $(this).val($(this).val().split(' - ', 2)[0]);
    });
  }

  function autoforme_setup_autocomplete() {
    autoforme.find('.autoforme_autocomplete').each(function(){
      var e = $(this);
      var column = e.data('column');
      var exclude = e.data('exclude');
      var url = base_url + 'autocomplete';
      if (column) {
        url += '/' + column;
      }
      url += '?type=' + e.data('type');
      if (exclude) {
        url += '&exclude=' + exclude;
      }
      e.autocomplete(url);
    });
  }

  autoforme_setup_autocomplete();

  autoforme.on('submit', 'form', function(e){
    autoforme_fix_autocomplete(this);
  });


  $('#lazy_load_association_links').click(function(e){
    var t = $(this);
    t.load(base_url + "association_links/" + t.data('object') + "?type=" + t.data('type'), autoforme_setup_autocomplete);
    t.unbind('click');
    e.preventDefault();
  });

  autoforme.on('submit', '.mtm_add_associations', function(e){
    var form = $(this);
    if (form.find('.autoforme_autocomplete').length == 0) {
      var select = form.find('select')[0];
      $.post(this.action, form.serialize(), function(data, textStatus){
        $(select).find('option:selected').remove();
        select.selectedIndex = 0;
        $(form.data('remove')).append(data);
      });
    } else {
      autoforme_fix_autocomplete(form);
      $.post(this.action, form.serialize(), function(data, textStatus){
        var t = form.find('.autoforme_autocomplete');
        t.val('');
        t.data('autocompleter').cacheFlush();
        $(form.data('remove')).append(data);
      });
    }
    e.preventDefault();
  });

  autoforme.on('submit', '.inline_mtm_remove_associations form', function(e){
    var form = $(this);
    var parent = form.parent();
    $.post(this.action, form.serialize(), function(data, textStatus){
      var t = $(form.data('add'));
      if (t[0].type == "text") {
        t.data('autocompleter').cacheFlush();
      } else {
        t.append(data);
      }
      parent.remove();
    });
    e.preventDefault();
  });
});
