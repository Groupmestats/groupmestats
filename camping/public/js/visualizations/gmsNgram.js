angular.module('visualizations').directive('gmsNgram', function($http, $routeParams) {
	return{
		scope: {
			gmsData: '=',
			gmsTitle: '@'
		},
		templateUrl: 'partials/directives/ngram.html',
		link: function ($scope, element, attrs) {
			$scope.showNgramChart = false;
			
			$scope.requestNgramData = function(){
				$scope.ngramloading = true;
				$http({method: 'GET', url: '/rest/ngramdata', params: {groupid : $routeParams.groupid, search: $scope.ngramterms}}).
					success(function(data, status, headers, config) {
						$scope.ngramloading = false;
						drawChart(data);
						$scope.showNgramChart = true;
					}).
					error(function(data, status, headers, config) {
						$scope.ngramloading = false;
					});
			}

			$scope.chart = new Highcharts.Chart({
				chart: {
					type: 'line',
					renderTo: element.find( "div" )[0], //TODO: better way...
				},
				credits: {
					enabled: false
				},
				title: {
					text: ''
				},
				legend: {
					align: 'right',
					layout: 'vertical',
					verticalAlign: 'middle'
				},
				plotOptions: {
				   line: {
					   allowPointSelect: false,
					   animation: {
						   duration: 2000
					   },
					   cursor: 'pointer',
					   dataLabels: {
						   enabled: false
					   },
					   marker:{
							enabled:false
						},
					   showInLegend: true
					}
				},
				xAxis: {
					type: 'datetime',
					title: {
						text: attrs.gmsXaxisTitle
					}
				},
				yAxis: {
					min: 0,
					ceiling: 100,
					labels: {
						format: '{value}%'
					},
					title: {
						text: attrs.gmsYaxisTitle
					},
				},
				tooltip: {
					pointFormat: '<b>{point.y}</b> posts<br/>',
					shared: true
				},
				series: []
			});

			function drawChart(chartData, title, xaxisTitle, yaxisTitle) {
				while($scope.chart.series.length > 0)
				{
					$scope.chart.series[0].remove(false);
				}
				$scope.chart.xAxis[0].setExtremes(chartData.startDate, chartData.endDate);
				angular.forEach(chartData.series, function(value, key){
					$scope.chart.addSeries({
							data: value.data,
							name: value.name
						}, false);
				})

				$scope.chart.setTitle({text:title}, '', false);
				$scope.chart.redraw();
			}

		}
	}
})