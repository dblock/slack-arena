var SlackArena = {};

$(document).ready(function() {

  SlackArena.message = function(text) {
    $('#messages').fadeOut('slow', function() {
      $('#messages').fadeIn('slow').html(text)
    });
  };

  SlackArena.errorMessage = function(message) {
    SlackArena.message(message)
    $('#messages').addClass('has-error');
  };

  SlackArena.error = function(xhr) {
    try {
      var message;
      if (xhr.responseText) {
        var rc = JSON.parse(xhr.responseText);
        if (rc && rc.error) {
          message = rc.error;
        } else if (rc && rc.message) {
          message = rc.message;
          if (message == 'invalid_code') {
            message = 'The code returned from the OAuth workflow was invalid.'
          } else if (message == 'code_already_used') {
            message = 'The code returned from the OAuth workflow has already been used.'
          }
        } else if (rc && rc.error) {
          message = rc.error;
        }
      }

      SlackArena.message(message || xhr.statusText || xhr.responseText || 'Unexpected Error');

    } catch(err) {
      SlackArena.message(err.message);
    }
  };

});
