angular.module('visualizations').directive('gmsBargraph', function() {
	return{
		scope: {
			gmsData: '=',
			gmsTitle: '@'
		},
		template: '<div id="container"></div>',
		link: function ($scope, element, attrs) {
			$scope.$watch('gmsData', function(gmsData) {
				if(gmsData)
				{
					drawChart(gmsData, attrs.gmsTitle, element[0]);
				}
			});

			$scope.chart = new Highcharts.Chart({
				chart: {
					type: 'column',
					renderTo: element[0],
				},
				credits: {
					enabled: false
				},
				legend: {
					enabled: false
				},
				plotOptions: {
				   line: {
					   allowPointSelect: true,
					   animation: {
						   duration: 2000
					   },
					   cursor: 'pointer',
					   dataLabels: {
						   enabled: false
					   },
					   showInLegend: false
					}
				},
				xAxis: {
					type: 'category',
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
					pointFormat: '<b>{point.y}</b> posts<br/>',
					shared: true
				},
				series: []
			});

			function drawChart(chartData, title, xaxisTitle, yaxisTitle, element) {
				if($scope.chart.series[0])
				{
					$scope.chart.series[0].remove(true);
				}
				$scope.chart.addSeries({
					data: chartData
				}, false);
				$scope.chart.setTitle({text:title}, '', false);
				$scope.chart.redraw();
			}

		}
	};
});