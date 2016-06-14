var fixtureLoader, merge, q;

fixtureLoader = require('./fixtures-loader');

merge = require('merge');

q = require('q');

module.exports = function(app, options) {
  var promises;
  options = merge({
    fixturePath: '/fixtures/data/',
    append: false
  }, options);
  promises = [];
  if (!options.append) {
    promises.push(fixtureLoader.purgeDatabase(app.models));
  }
  promises.push(fixtureLoader.loadFixtures(app.models, options.fixturePath));
  app.loadFixtures = function() {
    return q.all(promises);
  };
  console.log('Starting loading');
  return app.loadFixtures().then(function() {
    return console.log('Done !');
  })["catch"](function(err) {
    return console.log('Erreurs : ', err);
  });
};
