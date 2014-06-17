'use strict';

/* Directives */


angular.module('myApp.directives', []).
	directive('gmsPiechart', function() {
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
						type: 'pie',
						renderTo: element[0]
					},
					plotOptions: {
					   pie: {
						   allowPointSelect: true,
						   cursor: 'pointer',
						   dataLabels: {
							   enabled: false
						   },
						   showInLegend: true
					    }
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
                        //y: 100,
                        shadow: true
                    },
					series: []
				});

				function drawChart(chartData, title, element) {
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
