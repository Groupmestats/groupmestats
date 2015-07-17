'use strict';

/* Directives */

angular.module('gmStats.directives', [])
.directive('showLoading', function() {
    return {
      restrict: 'A',
      replace: true,
      transclude: true,
      scope: {
        loading: '=showLoading'
      },
      templateUrl: 'partials/directives/loading.html',
      link: function(scope, element, attrs) {
        //var spinner = new Spinner().spin();
        //var loadingContainer = element.find('.my-loading-spinner-container')[0];
        //loadingContainer.appendChild(spinner.el);
      }
    }
})
.directive('timeSelector', function() {
  return {
    restrict: 'E',
    replace: false,
    templateUrl: 'partials/directives/timeselect.html',
    link: function(scope, element, attrs) {
      //var spinner = new Spinner().spin();
      //var loadingContainer = element.find('.my-loading-spinner-container')[0];
      //loadingContainer.appendChild(spinner.el);
    }
  }
});

