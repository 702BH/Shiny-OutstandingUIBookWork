# chapter11_example_app
library(httpuv)
library(websocket)


s <- startServer("127.0.0.1", 8080,
                 list(
                   onWSOpen = function(ws){
                     # The ws object is a WebSocket object
                     cat("Server connection opened.\n")
                     
                     ws$onMessage(function(binary, message){
                       cat("Server recieved message:", message, "\n")
                       ws$send("Hello client!")
                     })
                     ws$onClose(function(){
                       cat("Server connection closed.\n")
                     })
                     
                   }
                 ))


# set the client
ws <- WebSocket$new("ws://127.0.0.1:8080/")
ws$onMessage(function(event){
  cat("Client recieved message:", event$data, "\n")
})

# wait for a moment before running next line
ws$send("Hello Server!")

ws$close()

# Handle the websocket server
ws_handler <- function(ws) {
  # the ws object is a WebSocket object
  cat("New connection opened.\n")
  
  ws$onMessage(function(binary, message){
    # server logic
    
    # capture client message
    input_message <- jsonlite::fromJSON(message)
    
    # debug
    print(input_message)
    cat("Number of bins:", input_message$value, "\n")
    
    # create plot
    hist(rnorm(input_message$value))
    
    output_message <- jsonlite::toJSON(
      list(
        val = sample(0:100, 1),
        message = "Thanks client! I updated the plot..."
      ),
      pretty = TRUE,
      auto_unbox = TRUE
    )
    ws$send(output_message)
    
    # debug
    cat(output_message)
    
    ws$onClose(function(){
      cat("Server connection closed.\n")
    })
  })
  
}


# not sure if to add
http_response <- function(req){
  list(
    status = 200L,
    headers = list(
      'Content-Type'='text/html'
    ),
    body = "Hello world!"
  )
}

stopAllServers()

startServer(
  "127.0.0.1",
  8080,
  list(call = http_response, onWSOpen = ws_handler)
)




## attempting the real app

# initialise a websocket server
websocket_server <- function(host = "127.0.0.1", port=8080){
  # set the server
  httpuv::startServer(
    host,
    port,
    list(
      onWSOpen = function(ws){
        # the ws object is a websocket object
        cat("New connection opened.\n")
        # capture client messages
        ws$onMessage(function(binary, message){
          print(binary)
          cat("Server recieved message:", message, "\n")
          ws$send("Hello client!")
        })
        ws$onClose(function(){
          cat("Server connection closed.\n")
        })
      }
    )
  )
  
  
}

# initlaise a client websocket 
websocket_client <- function(host="127.0.0.1", port = 8080){
  ws <- websocket::WebSocket$new(sprintf("ws://%s:%s/", host, port))
  # capture server messages
  ws$onMessage(function(event){
    cat("Client recieved message:", event$data,"\n")
  })
  ws
}

# create demo httpuv app
httpuv_app <- function(delay = NULL){
  s <- httpuv::startServer(
    "127.0.0.1",
    8080,
    list(
      call = function(req){
        list(
          status = 200L,
          headers = list(
            'Content-Type'='text/html'
          ),
          body ='
                      <!DOCTYPE HTML>
            <html lang="en">
              <head>
                <script language="javascript">
                  document.addEventListener("DOMContentLoaded", function(event) {
                    var gauge = document.getElementById("mygauge");
                    // Initialize client socket connection
                    var mySocket = new WebSocket("ws://127.0.0.1:8080");
                    mySocket.onopen = function (event) {
                      // do stuff
                    };
                    // update the gauge value on server message
                    mySocket.onmessage = function (event) {
                      var data = JSON.parse(event.data);
                      gauge.value = data.val;
                    };

                    var sliderWidget = document.getElementById("slider");
                    var label = document.getElementById("sliderLabel");
                    label.innerHTML = "Value:" + slider.value; // init
                    // on change
                    sliderWidget.oninput = function() {
                      var val = parseInt(this.value);
                      mySocket.send(
                        JSON.stringify({
                          value: val,
                          message: "New value for you server!"
                        })
                      );
                      label.innerHTML = "Value:" + val;
                    };
                  });
                </script>
                <title>Websocket Example</title>
              </head>
              <body>
                <div>
                  <input type="range" id="slider" name="volume" min="0" max="100">
                  <label for="slider" id ="sliderLabel"></label>
                </div>
                <br/>
                <label for="mygauge">Gauge:</label>
                <meter id="mygauge" min="0" max="100" low="33" high="66" optimum="80" value="50"></meter>
              </body>
            </html>
          '
        )
      },
      onWSOpen = function(ws){
        # the ws object is a WebSocket object
        cat("New connection opened.\n")
        # capture client messages
        ws$onMessage(function(binary, message){
          
          # create plot
          input_message <- jsonlite::fromJSON(message)
          print(input_message)
          cat("Number of bins:", input_message$value, "\n")
          hist(rnorm(input_message$value))
          if (!is.null(delay)) Sys.sleep(delay)
            
            # update guage widget
          output_message <- jsonlite::toJSON(
            list(
              val = sample(0:100, 1),
              message = "Thanks client! I updated the plot..."
            ),
            pretty = TRUE,
            auto_unbox = TRUE
          )
          ws$send(output_message)
          cat(output_message)
        })
        ws$onClose(function(){
          cat("Server connection close.\n")
        })
      }
    )
  )
  s
}
httpuv_app()
stopAllServers()
