angular.module('visualizations').directive('gmsPostVolumeChart', function($http, $routeParams) {
	return{
		scope: {
			gmsData: '=',
			gmsTitle: '@'
		},
		templateUrl: 'partials/directives/volumechart.html',
		link: function ($scope, element, attrs) {
			$scope.byWeek = false;
			$scope.byUser = false;

			$scope.setByWeek = function(val)
			{
				$scope.byWeek = val
				requestVolume();
			}

			$scope.setMessagesByUser = function(val)
			{
				$scope.byUser = val
				requestVolume();
			}

			function requestVolume(){
				$http({method: 'GET', url: '/rest/volumedata', params: {groupid : $routeParams.groupid, byWeek : $scope.byWeek == true, byUser : $scope.byUser == true}}).
					success(function(data, status, headers, config) {
						$scope.gmsData = data
					}).
					error(function(data, status, headers, config) {

					});
			}

			$scope.$watch('gmsData', function(gmsData) {
				if(gmsData)
				{
					drawChart(gmsData, attrs.gmsTitle, $scope.byWeek == true);
				}
			});

			//request
			requestVolume();

			$scope.chart = new Highcharts.Chart({
				chart: {
					type: 'column',
					renderTo: element.find( "div" )[2] //this sucksssssss
				},
				credits: {
					enabled: false
				},
				title: {
					text: ''
				},
				legend:
				{
					enabled:false
				},
				xAxis: {
					type: 'datetime',
					title: {
						text: attrs.gmsXaxisTitle
					}
				},
				yAxis: {
					labels: {
						format: '{value}'
					},
					title: {
						text: attrs.gmsYaxisTitle
					},
				},
				tooltip: {
				},
				series: []
			});

			function drawChart(chartData, title, byWeek) {
				while($scope.chart.series.length > 0)
				{
					$scope.chart.series[0].remove(false);
				}
				$scope.chart.counters.color = 0;
				$scope.chart.counters.symbol = 0;
				$scope.chart.addSeries({
						data: chartData
					}, false);

				if(byWeek){
					$scope.chart.tooltip.options.formatter = function() {
						return  '<b>Week of ' + Highcharts.dateFormat('%e %b %Y', new Date(this.x)) + '</b><br/><b>' + this.y + ' </b>posts';
					};
				}
				else
				{
					$scope.chart.tooltip.options.formatter = function() {
						return  '<b>' + Highcharts.dateFormat('%b %Y', new Date(this.x)) + '</b><br/><b>' + this.y + ' </b>posts';
					};
				}

				$scope.chart.setTitle({text:title}, '', false);
				$scope.chart.redraw();
			}

		}
	}
})