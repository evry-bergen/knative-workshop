var Gallery = require('./express-gallery-gcs');
var express = require('express');
var ejs = require('ejs');
var request = require('request');

// init express
var app = express();

// ejs 
app.set('view engine', 'ejs');

var options = {
    title : 'Booster image gallery'
};

const url = process.argv[2];
console.log('url : ', url);

app.use(express.static('./views'));

//takes creates a Gallery at /photo with the bucket that is in the arguments example  https://storage.googleapis.com/booster-photodump/.
// It will take the photos from / in the bucket and /thumb for thumbnails

app.use('/photos', Gallery(url, options));

//creates a endpoint where you can upload to the same bucket. 
//TODO: Need to finish the form.
app.get('/upload', (req, res) => res.render('upload'));
app.post('/upload', function (req, res) {
    res.send('test');
    
});
app.listen(8000, function(){
    console.log('Server is listening at port 8000');
});