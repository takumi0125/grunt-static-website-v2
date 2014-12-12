(function() {
  var project;

  project = window.project || {};

  project.Common = (function() {
    function Common() {}

    return Common;

  })();

  $(function() {
    return new sample.Common();
  });

}).call(this);
