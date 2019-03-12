const {Storage} = require('@google-cloud/storage');
const imagemagick = require('imagemagick-stream');

const gcs = new Storage({
  projectId:process.env.PROJECT,
});

const srcBucket = gcs.bucket(process.env.SRCBUCKET);
const dstBucket = gcs.bucket(process.env.DSTBUCKET);



module.exports.thumbnailCreator = (event, callback) => {
console.log('Events',event);
  const pubsubMessage = event.data;
  const message = JSON.parse(Buffer.from(pubsubMessage.data, 'base64').toString());
  var filename = message.name;
  console.log(`Processing Original: gs://${process.env.SRCBUCKET}/${filename}`);
  const sizes = ["256x256"];
  const gcsSrcObject = srcBucket.file(filename);

  Promise.all(sizes.map((size) => {
        let destfilename = filename;
        let gcsDstObject = dstBucket.file(destfilename);
        let gcsThumbObject = dstBucket.file('thumbs/'+destfilename);
        let srcStream = gcsSrcObject.createReadStream();
        let dstStream = gcsDstObject.createWriteStream();
        let thumbStream = gcsThumbObject.createWriteStream();
        let resize = imagemagick().resize(size).quality(90);


        srcStream.pipe(dstStream);

        srcStream.pipe(resize).pipe(thumbStream);
        return new Promise((resolve, reject) => {
          dstStream
          .on("error", (err) => {
              console.log(`Error: ${err}`);
              reject(err);
          })
          .on("finish", () => {
              console.log(`Success: copied ${filename} to gallery`);

          });
          thumbStream
          .on("error", (err) => {
              console.log(`Error: ${err}`);
              reject(err);
          })
          .on("finish", () => {
              console.log(`Success: created Thumbnail for ${filename} in gallery`);
          });
          resolve();
      });




  })).then(function() {
    console.log("All successful");
    callback();
  }).catch(function(err) {
    console.log("At least one failure");
    callback(err);
  });
  };
