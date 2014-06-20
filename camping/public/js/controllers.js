'use strict';

/* Controllers */

angular.module('myApp.controllers', [])
	.controller('GroupListController', ['$scope', '$http', '$routeParams', function($scope, $http, $routeParams) {
		$scope.scrapeGroup = function(index)
		{
			var group = $scope.groupList[index]
			group.loading = true;
			$http({method: 'GET', url: '/rest/scrapegroup', params: { groupid: group.group_id }}).
				success(function(data, status, headers, config) {
					group.loading = false;
					//todo: refresh last updated date
				}).
				error(function(data, status, headers, config) {
					group.loading = false;
				});
		}
	
		$http({method: 'GET', url: '/rest/groupList'}).
				success(function(data, status, headers, config) {
					$scope.groupList = data
				}).
				error(function(data, status, headers, config) {

				});
	}])
	.controller('GroupController', ['$scope', '$http', '$routeParams', function($scope, $http, $routeParams) {
		$scope.days = 0
		$scope.piechartData = "";
		$scope.$watch('days', function(newValue, oldValue) {
             requestPostsMostChart();
             requestLikesReceivedChart();
             requestDailyPostFreqChart();
             requestWeeklyPostFreqChart();
             requestWordCloud();
			 requestTop();
           });
		
		$http({method: 'GET', url: '/rest/group', params: {groupid : $routeParams.groupid}}).
				success(function(data, status, headers, config) {
					$scope.group = data
				}).
				error(function(data, status, headers, config) {

				});
		
		function requestPostsMostChart(){
			var daysToRequest = $scope.days
			if(daysToRequest == 0)
			{
				daysToRequest = 9999999
			}
			$http({method: 'GET', url: '/rest/postsmost', params: {days : daysToRequest, groupid : $routeParams.groupid}}).
				success(function(data, status, headers, config) {
					$scope.postsMostData = data
				}).
				error(function(data, status, headers, config) {

				});
		}

        function requestLikesReceivedChart(){
            var daysToRequest = $scope.days
            if(daysToRequest == 0)
            {
                daysToRequest = 9999999
            }
            $http({method: 'GET', url: '/rest/totallikesreceived', params: {days : daysToRequest, groupid : $routeParams.groupid}}).
                success(function(data, status, headers, config) {
                    $scope.likesReceivedData = data
                }).
                error(function(data, status, headers, config) {

                });
        }
        
        function requestDailyPostFreqChart(){
            var daysToRequest = $scope.days
            if(daysToRequest == 0)
            {
                daysToRequest = 9999999
            }
            $http({method: 'GET', url: '/rest/dailypostfrequency', params: {days : daysToRequest, groupid : $routeParams.groupid}}).
                success(function(data, status, headers, config) {
                    $scope.dailyFreqData = data
                }).
                error(function(data, status, headers, config) {

                });
        }
	
        function requestWeeklyPostFreqChart(){
            var daysToRequest = $scope.days
            if(daysToRequest == 0)
            {
                daysToRequest = 9999999
            }
            $http({method: 'GET', url: '/rest/weeklypostfrequency', params: {days : daysToRequest, groupid : $routeParams.groupid}}).
                success(function(data, status, headers, config) {
                    $scope.weeklyFreqData = data
                }).
                error(function(data, status, headers, config) {

                });
        } 
    
        function requestWordCloud(){
            var daysToRequest = $scope.days
            if(daysToRequest == 0)
            {
                daysToRequest = 9999999
            }
            $http({method: 'GET', url: '/rest/wordcloud', params: {days : daysToRequest, groupid : $routeParams.groupid}}).
                success(function(data, status, headers, config) {
                    $scope.wordCloudData = data
                }).
                error(function(data, status, headers, config) {
                
                });
        }
	
		function requestTop(){
			var daysToRequest = $scope.days
			if(daysToRequest == 0)
			{
				daysToRequest = 9999999
			}
			$http({method: 'GET', url: '/rest/toppost', params: {days : daysToRequest, groupid : $routeParams.groupid, num: 5}}).
				success(function(data, status, headers, config) {
					$scope.topPosts = data
				}).
				error(function(data, status, headers, config) {

				});
		}
		
		$scope.setDays = function(newday)
		{
			$scope.days = newday;
		}

	}])
	.controller('AboutController', ['$scope', function($scope) {

	}])
    .controller('GlanceController', ['$scope', '$http', '$routeParams', function($scope, $http, $routeParams) {
        //var user = $scope.user[index]

        $http({method: 'GET', url: '/rest/user'}).
                success(function(data, status, headers, config) {
                    $scope.user = data
                }).
                error(function(data, status, headers, config) {

                });
    }]);
