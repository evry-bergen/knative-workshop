# directory-exists [![Build Status](https://travis-ci.org/timmydoza/directory-exists.svg?branch=master)](https://travis-ci.org/timmydoza/directory-exists)

> Check if a directory exists - synchronously or asynchronously

## Install

```
$ npm install --save directory-exists
```

## Usage:

### Asynchronous

```js
const directoryExists = require('directory-exists');
directoryExists(directory, callback(result) {
  // returns boolean
};
```

### Synchronous

```js
const directoryExists = require('directory-exists');

directoryExists.sync(directory); //retuns boolean
```

## Why not use the `fs.exists`?
Because asynchronous `fs.exists` is [deprecated](https://nodejs.org/api/fs.html#fs_fs_exists_path_callback). Synchronous `fs.existsSync` is still [fine](https://nodejs.org/api/fs.html#fs_fs_existssync_path) to use, but this library does _both_, sync and async.

## License

MIT © timmydoza
