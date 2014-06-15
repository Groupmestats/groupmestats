'use strict';

/* Directives */


angular.module('myApp.directives', []).
	directive('gmsPiechart', function() {
		return{
			scope: {
				gmsData: '=',
				gmsTitle: '@'
			},
			link: function (scope, element, attrs) {
				scope.$watch('gmsData', function(gmsData) {
					if(gmsData)
					{
						drawChart(gmsData, attrs.gmsTitle, attrs.gmsWidth, attrs.gmsHeight);
					}
				})
				var chart = new google.visualization.PieChart(element[0]);

				function drawChart(chartData, title, width, height) {
					var data = new google.visualization.DataTable();
					data.addColumn('string', 'Topping');
					data.addColumn('number', 'Slices');
					data.addRows(chartData);

					var options = {'title':title};
					
					chart.draw(data, options);
				}

			}
		};
	});
