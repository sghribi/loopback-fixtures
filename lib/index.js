var fixtureLoader, fixturePath;

fixtureLoader = require('./fixtures-loader');

fixturePath = '/fixtures/data/';

module.exports = function(app, options) {
  return fixtureLoader.loadFixtures(app.models, fixturePath, function(ern, result) {
    return console.log(arguments);
  });
};
