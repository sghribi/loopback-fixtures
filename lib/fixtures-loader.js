var YAML, _, async, fs, loopback, merge, path, savedData;

_ = require('lodash');

async = require('async');

fs = require('fs');

loopback = require('loopback');

merge = require('merge');

path = require('path');

YAML = require('yamljs');

savedData = {};

module.exports = {
  replaceReferenceInObjects: function(object) {
    return _.each(object, function(value, key) {
      var identifier, ref, ref1, savedId;
      if (((ref = _.values(value)) != null ? ref[0] : void 0) === '@') {
        identifier = value.replace('@', '');
        savedId = savedData != null ? (ref1 = savedData[identifier]) != null ? ref1.id : void 0 : void 0;
        if (savedId) {
          return object[key] = savedId;
        } else {
          console.log('[ERROR] Please provide object for @' + identifier);
          return process.exit(1);
        }
      }
    });
  },
  applyHelpers: function(data) {
    var expandedData;
    expandedData = {};
    _.each(data, function(object, identifier) {
      var i, j, match, max, min, ref, ref1, regex, results;
      regex = /(\w+)\{(\d+)..(\d+)\}$/;
      match = identifier.match(regex);
      if ((match != null ? match.length : void 0) === 4) {
        identifier = match[1];
        min = parseInt(match[2]);
        max = parseInt(match[3]);
        results = [];
        for (i = j = ref = min, ref1 = max; ref <= ref1 ? j <= ref1 : j >= ref1; i = ref <= ref1 ? ++j : --j) {
          expandedData[identifier + i] = _.clone(object);
          results.push(_.each(object, function(value, key) {
            var newValue;
            if (typeof value === 'string') {
              newValue = value.replace('{@}', i.toString());
            } else {
              newValue = value;
            }
            return expandedData[identifier + i][key] = newValue;
          }));
        }
        return results;
      } else {
        return expandedData[identifier] = object;
      }
    });
    _.each(expandedData, function(object, identifier) {
      return _.each(object, function(value, key) {
        var e, error, fn;
        try {
          fn = eval(value);
          return expandedData[identifier][key] = fn;
        } catch (error) {
          e = error;
        }
      });
    });
    return expandedData;
  },
  loadFixtures: function(models, fixturesPath, callback) {
    var fixtureFolderContents, fixturePath, fixtures;
    fixturePath = path.join(process.cwd(), fixturesPath);
    fixtureFolderContents = fs.readdirSync(fixturePath);
    fixtures = fixtureFolderContents.filter(function(fileName) {
      return fileName.match(/\.yml$/);
    });
    return async.eachSeries(fixtures, (function(_this) {
      return function(fixture, nextFile) {
        var fixtureData;
        fixtureData = YAML.load(fixturePath + fixture);
        return async.eachOfSeries(fixtureData, function(modelData, modelName, nextModel) {
          modelData = _this.applyHelpers(modelData);
          return async.eachOfSeries(modelData, function(object, identifier, nextObject) {
            object = _this.replaceReferenceInObjects(object);
            return models[modelName].create(object, function(err, savedObject) {
              if (err) {
                return nextObject(err);
              }
              savedData[identifier] = savedObject;
              console.log('[' + modelName + '] - ' + identifier + ' imported (id : ' + savedObject.id + ')');
              return nextObject();
            });
          }, function(err) {
            if (err) {
              return nextModel(err);
            }
            return nextModel();
          });
        }, function(err) {
          if (err) {
            return nextFile(err);
          }
          return nextFile();
        });
      };
    })(this), function(err) {
      if (err) {
        return callback(err);
      }
      return callback();
    });
  }
};
