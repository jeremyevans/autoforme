(function() {
  var autoforme = document.querySelector('#autoforme_content');
  if (!autoforme) {
    return;
  }
  var base_url = autoforme.getAttribute('data-url');
  var xhr_headers = {'X-Requested-With': 'XMLHttpRequest'};

  function autoforme_fix_autocomplete(form) {
    form.querySelectorAll('.autoforme_autocomplete').forEach((e) => {
      e.value = e.value.split(' - ', 2)[0];
    });
  }

  function autoforme_setup_autocomplete(content) {
    content.querySelectorAll('.autoforme_autocomplete').forEach((e) => {
      var column = e.getAttribute('data-column');
      var exclude = e.getAttribute('data-exclude');
      var url = base_url + 'autocomplete';
      if (column) {
        url += '/' + column;
      }
      url += '?type=' + e.getAttribute('data-type');
      if (exclude) {
        url += '&exclude=' + exclude;
      }

      new autoComplete({
        selector: '[id="'+e.getAttribute("id")+'"]',
        source: function(term, suggest) {
          fetch((url + '&q=' + term), {headers: xhr_headers}).
            then(function(response) {
              return response.text();
            }).
            then(function(body) {
              suggest(body.split("\n"));
            });
        }
      });
    });
  }

  autoforme_setup_autocomplete(autoforme);

  autoforme.querySelectorAll("form").forEach((form) => {
    form.addEventListener('submit', function(){
      autoforme_fix_autocomplete(form);
    }, {passive: true});
  });

  var lazy_load_association_links = autoforme.querySelector('#lazy_load_association_links');
  if (lazy_load_association_links) {
    load_association_links = function(e) {
      e.preventDefault();
      lazy_load_association_links.removeEventListener('click', load_association_links);

      var url = base_url + "association_links/" + load_association_links.getAttribute('data-object') + "?type=" + load_association_links.getAttribute('data-type');
      fetch(url, {headers: xhr_headers}).
        then(function(response) {
          return response.text();
        }).
        then(function(body) {
          lazy_load_association_links.innerHTML = body;
          autoforme_setup_autocomplete(lazy_load_association_links);
        });
    };
    lazy_load_association_links.addEventListener('click', load_association_links);
  }

  setup_remove_hooks = function() {
    autoforme.querySelectorAll('.inline_mtm_remove_associations form.mtm_remove_associations').forEach((form) => {
      if (form.remove_hook_setup) {return;}
      form.remove_hook_setup = true;

      form.addEventListener('submit', function(e){
        fetch(form.action, {method: 'post', body: new FormData(form), headers: xhr_headers}).
          then(function(response) {
            return response.text();
          }).
          then(function(body) {
            document.querySelector(form.getAttribute('data-add')).insertAdjacentHTML('beforeend', body);
            form.parentElement.remove();
          });
        e.preventDefault();
      });
    });
  };
  setup_remove_hooks();

  autoforme.querySelectorAll('.mtm_add_associations').forEach((form) => {
    form.addEventListener('submit', function(e){
      var form_ac = form.querySelector('.autoforme_autocomplete');
      if (!form_ac) {
        var select = form.querySelector('select');

        fetch(form.action, {method: 'post', body: new FormData(form), headers: xhr_headers}).
          then(function(response) {
            return response.text();
          }).
          then(function(body) {
            select.remove(select.selectedIndex);
            select.selectedIndex = 0;
            document.querySelector(form.getAttribute('data-remove')).insertAdjacentHTML('beforeend', body);
            setup_remove_hooks();
          });
      } else {
        autoforme_fix_autocomplete(form);

        fetch(form.action, {method: 'post', body: new FormData(form), headers: xhr_headers}).
          then(function(response) {
            return response.text();
          }).
          then(function(body) {
            form_ac.value = '';
            document.querySelector(form.getAttribute('data-remove')).insertAdjacentHTML('beforeend', body);
            setup_remove_hooks();
          });
      }
      e.preventDefault();
    });
  });
})();
