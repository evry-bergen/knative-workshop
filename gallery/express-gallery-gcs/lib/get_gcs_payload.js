var https = require('https');
var xmlParse = require('xml2js').parseString;
var path = require('path');
var isImage = require(__dirname + '/is-image');
var objectAssign = require('object-assign');


module.exports = function(bucket, userOptions, callback) {

  var req = https.request(bucket, function(response) {
    var xml = '';

    response.on('data', function(data) {
      xml += data;
    });

    response.on('end', function() {

      xmlParse(xml, function(err, result) {
        var photoObj = {};
        //console.log('result',result);
        result.ListBucketResult.Contents.forEach(function(item) {
          var filePath = path.parse(item.Key[0]);
          var dir = filePath.dir || 'root';
          var name = filePath.base;

          if (!photoObj[dir]) {
            photoObj[dir] = [name];
          } else {
            photoObj[dir].push(name);
          }

        });

        var photoObjects = [];

        //console.log('PhotoObject', photoObj);

        photoObj.root.forEach(function(file) {
          var photoObject = {};

          if (isImage(file)) {

            if (photoObj.previews) {
              photoObject.src = bucket + 'previews/' + file;
              photoObject.downloadUrl = bucket + file;
            } else {
              photoObject.src = bucket + file;
            }

            if (photoObj.thumbs) photoObject.thumb =bucket + 'thumbs/' + file;

            photoObjects.push(photoObject);

          }
        });

        //console.log('PhotoOBJ ', photoObjects);

          var mandatorySettings = {
            dynamic: true,
            dynamicEl: photoObjects,
            closable: false,
            escKey: false,
          };

          var optionalSettings = {
            download: true,
            thumbnail: !!photoObj.thumbs
          };

          var payload = objectAssign(optionalSettings, userOptions, mandatorySettings);

          callback(payload);

      });
    });

  })

  req.on('error', function(err){
    throw err;  //add message
  })

  req.end();

};
