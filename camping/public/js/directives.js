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
						renderTo: element[0],
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
						   showInLegend: true
					    }
				    },
                    tooltip: {
                        pointFormat: '<b>{point.y}</b><br/>',
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
                        y: 100,
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
    }).directive('gmsLinegraph', function() {
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
                        type: 'line',
                        renderTo: element[0],
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
                        pointFormat: '<b>{point.y}</b><br/>',
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
    }).directive('gmsBargraph', function() {
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
                        pointFormat: '<b>{point.y}</b><br/>',
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
    }).directive('gmsHeatmap', function() {
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
					tooltip: {
						pointFormat: '<b>{point.value}</b><br/>',
						shared: true
					},
					colorAxis: {
						min: '0',
						minColor: '#EEF5FC',
						maxColor: '#0000FF'
					},
					xAxis:{
						labels: {
							align: 'left',
							x: 5,
							format: '{value:%b %e}' // long month
						}
					},
					yAxis:
					{
						reversed: true,
						min:0,
						max:23,
						minPadding: 0,
						maxPadding: 0
					},
					series: []
				});

				function drawChart(chartData, title, xaxisTitle, yaxisTitle, element) {
					if($scope.chart.series[0])
					{
						$scope.chart.series[0].remove(true);
					}
					$scope.chart.addSeries({
						turboThreshold: 100000,
						data: chartData,
						borderWidth: 0,
						colsize: 24 * 36e5 -5 // one day
					}, false);
					$scope.chart.setTitle({text:title}, '', false);
					$scope.chart.redraw();
				}

			}
		};
	});
