'use strict';

/* Controllers */

angular.module('myApp.controllers', [])
	.controller('GroupListController', ['$scope', '$http', '$routeParams', function($scope, $http, $routeParams) {
		$scope.scrapeGroup = function(index)
		{
			var group = $scope.groupList[index]
			group.loading = true;
			$http({method: 'GET', url: '/rest/scrapegroup', params: { groupid: group.group_id }}).
				success(function(data, status, headers, config) {
					group.loading = false;
					//todo: refresh last updated date
				}).
				error(function(data, status, headers, config) {
					group.loading = false;
				});
		}
	
		$scope.refreshGroupList = function(index)
		{
			$scope.groupListLoading = true;
			$http({method: 'GET', url: '/rest/refreshGroupList'}).
				success(function(data, status, headers, config) {
					$scope.groupListLoading = false;
				}).
				error(function(data, status, headers, config) {
					$scope.groupListLoading = false;
				});
		}
	
		$http({method: 'GET', url: '/rest/groupList'}).
				success(function(data, status, headers, config) {
					$scope.groupList = data
				}).
				error(function(data, status, headers, config) {

				});
	}])
	.controller('GroupController', ['$scope', '$http', '$routeParams', function($scope, $http, $routeParams) {
		$scope.days = 0
		$scope.$watch('days', function(newValue, oldValue) {
             requestChart();
           });
		
		function requestChart(){
			var daysToRequest = $scope.days
			if(daysToRequest == 0)
			{
				daysToRequest = 9999999
			}
			$http({method: 'GET', url: '/rest/postsmost', params: {days : daysToRequest, groupid : $routeParams.groupid}}).
				success(function(data, status, headers, config) {
					drawChart(data)
				}).
				error(function(data, status, headers, config) {

				});
		}
		requestChart(); //inital load
		
		$scope.setDays = function(newday)
		{
			$scope.days = newday;
		}
		
		//this is going in a directive soon
		function drawChart(chartData) {
		var data = new google.visualization.DataTable();
		data.addColumn('string', 'Topping');
		data.addColumn('number', 'Slices');
		data.addRows(chartData);

		// Set chart options
		var options = {'title':'Posts in Merrifielderos by User',
		'width':800,
		'height':600};

		// Instantiate and draw our chart, passing in some options.
		var chart = new google.visualization.PieChart(document.getElementById('chart_div'));
		chart.draw(data, options);
		}

	}])
	.controller('AboutController', ['$scope', function($scope) {

	}]);
