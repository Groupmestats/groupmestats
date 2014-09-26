'use strict';

/* Controllers */

angular.module('gmStats.controllers', [])
	.controller('GroupListController', ['$scope', '$http', '$routeParams', '$location', function($scope, $http, $routeParams, $location) {
		$scope.scraping = false;
		
		$scope.setScraping = function(groupId)
		{
			$scope.scraping = true;
			$location.url = "./#/group?groupid=" + groupId
		}
		
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
       $scope.refreshGroupList = function(index)
       {
          $scope.groupListLoading = true;
          $http({method: 'GET', url: '/rest/refreshGroupList'}).
              success(function(data, status, headers, config) {
                  $scope.groupListLoading = false;
              }).
              error(function(data, status, headers, config) {
                  $scope.groupListLoading = false;
              });
       }
       $scope.scrapeAll = function()
       {
          $http({method: 'GET', url: '/rest/scrapeall'}).
              success(function(data, status, headers, config) {
              }).
              error(function(data, status, headers, config) {
              });
       }
}])
	.controller('GroupController', ['$scope', '$http', '$routeParams', function($scope, $http, $routeParams) {
		$scope.days = 0
		$scope.piechartData = "";
		$scope.ngramloading = false;

        hs.allowMultipleInstances = false;
        hs.align = "center";
        hs.addEventListener(document, 'click', function(e) {
           e = e || window.event;
           var target = e.target || e.srcElement;

           // if the target element is not within an expander but there is an expander on the page, close it
           if (!hs.getExpander(target) && hs.getExpander()) hs.close();
        });

		requestGroupStats();
		requestGroupJoinRate();
		requestDailyPostFreqChart();
		requestWeeklyPostFreqChart();
		
		$http({method: 'GET', url: '/rest/group', params: {groupid : $routeParams.groupid}}).
			success(function(data, status, headers, config) {
				$scope.group = data
			}).
			error(function(data, status, headers, config) {

			});
		
		var offset = new Date().getTimezoneOffset();
		offset = offset / 60;
		$http({method: 'GET', url: '/rest/heatdata', params: {groupid : $routeParams.groupid, timezone: offset}}).
			success(function(data, status, headers, config) {
				$scope.heatdata = data
			}).
			error(function(data, status, headers, config) {

			});

        $scope.$watch('days', function(newValue, oldValue) {
             requestPostsMostChart();
			 requestTop();
             //requestUser();
           });

		function requestGroupStats() {
			$http({method: 'GET', url: '/rest/groupfacts', params: {groupid : $routeParams.groupid}}).
				success(function(data, status, headers, config) {
						$scope.groupfacts = data
				}).
				error(function(data, status, headers, config) {

				});
		}		
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
        
//        function requestUser(){
//            var daysToRequest = $scope.days
//            if(daysToRequest == 0)
//            {
//                daysToRequest = 9999999
//            }
//            $http({method: 'GET', url: '/rest/usergroup', params: {days: daysToRequest, groupid : $routeParams.groupid}}).
//               success(function(data, status, headers, config) {
//                   $scope.userData = data
//               }).
//               error(function(data, status, headers, config) {
//
//               });
//        }
//       
        function requestGroupJoinRate(){
           var daysToRequest = $scope.days
           if(daysToRequest == 0)
           {
               daysToRequest = 9999999
           }
           $http({method: 'GET', url: '/rest/groupjoinrate', params: {days : daysToRequest, groupid : $routeParams.groupid}}).
               success(function(data, status, headers, config) {
                   $scope.joinDateData = data[0]
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

            var offset = new Date().getTimezoneOffset();
            offset = offset / 60;

            $http({method: 'GET', url: '/rest/dailypostfrequency', params: {days : daysToRequest, groupid : $routeParams.groupid, timezone: offset}}).
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
			$http({method: 'GET', url: '/rest/toppost', params: {days : daysToRequest, groupid : $routeParams.groupid, numpost: 10, numimage: 9}}).
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
	   
        // Time zone offset 
        var offset = new Date().getTimezoneOffset();
        offset = offset / 60;

        $http({method: 'GET', url: '/rest/user', params: {timezone: offset}}).
                success(function(data, status, headers, config) {
                    $scope.user = data
                }).
                error(function(data, status, headers, config) {

                });
    }])
	.controller('UserController', ['$scope', '$http', '$routeParams', function($scope, $http, $routeParams) {

        // Time zone offset
        var offset = new Date().getTimezoneOffset();
        offset = offset / 60;
 
        $http({method: 'GET', url: '/rest/user',params: {timezone: offset, userid : $routeParams.userid, groupid : $routeParams.groupid}}).
                success(function(data, status, headers, config) {
                    $scope.user = data
                }).
                error(function(data, status, headers, config) {

                });
    }])
	;
