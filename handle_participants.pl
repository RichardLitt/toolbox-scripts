#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use File::Spec::Functions;
use Cwd q/realpath/;

my ($input_file, @participants, $marker);


GetOptions (
			'file=s' 	=> \$input_file,
			'participants=s' => \@participants,
			'marker=s'	=> \$marker
			);

@participants = split(/,/,join(',',@participants));

@participants = pre_chomp (@participants);

# print help text if an argument is missing
print_usage() unless $input_file;
print_usage() unless @participants > 0;

# set default marker 'tx'
$marker = 'tx' unless $marker;

# die if input file doesn't exist
die ("file $input_file does not exist!") unless -e $input_file;

# normalise path of input file
my $canon_input_file = realpath($input_file);
my $output_file = $canon_input_file . ".new";


open (my $input_handle,"<",$canon_input_file) or die "Could not open $canon_input_file: $!";
open (my $output_handle,">",$output_file) or die "Could not open $output_file for writing: $!";



my @array_of_items;
my @item;

my $elan_participant;

# collect file contents into an array of arrays
while (my $line = <$input_handle>)
{
	#ignore first couple of lines
	next if $line =~ /^\\_/;
	if ($line !~ /^\s$/)
	{
		next if $line =~ /^\\ELANParticipant/;
		foreach my $name (@participants)
		{
			if ($line =~ /^\\$name(\s+\S+)/)
			{
				$elan_participant = $name;
				$line =~ s/^\\$name(\s+\S+)/\\tx$1/;
			}
		}
		push @item, $line;
	}
	else
	{	
		next unless @item;
		push @item, '\ELANParticipant '."$elan_participant\n";
		push @array_of_items, [ @item ];
		@item = ();
	}
}

# write contents with added changes back into output file
foreach my $element (@array_of_items)
{
	my @el_as_array = @$element;
	IEBLOCK: foreach my $inner_element (@el_as_array)
	{
		foreach my $name (@participants)
		{
			next IEBLOCK if ($inner_element =~ /^\\$name/);
		}
				
		print $output_handle $inner_element;
		
	}
	print $output_handle "\n";
	
}


close ($input_handle);
close ($output_handle);



############################
# sub routines start here  #
############################
#

sub pre_chomp
{
	my @array = @_;
	foreach my $element (@array)
	{
	    $element =~ s/^\s+//; # remove leading whitespace    
    		$element =~ s/\s+$//; # remove trailing whitespace
	}
	return @array;
}

# print out program usage
sub print_usage
{
	print "
\n   Usage:  perl handle_participants.pl -file <input file> -marker <marker name> -participants <list of possible participant names>          
   
\n   Options:  
\n   -f, --file\t:\tpath to the file that should be used as input
\n   -m, --marker\t:\tname of the toolbox marker that should be inserted instead of the speaking participant, defaults to 'tx'
\n   -i, --insert\t:\tlist of possible participant names (enclosed in '', separate multiple values by comma)
\n\n ";

print "
\n   Example: perl handle_participants.pl --file /home/me/source.txt --marker tx --participants 'Jeremy, Alex, Han'
\n\n";

exit;
}
