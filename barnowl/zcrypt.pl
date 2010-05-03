# BarnOwls older than late September 2008 will segfault on short zcrypt messages.
# Besides, the code is sketchy and doesn't belong in core. This perl module
# will add :zcrypt and :decrypt commands that use barnowl's zcrypt binary via
# Perl, so a bug in zcrypt can't possibly affect BarnOwl proper. The :zcrypt
# command replaces the built-in one.
#
# To use this code, type
#   :perl do '/mit/snippets/barnowl/zcrypt.pl'
#
# This first line will disable BarnOwl's own zcrypt code, so messages are
# encrypted onscreen. Use :decrypt to display them. (Security bugs were later
# found in the decryption code, although these probably affect locker zcrypt
# too.)

BarnOwl::command("unset zcrypt");

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
   print $zi @{$msg->fields}[1] . "\n";
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

BarnOwl::new_command(zcrypt => sub {
   my $cmd = shift;
   my @args = @_;
   my $argstring = join ' ', @args;
   BarnOwl::start_edit_win("athrun barnowl zcrypt $argstring", sub {
      my $msg = shift;
      my ($zo, $zi);
      my $pid = open2($zo, $zi, 'athrun', 'barnowl', 'zcrypt', @args);
      print $zi "$msg\n";
      close $zi;
      local $/;
      BarnOwl::message(<$zo>);
      waitpid $pid, 0;
      });
   },
   {summary => "Run athrun barnowl zcrypt",
    usage => "zcrypt -c [class] -i [instance]",
    description => "Calls athrun barnowl zcrypt on a message you type in.\n\n
SEE ALSO: zcrypt(1)"});
