# hilight_notice.pl for irssi
#
# This script changes the message level for notices to the level used by private
# messages. Notices go to the status window by default, so when this script is
# loaded, the status window will be hilighted like a query window.
#
# Based off of active_notice.pl by Geert.

use strict;
use Irssi;

use vars qw($VERSION %IRSSI);

$VERSION = '1.1';
%IRSSI = (
  authors     => 'Matt "f0rked" Sparks',
  contact     => 'ms+irssi@quadpoint.org',
  name        => 'hilight_notice',
  description => 'hilight status window on notices',
  license     => 'GPLv2',
  url         => 'http://quadpoint.org',
  changed     => '2006-12-15',
);


sub hilight_notice
{
  my ($dest, $text, $stripped) = @_;
  my $server = $dest->{server};

  return if (!$server || !($dest->{level} & MSGLEVEL_NOTICES));

  # Change the message level to level used by PRIVMSGs
  my $witem = $server->window_item_find($dest->{target});
  $witem->print($text, MSGLEVEL_MSGS) if $witem;
  Irssi::print($text, MSGLEVEL_MSGS) if !$witem;
  Irssi::signal_stop();
}


Irssi::signal_add("print text", "hilight_notice");
