# This perl module adds a :decrypt command that uses barnowl's zcrypt
# binary via Perl to decrypt zcrypt'd zephyrs after they have been
# received.
#
# To use this code, type
#   :perl do '/mit/snippets/barnowl/zcrypt.pl'
#

use IPC::Open2;
BarnOwl::new_command(decrypt => sub {
   my $msg = BarnOwl::getcurmsg();
   my $cmd = shift;
   my @args = @_;
   if (scalar @args == 0) {
       @args = ('-c', $msg->class, '-i', $msg->instance);
   }
   my ($zo, $zi);
   my $pid = open2($zo, $zi, 'athrun', 'barnowl', 'zcrypt', '-D', @args) or die "Couldn't launch zcrypt\n";
   my $decrypted;
   print $zi $msg->fields->[1] . "\n";
   close $zi;
   while (<$zo>) {
      chomp;
      last if $_ eq "**END**";
      $decrypted .= "$_\n";
   }
   BarnOwl::popless_ztext($decrypted);
   waitpid $pid, 0;
   },
   {summary => "Decrypt a zcrypted message once",
    usage => "decrypt [args]",
    description => "Invokes athrun barnowl zcrypt on the current message,\n
using the class and instance to find the crypt key, and pops up the\n
decrypted output. If args are specified, they are passed to zcrypt and the\n
class and instance are ignored.\n\n
SEE ALSO: zcrypt(1)"});

1;
