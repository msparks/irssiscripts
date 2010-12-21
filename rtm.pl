# rtm.pl - add new tasks to rememberthemilk.com
#
# Install:
#   1) /script load rtm
#   2) /set rtm_email <your remember the milk email address>
#   3) /save
#
# Usage:
#   /rtm <task>
#
#   where:
#     <task>     task name, e.g. "do laundry"
#                Uses RTM's 'Smart Add' for due dates, priority, etc.
#
#   Examples:
#     Do the dishes for an hour, priority 2.
#       /rtm do dishes =1 hour !2
#
#     Do homework, due tomorrow.
#       /rtm homework ^tomorrow
#
# See also:
#   http://www.rememberthemilk.com/services/email/
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
  changed     => '2010-12-20',
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
  my($email, $text) = @_;
  open SM, qq(| mail -s "$text" $email);
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

  add_task($email_addr, $data);

  rtm_print($data);
}


Irssi::command_bind("rtm", "cmd_rtm");
Irssi::settings_add_str("rtm", "rtm_email", "");
