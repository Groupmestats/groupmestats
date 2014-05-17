'use strict';


// Declare app level module which depends on filters, and services
angular.module('myApp', [
  'ngRoute',
  'myApp.filters',
  'myApp.services',
  'myApp.directives',
  'myApp.controllers'
]).
config(['$routeProvider', function($routeProvider) {
  $routeProvider.when('/home', {templateUrl: 'partials/home.html', controller: 'HomeController'});
  $routeProvider.when('/about', {templateUrl: 'partials/about.html', controller: 'AboutController'});
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
