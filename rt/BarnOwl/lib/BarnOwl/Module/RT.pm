use warnings;
use strict;

=head1 NAME

BarnOwl::Module::Rt

=head1 DESCRIPTION

Foo

=cut

package BarnOwl::Module::RT;
use IPC::Open3;
use Text::ParseWords;

our $VERSION = '1.0.1';

my %queuemap;
my %commands = (
    "((?:set|add|del)\\s.*)", "edit ticket/\$t \$1",
    "status\\s(deleted|resolved|rejected|open|new|waiting)", "edit ticket/\$t set status=\$1",
    "(d|del|delete)", "edit ticket/\$t set status=deleted",
    "(r|res|resolve)", "edit ticket/\$t set status=resolved",
    "(rej|reject|rejected)", "edit ticket/\$t set status=rejected",
    "show", "show -l ticket/\$t/history",
    "show (\\d+)", "show -l ticket/\$1/history",
    "list", 'rt list -o +Created "((Status=new or Status=stalled or Status=open) and (Queue=\'$q\'))"',
    "list (\\w+)", 'rt list -o +Created "((Status=new or Status=stalled or Status=open) and (Queue=\'\$1\'))"',
    "merge (\\d+)", "rt merge \$t \$1",
    "(take|untake|steal)", "rt \$1 \$t",
    "(?:owner|give)\\s(\\w+)",  "edit ticket/\$t set owner=\$1",
    );



my $cfg = BarnOwl::get_config_dir();
my $file_path = "$cfg/rtqueuemap";
if(-r "$file_path") {
    open(my $fh, "<:encoding(UTF-8)", "$file_path") or die("Unable to read $file_path:$!\n");
    while(defined(my $line = <$fh>)) {
        next if $line =~ /^\s+#/;
        next if $line =~ /^\s+$/;
        my ($class, $q) = quotewords('\s+', 0, $line);
        $queuemap{lc($class)} = $q;
    }
    close($fh);
}

my $file_path = "$cfg/rtcommands";
if(-r "$file_path") {
    open(my $fh, "<:encoding(UTF-8)", "$file_path") or die("Unable to read $file_path:$!\n");
    while(defined(my $line = <$fh>)) {
        next if $line =~ /^\s+#/;
        next if $line =~ /^\s+$/;
        my ($match, $command) = quotewords('\s+', 0, $line);
        $commands{$match} = $command;
    }
    close($fh);
}



sub cmd_rt{
    shift @_;
    my $args = join(' ', @_);
    my $m = owl::getcurmsg();
    my ($ticket) = $m->instance =~ m/^\D*(\d{7})\D*$/;
    my ($class) = $m->class =~ /^(?:un)*(.+?)(?:[.]d)*$/i;
    my $queue = $queuemap{$class};

    for my $key (keys %commands) 
    {
	my $value = $commands{$key};
	if($args =~ m/^\s*$key\s*$/){
	    my $match = $value;
	    my @numargs = @+;
	    #my $match = qr/\Q$key\E/
	    if($value =~ m/\$t/){
		if(!$ticket){
		    BarnOwl::error("Command 'rt " . $args . "' requires a message with ticket number selected");
		    return;
		}
		$match =~ s/\$t/$ticket/;
	    }
	    if($value =~ m/\$q/){
		if(!$queue){
		    BarnOwl::error("Command 'rt " . $args . "' requires a class in rtqueuemap selected");
		    return;
		}
		$match =~ s/\$q/$queue/;
	    }
	    for my $digit ($value =~ m/\$(\d)/g){
	        $args =~ m/^\s*$key\s*$/;
		my $replace = substr($args, $-[$digit], $+[$digit] - $-[$digit]);
		$match =~ s/\$$digit/$replace/;
	    }
	    return run_rt_command( quotewords('\s+', 0, $match) );
	}
    }

    BarnOwl::error("No Matching RT command found for: '" . $args . "'" );
    return;
}

sub run_rt_command{
    my @args = ("athrun","tooltime","rt");
    push (@args, @_);
    local(*IN, *OUT, *ERR);
    my $pid = open3(*IN, *OUT, *ERR, @args) || die("RT threw $!");
    close(*IN); 
    my $out = do { local $/; <OUT> };
    close(*OUT);
    $out .= do { local $/; <ERR> };
    close(*ERR);

    waitpid( $pid, 0 );

    if (($out =~ tr/\n//) eq 1){
	return $out;
    }
    BarnOwl::popless_text($out);
    return;
}

BarnOwl::new_command("rt",
    \&cmd_rt,
		     {
        summary => "rt commands in barnowl",
        usage => "rt <args>",
	description => <<END_DESCR

Examples:
	    rt [set|add|del] <args> - runs rt (set|add|del) with relevent args - Dangerous if not careful
	    rt [d|del|delete] - mark a ticket deleted
	    rt [r|res|resolve] - mark a ticked resolved
	    rt [rej|reject|rejected] - mark a ticked rejected
	    rt status [deleted|resolved|new|open|waiting|rejected] - set status of a ticket
	    rt show - show detailed history of selected ticket
	    rt show <ticket> - show history of <ticket>
	    rt list - list open tickets of current queue
	    rt list <queue> - lists open tickets of <queue>
	    rt merge <ticket> - merges current ticket with <ticket>
	    rt [take|untake|steal] - takes, untakes, or steals ticket
	    rt [owner|give] <user> - gives selected ticket to <user> 

config:
	    Go to help.mit.edu to set you rt password
	    
	    In ~\/.rtrc add the following lines:
	    user <username>
	    passwd <password>


rtqueuemap:
	    ~\/.owl\/rtqueuemap is a list of queues in the form of 
	    class queue
	    which is used for the queue in commands like the rt list function which select the current queue
	    help "Some Help Queue"
rtcommands:
	    ~\/.owl\/rtcommands is a file where you can put custom
	    commands to map the barnowl rt module with the rt command
	    line tool

	    It is a good place to put custom queries which will be used frequently.
	  Examples:
	    "list-owner (\w+)" "rt list -o +Created \"((Status=new or Status=stalled or Status=open) and (Queue='\$q') and 'Owner='\$1')\""
	
	    \$t is the current ticket
	    \$q is the current queue
	    \$[digit] matches control groups in the first reg-exp
END_DESCR
		     });


sub cmd_rt_reply {
    my $cmd  = shift;
    my $type = "comment";
    if ($cmd eq "rt-reply"){
	$type = "correspond";
    }

    my $m = owl::getcurmsg();
    my ($ticket) = $m->instance =~ m/^\D*(\d{7})\D*$/;
    if (!$ticket){
	BarnOwl::error("Command: '" . $cmd . "' requires a message with a ticket number selected");
	return;
    }

    if(@_) {
        return run_rt_command("rt", $type, "-m", join(" ", @_), $ticket);
    }
    return BarnOwl::start_edit_win($cmd . " ticket " . $ticket, sub {run_rt_command("rt", $type, "-m", @_, $ticket)});
  
}

BarnOwl::new_command("rt-reply",
    \&cmd_rt_reply,
                     {
        summary => "Reply to current ticket",
        usage => "rt-reply [message]",
        description => <<END_DESCR
Replies to the currently selected ticket.
END_DESCR
                     });

BarnOwl::new_command("rt-comment",
    \&cmd_rt_reply,
                     {
        summary => "Comment on the current ticket",
        usage => "rt-reply [message]",
        description => <<END_DESCR
Comments on the currently selected ticket.
END_DESCR
                     });


#owl::command('bindkey recv "M-r" command reply-un');


1;
