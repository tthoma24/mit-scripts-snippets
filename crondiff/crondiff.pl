#!/usr/bin/env perl
use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

=head1 NAME

crondiff.pl - Run command periodically and compare their output.

=head1 DESCRIPTION

crondiff.pl is designed to be run from cron periodically. It takes as
input a list of commands to run. Each time it is invoked, it runs the
commands listed, and sends mail to the user running the script if the
output of that command has changed since the last run.

=head1 USAGE

=over 4

=item

Create a file C<~/.crondiff/cmdlist>, containing one line per file, of
commands to be checked.

=item

Add C<crondiff.pl> to your crontab. The following example runs it
directly out of the locker (not necessarily a good idea!) every hour:

    # m h  dom mon dow   command
      0 *  *   *   * PATH=/bin:/usr/bin: perl /mit/snippets/crondiff/crondiff.pl

=back

=head1 ASSUMPTIONS

=over 4

=item

Mail goes to C<$USER@mit.edu>, for the user who runs this script.

=item

Mail will be sent using C<mutt -x>.

=back

If you don't like these assumptions, patches are welcome :)

=cut

my $confdir = $ENV{HOME} . "/.crondiff";
unless($ENV{USER}) {
    chomp(my $user = `id -un`);
    $ENV{USER} = $user;
};
my $mailto = $ENV{USER} . '@mit.edu';
my @mailer = qw(mutt -x);

my $cachedir = "$confdir/cache";

mkdir("$cachedir") unless -e "$cachedir";

open(my $clist, "<", "$confdir/cmdlist")
  or exit;

while(my $cmd = <$clist>) {
    chomp($cmd);
    my $hash = md5_hex($cmd);
    my $pid = fork;
    if($pid == 0) {
        # Child
        close(STDOUT);
        close(STDERR);
        open(STDOUT, ">>", "$cachedir/$hash.new");
        open(STDERR, ">>", "$cachedir/$hash.new");
        exec($cmd);
    }
    waitpid($pid, 0);
    if($? != 0) {
        # Exited with error, should send mail, but punting for now.
        unlink("$cachedir/$hash.new");
        next;
    } elsif(-f "$cachedir/$hash"
       && system("diff -q $cachedir/$hash.new $cachedir/$hash > /dev/null 2>&1") != 0) {
        # Output changed
        if(($pid = fork) == 0) {
            close(STDOUT);
            open(STDOUT, "|-", @mailer, $mailto, '-s', "Output of [$cmd]");
            system("date");
            print "----\n";
            system("diff", "-u", "-U", "0", "$cachedir/$hash", "$cachedir/$hash.new");
            exit;
        } else {
            waitpid($pid, 0);
        }
    }
    rename("$cachedir/$hash.new", "$cachedir/$hash");
}
