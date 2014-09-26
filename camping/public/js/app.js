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
]).
config(['$routeProvider', function($routeProvider) {
  $routeProvider.when('/home', {templateUrl: 'partials/grouplist.html', controller: 'GroupListController'});
  $routeProvider.when('/group', {templateUrl: 'partials/group.html', controller: 'GroupController',
		resolve: {
			scrapeResults: ['$route', '$http', '$q', function ($route, $http, $q) {
				var scrapeStuff = $q.defer();
				$http({method: 'GET', url: '/rest/scrapegroup', params: {groupid : $route.current.params.groupid}}).
					success(function(data, status, headers, config) {
						//$scope.loading = false;
						console.log('got scrape');
						scrapeStuff.resolve('Done!');
					}).
					error(function(data, status, headers, config) {

					});
				return scrapeStuff.promise;
			}]
		}});
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
