'use strict';

/* Directives */


angular.module('myApp.directives', []).
	directive('gmsPiechart', function() {
        return{
            scope: {
                gmsData: '=',
                gmsTitle: '@',
                gmsUser: '=',
            },
            template: '<div id="container"></div>', 
            link: function ($scope, element, attrs) {
                $scope.$watch('gmsUser', function(gmsUser) {
                    if(gmsUser)
                    {
                        $scope.userData = gmsUser;
                        $scope.$watch('gmsData', function(gmsData) {
                            if(gmsData)
                            {
                                drawChart(gmsData, $scope.userData, attrs.gmsTitle, element[0]);
                            }
                        });
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
                        },
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
                        itemHoverStyle: {
                                color: '#00f'
                        },
                        shadow: true
                    },
                    series: []
                });

                function drawChart(chartData, userData, title, element) {
                    if($scope.chart.series[0])
                    {
                        $scope.chart.series[0].remove(true);
                    }
                    $scope.chart.addSeries({
                        data: chartData,
                        cursor: 'pointer',
                        point: {
                            events: {
                                click: function(e) {
                                    var user;
                                    for (var i = 0; i < userData.length; i++) {
                                            if (userData[i]['name'] == this.series.data[this.x].name) {
                                                user = userData[i];
                                            }
                                    }
                                    hs.htmlExpand(null, {
                                        headingText: "User Stats",
                                        
                                        maincontentText: '<img src="' + user.avatar_url + '.avatar" style="float:left; padding-right:15px"></img><h3>' + user.name + '</h3>' +
                                            '<br>' +
                                            '<h4>User stats:</h4>' + 
                                            '<p><b>Total Posts:</b> ' + user.total_posts + '</p>' +
                                            '<p><b>Total likes:</b> ' + user.total_likes_received + '</p>' +
                                            '<p><b>Likes to Posts Ratio:</b> ' + user.likes_to_posts_ratio + '</p>' +
                                            '<p><b>Top Post:</b> (' + user.top_post_likes + ') ' + user.top_post + '</p>' +
                                            '<a href="#/user?userid=' + user.user_id + '&groupid=' + user.group_id + '" onclick="javascript:parent.window.hs.close();" >More info</a>',
                                        //width: 800,
                                        //height: 600
                                    });
                                },
                                legendItemClick: function(e) {
                                    var user;
                                    for (var i = 0; i < userData.length; i++) {
                                            if (userData[i]['name'] == this.series.data[this.x].name) {
                                                user = userData[i];
                                            }
                                    }
                                    hs.htmlExpand(null, {
                                        headingText: "Stats",

                                        maincontentText: '<img src="' + user.avatar_url + '.avatar" style="float:left; padding-right:15px"></img><h3>' + user.name + '</h3>' +
                                            '<br>' +
                                            '<h4>User stats:</h4>' +
                                            '<p><b>Total Posts:</b> ' + user.total_posts + '</p>' +
                                            '<p><b>Total likes:</b> ' + user.total_likes_received + '</p>' +
                                            '<p><b>Likes to Posts Ratio:</b> ' + user.likes_to_posts_ratio + '</p>' +
                                            '<p><b>Top Post:</b> (' + user.top_post_likes + ') ' + user.top_post + '</p>' +
                                            '<a href="#/user?userid=' + user.user_id + '&groupid=' + user.group_id + '" onclick="javascript:parent.window.hs.close();" >More info</a>',
                                        //width: 800,
                                        //height: 600
                                    });
                                    return false;
                                }
                            }
                        }
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
                        data: chartData,
                        //pointInterval: 24 * 3600 * 1000 // one day
                        //pointStart: Date.UTC(1970, 0, 1)
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
						inverted: true
					},
					legend: {
						enabled: false
					},
					tooltip: {
						formatter: function () {
							return this.series.xAxis.categories[this.point.x] + ' ' + this.point.y +
							'<br/><b>' + this.point.value + '</b>'
							},
						shared: true
					},
					colorAxis: {
						min: '0',
						minColor: '#EEF5FC',
						maxColor: '#0000FF'
					},
					xAxis:{
						categories: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
					},
					yAxis:
					{
						min:0,
						max:23,
						minPadding: 0,
						maxPadding: 0,
						title: {
							text: 'Hour'
						}
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
	}).directive('gmsNgram', function() {
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
                        renderTo: element[0]
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
                        pointFormat: '<b>{point.y}</b><br/>',
                        shared: true
                    },
                    series: []
                });

                function drawChart(chartData, title, xaxisTitle, yaxisTitle, element) {
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
        };
    });
