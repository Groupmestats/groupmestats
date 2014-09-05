angular.module('visualizations').directive('gmsHeatmap', function() {
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
					type: 'heatmap',
					renderTo: element[0],
					inverted: true
				},
					credits: {
								enabled: false
							},
				legend: {
					enabled: false
				},
				tooltip: {
					formatter: function () {
						return this.series.xAxis.categories[this.point.x] + ' ' + this.point.y +
						'<br/><b>' + this.point.value + '</b> posts'
						},
					shared: true,
					positioner: function (labelWidth, labelHeight, point) {
						return { x: point.plotX - labelWidth + 60, y: point.plotY + labelHeight/2 };
					}
				},
				colorAxis: {
					min: '0',
					minColor: '#EEF5FC',
					maxColor: '#0000FF'
				},
				xAxis:{
					categories: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
					max:6
				},
				yAxis:
				{
					categories: ['12 am', '1 am', '2 am', '3 am', '4 am', '5 am', '6 am', '7 am', '8 am', '9 am', '10 am', '11 am', '12 pm', '1 pm', '2 pm', '3 pm', '4 pm', '5 pm', '6 pm', '7 pm', '8 pm', '9 pm', '10 pm', '11 pm'],
					minPadding: 0,
					maxPadding: 0,
					title: {
						text: 'Hour'
					},
					gridLineWidth:0
				},
				series: []
			});

			function drawChart(chartData, title, xaxisTitle, yaxisTitle, element) {
				if($scope.chart.series[0])
				{
					$scope.chart.series[0].remove(true);
				}
				$scope.chart.addSeries({
					data: chartData,
					borderWidth: 0
				}, false);
				$scope.chart.setTitle({text:title}, '', false);
				$scope.chart.redraw();
			}

		}
	};
})