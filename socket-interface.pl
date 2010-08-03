use strict;
use IO::Socket;
use Fcntl;
use Irssi;
use Time::Format qw(%strftime);
#use Data::Dumper;

use vars qw($VERSION %IRSSI);

$VERSION = '1.0.1';
%IRSSI = (
  authors     => 'Matt "f0rked" Sparks, Miklos Vajna',
  contact     => 'ms+irssi@quadpoint.org',
  name        => 'socket-interface',
  description => 'provides an interface to irssi via unix sockets',
  license     => 'GPLv2',
  url         => 'http://quadpoint.org',
  changed     => '2009-01-22',
);

my $socket = $ENV{"HOME"} . "/.irssi/socket";

# create the socket
unlink $socket;
my $server = IO::Socket::UNIX->new(Local  => $socket,
                                   Type   => SOCK_STREAM,
                                   Listen => 5) or die $@;

# set this socket as nonblocking so we can check stuff without interrupting
# irssi.
nonblock($server);


# method to set a socket handle as nonblocking
sub nonblock
{
  my($fd) = @_;
  my $flags = fcntl($fd, F_GETFL, 0);
  fcntl($fd, F_SETFL, $flags | O_NONBLOCK);
}


# check the socket for data and act upon it
sub check_sock
{
  my $msg;
  if (my $client = $server->accept()) {
    $client->recv($msg, 1024);
    #print "Got message: $msg" if $msg;

    if ($msg =~ /^activelog ?(\d*)$/) {
      my $lines = ($1) ? $1 : 5;
      #print "found lines: $lines";
      #print Dumper $win;
      my $ref = get_active_refnum();
      my $name = get_active_name();
      my $tag = get_active_tag();
      my $fname = get_log_fname(get_active_tag(), get_active_name());
      my $log = tail_log($fname, $lines);
      if (!$log) {
        $log = "Could not open log";
      }

      chomp $log;
      $client->send(">> $ref: $name ($tag)\n$log");
    } elsif ($msg eq "windowlist") {
      # send back a list of the windows
      my $out;
      for (2 .. last_refnum()) {
        $out .= ("$_: " . name_of($_) . " (".tag_of($_).") " .
                 level_of($_) . "\n");
      }

      chomp $out;
      $client->send($out);
    } elsif ($msg =~ /^switch (\d+)$/) {
      $client->send(switch_to($1));
    } elsif ($msg =~ /^get_lines (\d+)$/) {
      $client->send(get_lines($1));
    } elsif ($msg =~ /^send (.+)$/) {
      $client->send(msg_active($1));
    } elsif ($msg =~ /^command (.+)$/) {
      $client->send(command($1));
    }
  }
}


# returns the name of the active window item. If there is no active window
# item, return the name of the window itself.
sub get_active_name
{
  my $win = Irssi::active_win();
  return $win->get_active_name();
}


# returns the server tag of the active window item
sub get_active_tag
{
  my $win = Irssi::active_win();
  return ($win->{active}) ? $win->{active}->{server}->{tag} : "";
}


# returns refnum of active window
sub get_active_refnum
{
  return (Irssi::active_win())->{refnum};
}


# switches windows to the given refnum
sub switch_to
{
  my($refnum) = @_;
  my $window = Irssi::window_find_refnum($refnum);
  if ($window) {
    $window->set_active();
    return 1;
  } else {
    return 0;
  }
}


# gets the lines from a buffer of a window
sub get_lines
{
  my($refnum) = @_;
  my $window = Irssi::window_find_refnum($refnum);
  if ($window) {
    my $view = $window->view;
    my $line = $view->get_lines();
    my $ret = "";
    while (defined $line) {
      $ret .= $line->get_text(0) . "\n";
      $line = $line->next();
    }
    return $ret;
  }
  else {
    return 0;
  }
}


# return highest refnum
sub last_refnum
{
  return Irssi::windows_refnum_last();
}


# name of given refnum's window
sub name_of
{
  my($refnum) = @_;
  my $win = Irssi::window_find_refnum($refnum);
  return $win->get_active_name();
}


# tag of given refnum's window
sub tag_of
{
  my($refnum) = @_;
  my $win = Irssi::window_find_refnum($refnum);
  return ($win->{active}) ? $win->{active}->{server}->{tag} : "";
}


# level of given refnum's window
sub level_of
{
  my($refnum) = @_;
  my $win = Irssi::window_find_refnum($refnum);
  return $win->{data_level};
}


sub msg
{
  my($refnum, $text) = @_;
  my $win = Irssi::window_find_refnum($refnum);
  return unless $win;
  if ($text =~ /^\//) {
    # this is a command, don't prepend /msg *
    $win->command($text);
  } else {
    $win->command("msg * $text");
  }
  return 1;
}


sub command
{
  my($command) = @_;
  if (my $s = Irssi::active_server()) {
    $s->command($command);
  } else {
    Irssi::command($command);
  }
  return 1;
}


sub msg_active
{
  my($text) = @_;
  return msg(get_active_refnum(), $text);
}


sub get_log_fname
{
  my($servertag, $name) = @_;
  $name = lc($name);
  my $log_path = Irssi::settings_get_str("autolog_path");

  # fill in variables
  my $log_file = $strftime{$log_path};
  $log_file =~ s/^~/$ENV{HOME}/;
  $log_file =~ s/\$tag/$servertag/g;
  $log_file =~ s/\$0/$name/g;
  #print "log file: $log_file";

  return $log_file;  # hope this is filled in enough.
}


# return the last x lines of a given filename
sub tail_log
{
  my($filename, $lines) = @_;
  $lines ||= 5;
  #print "found $filename";
  return 0 if !-e $filename;
  my $t = qx(tail -n $lines '$filename');
  chomp $t;
  return $t;
}


my $timer = Irssi::timeout_add(250, \&check_sock, []);
