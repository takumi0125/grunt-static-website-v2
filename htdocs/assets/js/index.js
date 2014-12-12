(function() {
  var project;

  project = window.project || {};

  project.Index = (function() {
    function Index() {}

    return Index;

  })();

  $(function() {
    return new project.Index();
  });

}).call(this);
