angular.module('Relics', ['prevent-default', 'ozService', 'ngSanitize'])

angular.module('Relics').config ($httpProvider) ->
  $httpProvider.defaults.headers.common['X-CSRF-Token'] =
    angular.element(
      document.querySelector('meta[name=csrf-token]')
    ).attr('content')
