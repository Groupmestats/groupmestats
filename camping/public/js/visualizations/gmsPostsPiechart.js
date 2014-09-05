angular.module('visualizations').directive('gmsPostsPiechart', function() {
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
							drawChart(gmsData, attrs.gmsTitle, element[0]);
						}
					});

			$scope.chart = new Highcharts.Chart({
				chart: {
					renderTo: element[0]
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
					   size: '70%'
					},
					series: {
						slicedOffset: 0,
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
					borderWidth: 1,
					layout: 'vertical',
					verticalAlign: 'top',
					width: 150,
					itemStyle: {
						width: 130
					},
					y: 70,
					x: 0,
					itemHoverStyle: {
							color: '#00f'
					},
					shadow: true
				},
				tooltip: {
					formatter: function() {
						return '<small>'+ this.point.name +'</small><br><b> '+ this.point.y + '</b> ' + $scope.gmsTooltiptext + '<br><b>' + roundToFour(this.percentage) +'</b>% of ' + $scope.gmsTooltiptext;
					},
					shared: true,
					useHTML: true,
				},
				series: []
			});

			function roundToFour(num) {
				return +(Math.round(num + "e+2")  + "e-2");
			}

			function userStats(userData, chart) {
				var user;
				for (var i = 0; i < userData.length; i++) {
						if (userData[i]['name'] == chart.series.data[chart.x].name) {
							user = userData[i];
						}
				}

					return '<img src="' + user.avatar_url + '" style="float:left; padding-right:15px"></img><h3>' + user.name + '</h3>' +
						'<br>' +
						'<h4>User stats:</h4>' +
						'<p><b>Total Posts:</b> ' + user.total_posts + '</p>' +
						'<p><b>Percentage of Total Posts:</b> ' + user.post_percentage + '%</p>' +
						'<p><b>Total likes:</b> ' + user.total_likes_received + '</p>' +
						'<p><b>Likes to Posts Ratio:</b> ' + user.likes_to_posts_ratio + '</p>' +
						'<a href="#/user?userid=' + user.user_id + '&groupid=' + user.group_id + '" onclick="javascript:parent.window.hs.close();" >More info</a>'
			}

			function drawChart(chartData, title, element) {
				if($scope.chart.series[0])
				{
					$scope.chart.series[0].remove(true);
				}
				$scope.chart.addSeries({
					type: 'pie',
					name: 'testname1',
					center: ["35%", "50%"],
					showInLegend:true,
					data: chartData,
					cursor: 'pointer',
					point: {
//                            events: {
//                                click: function(e) {
//                                    hs.htmlExpand(null, {
//                                        headingText: "User Stats",
//                                        maincontentText: userStats(userData, this)
//                                    });
//                                },
//                                legendItemClick: function(e) {
//                                    hs.htmlExpand(null, {
//                                        headingText: "User Stats",
//                                        maincontentText: userStats(userData, this)
//                                    });
//                                    return false;
//                                }
//                            }
					},
					tooltip: {
					}
				}, false);
				/*
				$scope.chart.addSeries({
					type: 'pie',
					name: 'testname2',
					center: ["65%", "50%"],
					showInLegend:false,
					data: chartData.likesGotten,
					cursor: 'pointer',
					point: {
						events: {
							click: function(e) {
//                                    hs.htmlExpand(null, {
//                                        headingText: "User Stats",
//                                        maincontentText: userStats(userData, this)
//                                    });
							},
							legendItemClick: function(e) {
//                                    hs.htmlExpand(null, {
//                                        headingText: "User Stats",
//                                        maincontentText: userStats(userData, this)
//                                    });
								return false;
							}
						}
					},
					tooltip: {
					}
				}, false);
				*/
				$scope.chart.setTitle({text:title}, '', false);
				$scope.chart.redraw();
			}
		}
	};
})