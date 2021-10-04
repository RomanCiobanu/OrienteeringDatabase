// Load all the channels within this directory and all subdirectories.
// Channel files must be named *_channel.js.

const channels = require.context('.', true, /_channel\.js$/)
channels.keys().forEach(channels)


 function hide() {
    obj = document.getElementById("create-competition").setAttribute("hidden", true);
    }

        function show() {
    obj = document.getElementById("create-competition").removeAttribute("hidden");
    }

    function myFunction(text) {

      aaa = document.getElementById("runner_category_id").value;
      if (aaa != "11") {
        show();

      } else { hide() }

    }
