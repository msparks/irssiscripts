# grumble.pl provides sane integration of Irssi with Growl [http://growl.info/]
# and Mumbles [http://www.mumbles-project.org/]. These programs both support the
# Growl network protocol that the Perl module Net::Growl uses to communicate.
#
# This script supports multiple targets, each with a potentially unique Growl
# password.
#
# SETTINGS
# Targets are specified in the "grumble_targets" setting:
#   /set grumble_targets localhost:mypass
#     sends messages to an instance running on localhost with password "mypass"
#   /set grumble_targets localhost:mypass othermachine:otherpass
#     sends messages to two separate machines with different passwords
#
# To turn on/off notifications while /away, toggle the setting
# 'grumble_notify_when_away'. Default: OFF.
#
# To enable/disable notifications for the active window, toggle the setting
# 'grumble_notify_for_active_window'. Default: ON.
use strict;
use Irssi;
use Net::Growl;
use IO::Socket::INET;

use vars qw($VERSION %IRSSI);

$VERSION = '1.2';
%IRSSI = (
  authors     => 'Matt "f0rked" Sparks',
  contact     => 'ms+irssi@quadpoint.org',
  name        => 'grumble',
  description => 'Irssi integration with growl and mumbles',
  license     => 'BSD',
  url         => 'http://quadpoint.org',
  changed     => '2009-03-04'
);


sub send_growl
{
  my($host, $password, $title, $text) = @_;
  my %addr = (PeerAddr => $host,
              PeerPort => Net::Growl::GROWL_UDP_PORT,
              Proto    => "udp");
  my $s = IO::Socket::INET->new(%addr) || die "Could not create socket: $!\n";
  my $r = Net::Growl::RegistrationPacket->new(application => "grumble.pl",
                                              password    => $password);
  $r->addNotification();
  print $s $r->payload();

  # send a notification
  my $p = Net::Growl::NotificationPacket->new(application => "grumble.pl",
                                              title       => $title,
                                              description => $text,
                                              priority    => 2,
                                              sticky      => 'True',
                                              password    => $password);
  print $s $p->payload();
  close $s;
}


sub send_to_all
{
  my($title, $text) = @_;
  my @targets = split / /, Irssi::settings_get_str("grumble_targets");

  for my $target (@targets) {
    my($host, $pass) = split /:/, $target, 2;
    send_growl($host, $pass, $title, $text);
  }
}


sub event_privmsg
{
  my($server, $msg, $nick, $address, $target) = @_;
  my $active = Irssi::active_win();
  return if ($active->get_active_name() eq $nick &&
             !Irssi::settings_get_bool("grumble_notify_for_active_window"));
  send_to_all("irssi: $nick", "new private message from $nick");
}


sub event_printtext
{
  my ($dest, $text, $stripped) = @_;
  my $server = $dest->{server};

  my $active = Irssi::active_win();
  return if ($active->get_active_name() eq $dest->{window}->get_active_name() &&
             !Irssi::settings_get_bool("grumble_notify_for_active_window"));

  return if ($server->{usermode_away} &&
             !Irssi::settings_get_bool("grumble_notify_when_away"));

  # Run the command if we're hilighted
  if (($dest->{level} & (MSGLEVEL_HILIGHT)) &&
      ($dest->{level} & MSGLEVEL_NOHILIGHT) == 0) {
    send_to_all("irssi: hilight", $stripped);
  }
}


Irssi::signal_add("message private", \&event_privmsg);
Irssi::signal_add("print text", \&event_printtext);

Irssi::settings_add_str("grumble", "grumble_targets", "localhost:grwlpass");
Irssi::settings_add_bool("grumble", "grumble_notify_when_away", 0);
Irssi::settings_add_bool("grumble", "grumble_notify_for_active_window", 1);
