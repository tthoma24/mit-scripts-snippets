my $class = 'scripts-test';
my $instance_prefix = 'rt.';
my @zwrite = ('/usr/athena/bin/zwrite', '-d', '-O', 'auto', '-c', $class);

# RT-to-Zephyr notification scrip
# http://snippets.scripts.mit.edu/gitweb.cgi/.git/blob/HEAD:/rt/Scrips/zephyr.pl
#
# Copyright © 2010 Anders Kaseorg <andersk@mit.edu>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# Usage: configure $class and $instance_prefix above, and create a
# scrip as follows.
#
#   Description: Send Zephyr
#   Condition: User Defined
#   Action: User Defined
#   Template: Global template: Blank
#   Stage: TrasnactionCreate
#   Custom condition:
#     1;
#   Custom action preparation code:
#     1;
#   Custom action cleanup code:
#     [insert this code]

sub send_notice {
    my ($instance, $body, $extra) = @_;
    open my $out, '|-', @zwrite, '-i', $instance, defined $extra ? ('-s', $extra) : ();
    print $out $body;
    close $out;
};

local $SIG{__DIE__} = sub {
    my ($err) = @_;
    $err =~ s/@/@@/g;
    send_notice "${instance_prefix}error", "Internal error in Zephyr scrip:\n$err";
};

(my $id = $self->TransactionObj->Ticket) =~ s/@/@@/g;
(my $description = $self->TransactionObj->Description) =~ s/@/@@/g;
(my $subject = $self->TransactionObj->TicketObj->Subject) =~ s/@/@@/g;

send_notice "$instance_prefix$id", $description, $subject;
1;
