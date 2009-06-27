# rtm.pl - add new tasks to rememberthemilk.com
#
# Install:
#   1) /script load rtm
#   2) /set rtm_email <your remember the milk email address>
#   3) /save
#
# Usage:
#   /rtm <task> <options>
#
#   where:
#     <task>     task name, e.g. "do laundry"
#     <options>  a string formatted like: [D: tomorrow E: 3 hours]
#
#       possible options (case insensitive):
#         D: due
#         E: time estimate
#         L: list
#         O: location
#         P: priority
#         R: repeat
#         S: tags (comma separated)
#         U: url
#
#   Examples:
#     Do the dishes for an hour, priority 2.
#       /rtm do dishes [E: 1 hour P: 2]
#
#     Do homework, due tomorrow.
#       /rtm homework [D: tomorrow]
#
# See also:
#   http://www.rememberthemilk.com/help/answers/sending/emailinbox.rtm
use strict;
use Irssi;

use vars qw($VERSION %IRSSI);

$VERSION = '1.0';
%IRSSI = (
  authors     => 'Matt "f0rked" Sparks',
  contact     => 'ms+irssi@quadpoint.org',
  name        => 'rtm',
  description => 'Add new tasks to rememberthemilk.com',
  license     => 'BSD',
  url         => 'http://quadpoint.org',
  changed     => '2007-09-08',
);


sub rtm_print
{
  my($text) = @_;
  my $window = Irssi::active_win();
  my $b = chr(2);
  $window->print("[${b}rtm${b}] $text", MSGLEVEL_CRAP);
}


sub add_task
{
  my($email, $text, $options_str) = @_;
  my %opt_list = (priority => "p",
                  due      => "d",
                  repeat   => "r",
                  estimate => "e",
                  tags     => "s",
                  location => "o",
                  url      => "u",
                  list     => "l");

  # parse out options
  my %options;

  my $key = "";
  for my $word (split / /, $options_str) {
    if ($word =~ /:$/) {
      $word =~ s/:$//;
      if (grep /^\Q$word\E$/i, keys(%opt_list)) {
        $key = $opt_list{$word};
      } elsif (grep /^\Q$word\E$/i, values(%opt_list)) {
        $key = $word;
      }
      next;
    }
    $options{$key} .= "$word " if $key ne "";
  }

  open SM, qq(| mail -s "$text" $email);
  for my $key (keys %options) {
    printf SM "%s: %s\n", $key, substr($options{$key}, 0, -1);
  }
  print SM "\n\n";
  close SM;
}


sub cmd_rtm
{
  my($data, $server, $witem) = @_;
  my $email_addr = Irssi::settings_get_str("rtm_email");
  if (!$email_addr) {
    rtm_print("your rememberthemilk.com email address is not set. ".
              "Use /set rtm_email <email address> to set it. Don't forget ".
              "to /save.");
    return;
  }

  # task options are specified in [ ] at the end of the data
  my($options) = $data =~ / \[\s*(.+?)\s*\]\s*$/;
  $data =~ s/ \[(.+?)\]\s*$//;
  $data =~ s/^\s*(.+?)\s*$/$1/;

  add_task($email_addr, $data, $options);

  if ($options) {
    rtm_print("$data [$options]");
  } else {
    rtm_print($data);
  }
}


Irssi::command_bind("rtm", "cmd_rtm");
Irssi::settings_add_str("rtm", "rtm_email", "");
