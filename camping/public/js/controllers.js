'use strict';

/* Controllers */

angular.module('myApp.controllers', [])
	.controller('HomeController', ['$scope', '$http', function($scope, $http) {
		$http({method: 'GET', url: '/rest/postsmost'}).
			success(function(data, status, headers, config) {
				drawChart(data)
			}).
			error(function(data, status, headers, config) {

			});
		
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
