var chai = require('chai');
var expect = chai.expect;

var directoryExists = require(__dirname + '/../index.js');

describe('The directoryExists function', function() {
  it('return true if a directory exists and is a directory', function(done) {
    var result = directoryExists(__dirname, function(result) {
    expect(result).to.eql(true);
    setImmediate(done);
    });
  });

  it('should return false if path does not exist', function(done) {
    var result = directoryExists(__dirname + '/fakeDirectory', function(result) {
    expect(result).to.eql(false);
    setImmediate(done);
    });
  });

  it('should return false if path is a file', function(done) {
    var result = directoryExists(__dirname + '/directory-exists-test.js', function(result) {
    expect(result).to.eql(false);
    setImmediate(done);
    });
  });
});

describe('The directoryExists.sync function', function() {
  it('return true if a directory exists and is a directory', function() {
    var result = directoryExists.sync(__dirname);
    expect(result).to.eql(true);
  });

  it('should return false if path does not exist', function() {
    var result = directoryExists.sync(__dirname + '/fakeDirectory');
    expect(result).to.eql(false);
  });

  it('should return false if path is a file', function() {
    var result = directoryExists.sync(__dirname + '/directory-exists-test.js');
    expect(result).to.eql(false);
  });
});
