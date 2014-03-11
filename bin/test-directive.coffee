define [
	'jquery',
	'angular',
	'appmodule'
], =>
	appModule = angular.module 'app'
	appModule.directive 'test-directive', [() ->
		scope: 'isolate'
		restrict: "A"
		scope:
		{

		}

		replace: true
		template:
		'
						<div></div>
						
					'

		link: ($scope, $element, $attrs) ->
			# ---------------------------------------------------------------- Public Variables

			# ---------------------------------------------------------------- Private Variables

			# ---------------------------------------------------------------- Init Function
			init = () ->
				undefined

			# ---------------------------------------------------------------- Public Functions

			# ---------------------------------------------------------------- Private Functions

			# ---------------------------------------------------------------- Handler Functions


			# ---------------------------------------------------------------- Helper Functions


			# ---------------------------------------------------------------- init()
			init()
	]