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
    		link: function (scope, element, attrs) {
            	scope.$watch('gmsData', function(gmsData) {
					if(gmsData)
					{
						drawChart(gmsData, attrs.gmsTitle, attrs.gmsWidth, attrs.gmsHeight, element[0]);
					}
				})

				function drawChart(chartData, title, width, height, element) {
				        $('#container').highcharts({
                            chart: {
                                type: 'pie'
                            },
                            title: {
                                text: title
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
                                   series: [{
                                       data:
                                           chartData
                                   }]
                        });
                    }

			}
		};
	});
