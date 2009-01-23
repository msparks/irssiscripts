# automode.pl
#
# Passively learn and actively maintain the ops/voices/halfops in channels.
# This is a no-maintenance auto-op/auto-voice script for irssi.
#
# INSTALL:
#   1) /script load automode.pl
#   2) Be a channel operator
#
# HOW IT WORKS:
#   When someone joins a channel and is given ops/voice/halfop, the script
#   will record that user's mask, as a combination of their nickname and part
#   of their hostname or IP address. When that person leaves and rejoins, the
#   script will check against its database and regrant the user the modes
#   he or she had before leaving.
#
#   If a user is kicked from a channel, all modes for that person are removed.
#   They must therefore be regiven by another operator manually. Note this.
#
#   Also, this script relies on the "chatnet" attribute being set for a
#   particular connection. Use /network (or /ircnet) to set up your networks
#   and such. This script will spit out (lots of) warnings if the chatnet is
#   not set.
#
# IGNORING CHANNELS:
#   If you do not wish to maintain modes on a channel, add it to the setting
#   "automode_ignore" in the form <tag>:<channel>, separated by spaces.
#
#   For example: /set automode_ignore FreeNode:#perl EFnet:#irssi
#                (should) not maintain modes in #perl on FreeNode or #irssi
#                on EFnet, provided FreeNode and EFnet are the tags for those
#                connections.
#
# NOTES:
#   The Perl module Data::Serializer is needed for this script.
#   The database file is not written instantaneously; it is on a timer and is
#   written to every five minutes or so. If the script is reloaded before it has
#   had a chance to save will result in forgotten modes.
#
use strict;
use Irssi;
use Data::Serializer;
use Data::Dumper;

use vars qw($VERSION %IRSSI);

$VERSION = '1.3';
%IRSSI = (
  authors     => 'Matt "f0rked" Sparks',
  contact     => 'ms+irssi@quadpoint.org',
  name        => 'automode',
  description => 'Mode maintainer',
  license     => 'BSD',
  url         => 'http://quadpoint.org',
  changed     => '2008-06-14',
);

# show debug lines
my $debug = 0;

my $s = new Data::Serializer;
my $file = Irssi::get_irssi_dir."/automode_list";

if (!-e $file) {
  print "[automode] creating $file";
  system("touch $file");
}

my $listref = $s->retrieve($file);
my %list = $listref ? %{$listref} : ();

#print Dumper %list;

my $save_tag;
my %buffer_tags;
my %buffer;


sub save_list
{
  $s->store(\%list,$file);
}


sub clear_list
{
  %list = ();
}


sub make_mask
{
  my($address) = @_;
  return if !$address;
  my($ident, $host) = split /@/, $address;
  my @split = split /\./, $host;

  if (@split <= 2) {
    # host is something like "foo.com". We cannot make the mask *.com.
  } else {
    if ($split[$#split] =~ /^\d+$/) {
      # Looks like an IP address.
      pop @split;
      $host = join(".", @split) . ".\d{1,3}";
    } else {
      # Mask the first segment.
      shift @split;
      $host = ".+?." . join(".", @split);
    }
  }

  return ".+?!.*${ident}@" . "${host}";
}


sub show
{
  my($net, $channel) = @_;
  print Dumper %{$list{$net}->{$channel}};
}


sub show_all
{
  my $list;
  print Dumper %list;
}


sub clear_channel
{
  my($net, $channel) = @_;
  delete $list{$net}->{$channel};
}


sub set_modes
{
  my($net, $channel) = @{$_[0]};
  return if !$buffer{$net}->{$channel};

  my($nicks, $modes) = values(%{$buffer{$net}->{$channel}});
  print "[automode] modes: $modes, nicks: $nicks" if $debug;
  my $c = Irssi::server_find_chatnet($net)->channel_find($channel);

  # iterate through the modes and see which ones we don't have to set
  my($final_modes, $final_nicks);

  my $i = 0;
  for (split //,$modes) {
    my $m = $_;
    my $n = (split / /, $nicks)[$i];
    $i++;

    next if (!$c->nick_find($n));
    next if ($m eq "o" && $c->nick_find($n)->{"op"});
    next if ($m eq "v" && $c->nick_find($n)->{"voice"});
    next if ($m eq "h" && $c->nick_find($n)->{"halfop"});

    # if we made it this far, add this to the final modes
    $final_modes .= $m;
    $final_nicks .= "$n ";
  }

  print "[automode] final modes: +$final_modes $final_nicks" if $debug;

  $c->command("MODE $channel +$final_modes $final_nicks")
    if ($final_modes && $final_nicks);
  delete $buffer{$net}->{$channel};
}


sub mode2letter
{
  my($mode) = @_;
  if ($mode eq "@") {
    return "o";
  } elsif ($mode eq "+") {
    return "v";
  } elsif ($mode eq "%") {
    return "h";
  }
  return -1;
}


sub remove_mode
{
  my($net, $channel, $mask, $mode) = @_;
  my $letter = mode2letter($mode);
  $list{$net}->{$channel}->{$mask} =~ s/$letter//
    if user_modes($net, $channel, $mask);
  delete $list{$net}->{$channel}->{$mask}
    if exists $list{$net}->{$channel}->{$mask}
    and !$list{$net}->{$channel}->{$mask};
}


sub remove_all
{
  my($net, $channel, $mask) = @_;
  delete $list{$net}->{$channel}->{$mask}
    if exists $list{$net}->{$channel}->{$mask};
}


sub user_modes
{
  my($net, $channel, $mask) = @_;
  return $list{$net}->{$channel}->{$mask};
}


sub add_mode
{
  my($net, $channel, $mask, $mode) = @_;
  return if !$mask or !$net or !$channel or !$mode;

  my $letter = mode2letter($mode);
  $list{$net}->{$channel}->{$mask} .= $letter
    if $list{$net}->{$channel}->{$mask} !~ /$letter/;

  Irssi::timeout_remove($save_tag);
  $save_tag = Irssi::timeout_add_once(300, "save_list", []);
}


sub event_mode
{
  my($channel, $nick, $setby, $mode, $type) = @_;
  return if check_ignore($channel->{server}, $channel->{name});
  my $w = Irssi::active_win;
  return if $mode != '@' and $mode != '%' and $mode != '+';

  my $chatnet = $channel->{server}->{chatnet};
  my $tag = $channel->{server}->{tag};
  print ("[automode] The 'chatnet' attribute is missing for the tag '$tag'. " .
         "Use /network (or /ircnet) to properly manage this.") if !$chatnet;
  return if !$chatnet;

  my $mask = make_mask($nick->{host});
  print "[automode] failed to make mask ($mask)" if (!$mask && $debug);
  return if !$mask;

  if ($type eq "+") {
    print ("[automode] adding mode '$mode' for $mask in $channel->{name} on " .
           $chatnet) if $debug;
    add_mode($chatnet, $channel->{name}, $mask, $mode);
  } else {
    # don't remove op if they deop themselves.
    return if $setby eq $nick->{nick};
    print ("[automode] removing mode '$mode' for $mask in $channel->{name} " .
           " on $chatnet") if $debug;
    remove_mode($chatnet, $channel->{name}, $mask, $mode);
  }

  #show($chatnet, $channel->{name});
}


sub event_join
{
  my($server, $channel, $nick, $address) = @_;
  return if check_ignore($server, $channel);
  my $mask = make_mask($address);
  return if !user_modes($server->{chatnet}, $channel, $mask);
  my $c = $server->channel_find($channel);
  return if not $c->{chanop};

  if (my $modes = user_modes($server->{chatnet}, $channel, $mask)) {
    print "[automode] Matched mask ($mask) with modes: $modes" if $debug;
    my $nick_list = "$nick " x length($modes);
    my %buf = ($buffer{$server->{chatnet}}->{$channel} ?
               %{$buffer{$server->{chatnet}}->{$channel}} : ());
    $buf{modes} .= $modes;
    $buf{nicks} .= $nick_list;
    $buffer{$server->{chatnet}}->{$channel} = \%buf;
    my $tag = $server->{chatnet} . "_$channel";
    Irssi::timeout_remove($buffer_tags{$tag});
    $buffer_tags{$tag} = Irssi::timeout_add_once(1000 + int(rand(250) * 3),
                                                 "set_modes",
                                                 [$server->{chatnet},
                                                 $channel]);
    #print Dumper %buffer;
  }
}


sub event_kick
{
  my($server, $channel, $nick, $kicker, $address, $reason) = @_;
  my $n = $server->channel_find($channel)->nick_find($nick);
  #print Dumper $n;
  my $mask = make_mask($n->{host});
  remove_all($server->{chatnet}, $channel, $mask) if $mask;
}


sub check_ignore
{
  my($server, $channel) = @_;
  my $chatnet = $server->{chatnet};
  my $ignore = Irssi::settings_get_str("automode_ignore") . " ";
  return ($ignore =~ /$chatnet:$channel /i) ? 1 : 0;
}


# I don't think this does what I want it to do.
sub event_exit
{
  save_list;
}


Irssi::signal_add("gui exit", "event_exit");

Irssi::signal_add("message kick", "event_kick");
Irssi::signal_add("message join", "event_join");
Irssi::signal_add("nick mode changed", "event_mode");

Irssi::settings_add_str("automode", "automode_ignore", "IM:&bitlbee");
