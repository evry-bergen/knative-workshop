var fs = require('fs');
var resolve = require('path').resolve;

module.exports = function(directory, callback) {
  fs.stat(resolve(directory), function(err, stat) {
    if (err) {
      return callback(false);
    }
    callback(stat.isDirectory());
  });
};

module.exports.sync = function(directory) {
  try {
    return fs.statSync(resolve(directory)).isDirectory();
  } catch (e) {
    return false;
  }
};
