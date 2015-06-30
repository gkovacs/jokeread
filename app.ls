require! {
  express
  path
  getsecret
}

bing_api_key = getsecret 'bing_api_key'
Bing = require('node-bing-api')({accKey: bing_api_key})

app = express()

app.set 'port', (process.env.PORT || 8080)

app.use express.static(path.join(__dirname, ''))

get_image_url = (query, callback) ->
  Bing.images query, {}, (error, res2, body) ->
    callback body.d.results[0].MediaUrl

app.get '/image', (req, res) ->
  get_image_url req.query.name, (imgurl) ->
    res.send imgurl

app.listen app.get('port'), '0.0.0.0'
