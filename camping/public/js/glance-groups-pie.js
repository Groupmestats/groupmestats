'use strict';

/* Directives */

angular.module('myApp.directives', []).
	directive('gmsGlanceGroupPiechart', function() {
        return{
            scope: {
                gmsData: '=',
                gmsTitle: '@',
                gmsUser: '=',
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
                        //drawChart($scope.data, attrs.gmsTitle, element[0]);
                
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
                           size: '60%'
                        },
                        series: {
                            slicedOffset: 0,
                        }
                    },
                    tooltip: {
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
                        width: 100,
                        itemStyle: {
                            width: 50 
                        },
                        y: 70,
                        x: -50,
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
    });
