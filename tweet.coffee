http    = require "http"
url     = require "url"
path    = require "path"
fs      = require "fs"
events  = require "events"

load_static_file = (uri, response) ->
    filename = path.join process.cwd(), uri
    path.exists filename, (exists) ->
        if not exists
            response.writeHead 404, {"Content-Type": "text/plain"}
            response.end "404 Not Found\n"
        else
            fs.readFile filename, "binary", (err, file) ->
                if err
                    response.writeHead 500, {"Content-Type": "text/plain"}
                    response.end "#{err}\n"
                else
                    response.writeHead 200
                    response.end file, "binary"

get_tweets = () ->
    request = twitter_client.request "GET", "/1/statuses/public_timeline.json?count=10&include_entities=true", {"host": "api.twitter.com"}

    request.addListener "response", (response) ->
        body = ""
        response.addListener "data", (data) ->
            body += data
        response.addListener "end", ->
            tweets = JSON.parse body
            tweet_emitter.emit "tweets", tweets if tweets.length > 0
    request.end()

server = http.createServer (request, response) ->
    uri = url.parse(request.url).pathname
    if uri == "/stream"
        listener = tweet_emitter.addListener "tweets", (tweets) ->
            response.writeHead 200, {"Content-Type": "application/json"}
            response.end JSON.stringify tweets
            clearTimeout timeout
        
        blank_request =  ->
            response.writeHead 200, {"Content-Type": "text/plain"}
            response.end JSON.stringify []
            tweet_emitter.removeListener listener

        timeout = setTimeout blank_request, 10000
    else
        load_static_file uri, response

twitter_client = http.createClient 80, "api.twitter.com"

tweet_emitter = new events.EventEmitter()

setInterval get_tweets, 5000

server.listen 8080

console.log "Server running at http://localhost:8080"
