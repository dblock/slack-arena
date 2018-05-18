$(document).ready(function() {
  // Slack OAuth
  var code = $.url('?code')
  if (code) {
    SlackArena.message('Working, please wait ...');
    $('#register').hide();
    $.ajax({
      type: "POST",
      url: "/api/teams",
      data: {
        code: code
      },
      success: function(data) {
        SlackArena.message('Team successfully registered!<br><br>Invite <b>@arena</b> to a channel.');
      },
      error: SlackArena.error
    });
  }
});
