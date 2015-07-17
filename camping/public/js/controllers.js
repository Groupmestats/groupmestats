'use strict';

/* Controllers */

angular.module('gmStats.controllers', [])
	.controller('GroupListController', ['$scope', '$http', '$routeParams', '$location', function($scope, $http, $routeParams, $location) {
		$scope.setScraping = function(groupId)
		{
			$location.path("/group").search({groupid: groupId})
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
}])
	.controller('GroupController', ['$scope', '$http', '$routeParams', '$sce', function($scope, $http, $routeParams, $sce) {
		$scope.days = 0
		$scope.piechartData = "";
		$scope.ngramloading = false;

		$http({method: 'GET', url: '/rest/groupfacts', params: {groupid : $routeParams.groupid}}).
			success(function(data, status, headers, config) {
					$scope.group = data
					$scope.groupurl = "https://192.168.4.50/kibana/#/dashboard/Groupmestats?embed&_g=(refreshInterval:(display:Off,section:0,value:0),time:(from:now-2y,mode:quick,to:now))&_a=(filters:!(),panels:!((col:1,id:'Groupmestats:-Messages-over-time-by-User',row:13,size_x:12,size_y:6,type:visualization),(col:1,id:'Groupmestats:-Posts-per-User',row:3,size_x:5,size_y:5,type:visualization),(col:4,id:'Groupmestats:-Average-Likes-per-post',row:1,size_x:3,size_y:2,type:visualization),(col:1,id:'Groupmestats:-Total-Posts',row:1,size_x:3,size_y:2,type:visualization),(col:1,id:'Groupmestats:-Most-liked-Images',row:8,size_x:6,size_y:5,type:search),(col:6,id:'Groupmestats:-Most-liked-Posts',row:3,size_x:7,size_y:5,type:search),(col:10,id:'Groupmestats:-Total-Images',row:1,size_x:3,size_y:2,type:visualization),(col:7,id:'Groupmestats:-Active-Users',row:1,size_x:3,size_y:2,type:visualization),(col:7,id:'Groupmestats:-Unique-users-posting-over-time',row:8,size_x:6,size_y:5,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:group_id%3D" + data.group_id + ")),title:Groupmestats)"
					$scope.groupfactsUrl = $sce.trustAsResourceUrl($scope.groupurl);
			}).
			error(function(data, status, headers, config) {

			});
		
		$scope.setDays = function(newday)
		{
			 $scope.groupurl = "https://192.168.4.50/kibana/#/dashboard/Groupmestats?embed&_g=(refreshInterval:(display:Off,section:0,value:0),time:(from:now-" + newday + ",mode:quick,to:now))&_a=(filters:!(),panels:!((col:1,id:'Groupmestats:-Messages-over-time-by-User',row:13,size_x:12,size_y:6,type:visualization),(col:1,id:'Groupmestats:-Posts-per-User',row:3,size_x:5,size_y:5,type:visualization),(col:4,id:'Groupmestats:-Average-Likes-per-post',row:1,size_x:3,size_y:2,type:visualization),(col:1,id:'Groupmestats:-Total-Posts',row:1,size_x:3,size_y:2,type:visualization),(col:1,id:'Groupmestats:-Most-liked-Images',row:8,size_x:6,size_y:5,type:search),(col:6,id:'Groupmestats:-Most-liked-Posts',row:3,size_x:7,size_y:5,type:search),(col:10,id:'Groupmestats:-Total-Images',row:1,size_x:3,size_y:2,type:visualization),(col:7,id:'Groupmestats:-Active-Users',row:1,size_x:3,size_y:2,type:visualization),(col:7,id:'Groupmestats:-Unique-users-posting-over-time',row:8,size_x:6,size_y:5,type:visualization)),query:(query_string:(analyze_wildcard:!t,query:group_id%3D" + $scope.group.group_id + ")),title:Groupmestats)"
                         $scope.groupfactsUrl = $sce.trustAsResourceUrl($scope.groupurl);
		}
	}])
	.controller('AboutController', ['$scope', function($scope) {

	}])
    .controller('GlanceController', ['$scope', '$http', '$routeParams', function($scope, $http, $routeParams) {
    }])
	.controller('UserController', ['$scope', '$http', '$routeParams', function($scope, $http, $routeParams) {
    }])
	;
