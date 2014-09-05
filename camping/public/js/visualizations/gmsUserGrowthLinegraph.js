angular.module('visualizations').directive('gmsUserGrowthLinegraph', function() {
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
					pointFormat: '<b>{point.y}</b><br/>',
					shared: false
				},
				series: []
			});

			function drawChart(chartData, title, categories) {
				if($scope.chart.series[0])
				{
					$scope.chart.series[0].remove(true);
				}

				var toAdd = chartData;

				if(categories != null)
				{
					toAdd = [];
					var i = 0;
					angular.forEach(chartData, function(value, key){
						toAdd.push({
							name: categories[i],
							x: value[0],
							y: value[1]
						})
						i++;
					})
					$scope.chart.tooltip.options.formatter = function(i) {
						return  Highcharts.dateFormat('%e %b %Y', new Date(this.x)) + '<br/><b>' + this.point.name + '</b>';
					};
				};

				$scope.chart.addSeries({
					data: toAdd,
					//pointInterval: 24 * 3600 * 1000 // one day
					//pointStart: Date.UTC(1970, 0, 1)
				}, false);


				$scope.chart.setTitle({text:title}, '');
				$scope.chart.redraw();
			}

		}
	};
})