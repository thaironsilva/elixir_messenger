// Connects to the chat socket using the token rendered into the page.
// The token is only present once the user is authenticated.

import {Socket} from "phoenix"

let socket = null

if (window.userToken) {
  socket = new Socket("/socket", {params: {token: window.userToken}})
  socket.connect()
}

export default socket
