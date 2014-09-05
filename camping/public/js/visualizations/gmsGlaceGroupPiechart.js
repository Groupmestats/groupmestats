angular.module('visualizations').directive('gmsGlanceGroupPiechart', function() {
	return{
		scope: {
			gmsData: '=',
			gmsTitle: '@',
			gmsUser: '=',
			gmsTooltiptext: '@'
		},
		template: '<div id="container"></div>',
		link: function ($scope, element, attrs) {
					$scope.$watch('gmsData', function(gmsData) {
						if(gmsData)
						{
							$scope.data = gmsData;
							drawChart($scope.data, attrs.gmsTitle, element[0]);
						}
					});

			$scope.chart = new Highcharts.Chart({
				chart: {
					type: 'pie',
					renderTo: element[0],
				},
		credits: {
			enabled: false
		},
				plotOptions: {
				   pie: {
					   allowPointSelect: true,
					   animation: {
						   duration: 2000
					   },
					   cursor: 'pointer',
					   dataLabels: {
						   enabled: false
					   },
					   showInLegend: true,
					},
					series: {
						slicedOffset: 0,
					}
				},
				tooltip: {
		formatter: function() {
			return '<b>'+ this.point.name + '</b>: '+ '<br><b>' + this.y + '</b> ' + $scope.gmsTooltiptext + '<br><b>' + roundToFour(this.percentage) +'</b>% of ' + $scope.gmsTooltiptext;
		},
		shared: true
				},
				legend: {
					align: 'right',
					title: {
						text: attrs.gmsLegendTitle,
						style: {
							fontWeight: 'bold',
						}
					},
					borderColor: 'black',
					borderWidth: 2,
					layout: 'vertical',
					verticalAlign: 'top',
					itemStyle: {
						width: 50
					},
					y: 70,
					x: -150,
					itemHoverStyle: {
							color: '#00f'
					},
					shadow: true
				},
				series: []
			});

			function roundToFour(num) {
				return +(Math.round(num + "e+4")  + "e-4");
			}

			function drawChart(chartData, title, element) {
				$scope.chart.addSeries({
					data: chartData,
					cursor: 'pointer',
				}, false);
				$scope.chart.setTitle({text:title}, '', false);
				$scope.chart.redraw();
			}
		}
	};
})