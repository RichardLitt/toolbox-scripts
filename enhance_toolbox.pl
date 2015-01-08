#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use File::Spec::Functions;
use File::Basename;
use Cwd;
use File::Copy;
use Data::Dumper;

# read config
my %config;
read_in_conf();

# get input file from config
my $input_file = $config{"input_file"};

my ($filename, $input_file_dir) = fileparse($input_file);

# die if input file doesn't exist
die ("file $input_file does not exist!") unless -e $input_file;

# define output file
my $output_file = $config{"input_file"} . "1.tmp";

# perform insert_prefix
copy ($input_file,$output_file) unless insert_prefix();
$input_file = $output_file;
$output_file = $config{"input_file"} . "2.tmp"; 

# perform insert_empty_markers 
copy ($input_file,$output_file) unless insert_empty_markers();
$input_file = $output_file;
$output_file = $config{"input_file"} . "3.tmp";

# perform change_label 
copy ($input_file,$output_file) unless change_label();
$input_file = $output_file;
$output_file = $config{"input_file"} . "4.tmp";

# perform create_media_marker 
copy ($input_file,$output_file) unless create_media_marker();
$input_file = $output_file;
$output_file = $config{"input_file"} . "5.tmp";

# perform handle_participants 
copy ($input_file,$output_file) unless handle_participants();


# rename old file to .orig
my $new_name_for_old_file = $config{"input_file"} . ".orig";
move($config{"input_file"},$new_name_for_old_file);

# rename final output to original filename
my $final_output_file = $config{"input_file"};
copy ($output_file,$final_output_file);

# delete temporary files
my @list = glob("$input_file_dir/*.tmp");

unlink @list or die "Couldn't delete temporary files: $!";


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

sub read_in_conf
{
	my $this_path = getcwd;
	open (my $conf_handle,"<",catfile($this_path,"enhance_toolbox.conf")) or die "Could not open enhance_toolbox.conf: $!";

    while (<$conf_handle>)
    {
    		chomp;		# get rid of newline
    		s/#.*//;		# get rid of comments
    		s/^\s+//;	# get rid of leading whitespaces
    		s/\s+$//;	# get rid of trailing whitespaces
    		next unless length;	# get next line if this is empty now
    		
    		if ($_ =~ / = /)
    		{
    			my ($key,$value) = split (/ = /,$_);
    			$config{$key} = $value;
    		}
    }
    
    # set default values; comment these out, if you do not want defaults
    print "No value supplied for media_marker, falling back on default value 'aud'\n" unless $config{"media_marker"};
    $config{"media_marker"} = "aud" unless $config{"media_marker"};     
    print "No value supplied for text_marker, falling back on default value 'tx'\n" unless $config{"text_marker"};
    $config{"text_marker"} = "tx" unless $config{"text_marker"};
    print "No value supplied for prefix_marker, falling back on default value 'ref'\n" unless $config{"prefix_marker"};
    $config{"prefix_marker"} = "ref" unless $config{"prefix_marker"};
    print "No value supplied for media_file, falling back on default value (same name as input file with extension .wav)\n" unless $config{"media_file"};
    my ($input_base_name,$del_me_directories,$del_me_suffix) = fileparse($config{"input_file"},(".txt"));
    $config{"media_file"} =  $input_base_name.".wav" unless $config{"media_file"};
}

sub change_label
{
	# open input and output
	open (my $input,"<",$input_file) or die "Could not open $input_file: $!";
	open (my $output,">",$output_file) or die "Could not open $output_file for writing: $!";

	# get variables from config
	my $old_label = $config{"old_label"};
	my $new_label = $config{"new_label"};
	
	# check if all necessary configuration values are set
	if (!$old_label or !$new_label)
	{
		warn "change_label could not be performed.\nPlease ensure that old_label and new_label are configured in enhance_toolbox.conf.\n";
		return 0;
	}
	
	# process file line by line
	while (my $line = <$input>)
	{
		$line =~ s/^\\$old_label(\s+.+)/\\$new_label$1/;
		print $output $line;
	}
	return 1;
}

sub insert_empty_markers
{
	# open input and output
	open (my $input,"<",$input_file) or die "Could not open $input_file: $!";
	open (my $output,">",$output_file) or die "Could not open $output_file for writing: $!";

	# get variables from config
	my $markers_to_insert = $config{"markers_to_insert"};
	my @insert = split(/,/,$markers_to_insert);
	@insert = pre_chomp (@insert);
	foreach (@insert)
	{
		s/'//g;
	}	
	
	my $after = $config{"after"};
	my $before = $config{"before"};
	
	# check if all necessary configuration values are set
	if ((@insert<1) or (!($after xor $before)))
	{
		warn "insert_empty_markers could not be performed.\nPlease ensure that markers_to_insert and either before or after are configured in enhance_toolbox.conf.\n";
		return 0;		
	} 
		
	my @array_of_items;
	my @item;
	
	# collect file contents into an array of arrays
	while (my $line = <$input>)
	{
		
		if ($line !~ /^\s$/)
		{
			push @item, $line;
		}
		else
		{	
			push @array_of_items, [ @item ];
			@item = ();
		}
	}
	push @array_of_items, [ @item ];
	
	# write contents with added changes back into output file
	foreach my $element (@array_of_items)
	{
		my @el_as_array = @$element;
		foreach my $inner_element (@el_as_array)
		{
			if ($before)
			{
				if ($inner_element =~ /^\\$before/)
				{
					foreach my $marker (@insert)
					{
						print $output '\\'."$marker\n";
					} 
				}
			}
			
			print $output $inner_element;
			
			if ($after)
			{
				if ($inner_element =~ /^\\$after/)
				{
					foreach my $marker (@insert)
					{
						print $output '\\'."$marker\n";
					} 
				}
			}
		}
		print $output "\n";
	}
	return 1;		
}

sub create_media_marker
{
	# open input and output
	open (my $input,"<",$input_file) or die "Could not open $input_file: $!";
	open (my $output,">",$output_file) or die "Could not open $output_file for writing: $!";

	# get variables from config
	my $media_file = $config{"media_file"};
	my $media_marker = $config{"media_marker"};

	# check if all necessary configuration values are set
	if (!$media_file or !$media_marker)
	{
		warn "create_media_markers could not be performed.\nPlease ensure that media_file and media_marker are configured in enhance_toolbox.conf.\n";
		return 0;
	}
	
	
	my @array_of_items;
	my @item;
	
	# collect file contents into an array of arrays
	while (my $line = <$input>)
	{
		if ($line !~ /^\s$/)
		{
			push @item, $line;
		}
		else
		{	
			push @array_of_items, [ @item ];
			@item = ();
		}
	}
	
	# write contents with added changes back into output file
	foreach my $element (@array_of_items)
	{
		my $elan_begin = '';
		my $elan_end = '';
		my @el_as_array = @$element;
		next if $#el_as_array < 0;
		foreach my $inner_element (@el_as_array)
		{
			if ($inner_element =~ /^\\ELANBegin\s+(\S+)|^\\EUDICOt0\s+(\S+)/)
			{
				$elan_begin = $1;
			}
			if ($inner_element =~ /^\\ELANEnd\s+(\S+)|^\\EUDICOt1\s+(\S+)/)
			{
				$elan_end = $1;
			}
			
			print $output $inner_element;
		
		}
		if ($elan_begin && $elan_end)
		{
			print $output '\\'. "$media_marker $media_file $elan_begin $elan_end\n";
		}
		print $output "\n";
		
	}
	return 1;
}

sub handle_participants
{
	# open input and output
	open (my $input,"<",$input_file) or die "Could not open $input_file: $!";
	open (my $output,">",$output_file) or die "Could not open $output_file for writing: $!";
	
	# get variables from config
	my $text_marker = $config{"text_marker"};
	my $participant_list = $config{"participants"};
	my @participants = split(/,/,$participant_list);
	@participants = pre_chomp (@participants);
	foreach (@participants)
	{
		s/'//g;
	}

	# check if all necessary configuration values are set
	if (@participants<1 or !$text_marker)
	{
		warn "handle_participants could not be performed.\nPlease ensure that participants and text_marker are configured in enhance_toolbox.conf.\n";
		return 0;
	}
	
	my @array_of_items;
	my @item;
	
	my $elan_participant;
	
	# collect file contents into an array of arrays
	while (my $line = <$input>)
	{
		if ($line !~ /^\s$/)
		{
			next if $line =~ /^\\ELANParticipant/;
			foreach my $name (@participants)
			{
				if ($line =~ /^\\$name(\s+\S+)/)
				{
					$elan_participant = $name;
					$line =~ s/^\\$name(\s+\S+)/\\$text_marker$1/;
				}
			}
			push @item, $line;
		}
		else
		{	
			next unless @item;
			push @item, '\ELANParticipant '."$elan_participant\n" if $elan_participant;
			push @array_of_items, [ @item ];
			@item = ();
			$elan_participant = '';
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
					
			print $output $inner_element;
			
		}
		print $output "\n";
		
	}
	return 1;
}

sub insert_prefix
{
	# open input and output
	open (my $input,"<",$input_file) or die "Could not open $input_file: $!";
	open (my $output,">",$output_file) or die "Could not open $output_file for writing: $!";

	# get variables from config
	my $prefix = $config{"prefix"};
	my $prefix_marker = $config{"prefix_marker"};
	
	# check if all necessary configuration values are set
	if (!$prefix_marker or !$prefix)
	{
		warn "insert_prefix could not be performed.\nPlease ensure that prefix_marker and prefix are configured in enhance_toolbox.conf.\n";
		return 0;
	}
	
	while (my $line = <$input>)
	{
		$line =~ s/^(\\$prefix_marker\s+)(.+)/$1$prefix$2/;
		print $output $line;
	}
	return 1;
}

