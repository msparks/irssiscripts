# ms's scripts and themes for irssi

These scripts are products of my work for my favorite IRC client, Irssi. If you
are new to Irssi, you also may want to read my
[guide to Irssi and GNU screen](http://quadpoint.org/articles/irssi).

Also, some scripts listed have comments and documentation listed at the top of
the files. Note this documentation.

## Bitlbee

### bitlbee_autoreply.pl

Sends an auto-reply message to AIM users when they send you messages while you
are away. Auto-replies are sent once an hour per nick. There is also an option
to notify the user of the length of your awayness. This is done by including
*(away: 5 minutes and 3 seconds)* at the end of the auto-reply.

### bitlbee_html.pl

Incoming HTML from AIM connections will be parsed into readable control
codes. Links are also parsed into readable text. An option exists replacing
outgoing control codes with appropriate HTML. Read the comments at the top of
the file to learn more.

### bitlbee_status_notice.pl

A buddy tracking system for Bitlbee and Irssi. When a contact goes offline, the
script displays how long they were online. When the contact returns, the script
displays how long they were offline.

### bitlbee_typing_notice.pl

Displays when the other party is typing.

## Miscellaneous

### anames.pl

Creates an `/anames` command that will read away information for users in a
particular channel and display a `/names`-like output with the away users
grayed out.

### automode.pl

No-maintenance, learning, auto-op/auto-voice/auto-halfop, nick mode maintainer.

### grumble.pl

Provides sane integration of Irssi with [Growl](http://growl.info/) and
[Mumbles](http://www.mumbles-project.org/), which both support the
[Growl network protocol](http://www.growlforwindows.com/gfw/help/gntp.aspx).
This script uses [Net::Growl](http://search.cpan.org/perldoc?Net%3A%3AGrowl) to
deliver notifications of hilights and private messages to multiple targets
simultaneously while maintaining privacy.

### hilightcmd.pl

Run a command (such as a shell script that executes a series of beeps) when you
are hilighted. It also has a setting to not run the command when you are away.

### hilight_notice.pl

Changes the msglevel of notices to that used by private messages. This means
that the status window will be hilighted like a query when a notice is
received.

### rtm.pl

Add new tasks to [Remember The Milk](http://rememberthemilk.com) through Irssi.

### socket-interface.pl

Control and get information from Irssi via a Unix socket. This script is not as
complete as it could (or should) be, but it allows for external programs to
send commands to Irssi easily.
