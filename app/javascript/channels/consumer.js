// Action Cable provides the framework to deal with WebSockets in Rails.
// You can generate new channels where WebSocket features live using the `bin/rails generate channel` command.

import { createConsumer } from "@rails/actioncable"

export default createConsumer()

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

