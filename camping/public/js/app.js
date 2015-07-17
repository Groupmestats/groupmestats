'use strict';

angular.module('visualizations',[]);

//main app module
angular.module('gmStats', [
  'ngRoute',
  'gmStats.filters',
  'gmStats.services',
  'gmStats.directives',
  'gmStats.controllers',
  'visualizations'
])
.config(['$routeProvider', function($routeProvider) {
  $routeProvider.when('/home', {templateUrl: 'partials/grouplist.html', controller: 'GroupListController'});
//  $routeProvider.when('/group', {templateUrl: 'partials/group.html', controller: 'GroupController'});
  $routeProvider.when('/group', {templateUrl: 'partials/group.html', controller: 'GroupController', resolve : { app: function ($q, $timeout) {
          var defer = $q.defer();
          $timeout(function () {
            defer.resolve(); 
          }, 7000);
          return defer.promise;
        }}});
  $routeProvider.when('/glance', {templateUrl: 'partials/glance.html', controller: 'GlanceController'});
  $routeProvider.when('/about', {templateUrl: 'partials/about.html', controller: 'AboutController'});
  $routeProvider.when('/user', {templateUrl: 'partials/user.html', controller: 'UserController'});
  $routeProvider.when('/loadGroup', {templateUrl: 'partials/loadGroup.html', controller: 'ScrapeController'});
  $routeProvider.otherwise({redirectTo: '/home'});
}])
.run(['$rootScope', '$location', function($rootScope, $location) {
	$rootScope.isActive = function(path) {
		if ($location.path().substr(1, path.length) == path) {
		  return true
		} else {
		  return false
		}
	}
}]);;
