# Automatically colors personals by hashing the username. Inspired by geofft's
# .bashrc. Needs a lot of tweaking to make perfect...
#
# To use:
#   :perl do '/mit/snippets/barnowl/personal-colors.pl'
#   :view -s colors

package BarnOwl::Style::Colors;
our @ISA=qw(BarnOwl::Style::Default);
use Digest::MD5;

sub description {"Colors for personals";}

sub format_chat {
    my $self = shift;
    my $m = shift;
    my $body = $self->indent_body($m);
    if ($m->is_personal) {
      my @colors = qw{red green blue yellow magenta cyan};
      my $hash = ord Digest::MD5::md5(($m->direction eq "out") ? $m->pretty_recipient : $m->pretty_sender);
      $body = '@[@color(' . $colors[$hash % scalar @colors] . ")$body]";
    }
    return $self->chat_header($m) . "\n". $body;
}

BarnOwl::create_style("colors", "BarnOwl::Style::Colors");

1;
