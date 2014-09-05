angular.module('visualizations').directive('gmsDailyPostsLinegraph', function() {
	return{
		scope: {
			gmsData: '=',
			gmsTitle: '@',
			gmsCategoryData: '='
		},
		template: '<div id="container"></div>',
		link: function ($scope, element, attrs) {
			$scope.$watch('gmsData', function(gmsData) {
				if(gmsData)
				{
					drawChart(gmsData, $scope.gmsTitle, $scope.gmsCategoryData);
				}
			});

			$scope.chart = new Highcharts.Chart({
				chart: {
					type: 'scatter',
					renderTo: element[0],
				},
				credits: {
					enabled: false
				},
				plotOptions: {
				   scatter: {
					   allowPointSelect: true,
					   animation: {
						   duration: 1000
					   },
					   cursor: 'pointer',
					   dataLabels: {
						   enabled: false
					   },
					   showInLegend: false,
					   lineWidth:2
					}
				},
				xAxis: {
					type: attrs.gmsCategory,
					//type: 'datetime',
					//type: 'category',
					dateTimeLabelFormats: {
						day: '%e of %b %Y'
					},
					title: {
						text: attrs.gmsXaxisTitle
					}
				},
				yAxis: {
					min: 0,
					title: {
						text: attrs.gmsYaxisTitle
					},
				},
				tooltip: {
					headerFormat: '<small>{point.x}</small><br/>',
					pointFormat: '<b>{point.y}</b> Posts<br/>',
					shared: true,
					useHTML: true,
				},
				series: []
			});

			function drawChart(chartData, title, categories) {
				if($scope.chart.series[0])
				{
					$scope.chart.series[0].remove(true);
				}

				$scope.chart.addSeries({
					data: chartData,
				}, false);

				$scope.chart.setTitle({text:title}, '', false);
				$scope.chart.redraw();
			}

		}
	};

})