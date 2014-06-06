require('coffee-script/register');
var App = require('./lib/app'),
    port = (process.env.PORT || 3000);

console.log('Starting server on port ' + port + '.');
new App(port, function() {
  console.log('Ready.');
});
