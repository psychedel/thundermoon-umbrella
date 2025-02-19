// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.scss";

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html";

import {Socket} from "phoenix";
import LiveSocket from "phoenix_live_view";

let Hooks = {};
Hooks.ChatText = {
  updated() {
    this.el.value = "";
  }
};

let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks});
liveSocket.connect();

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"
