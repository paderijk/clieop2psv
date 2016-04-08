#!/usr/bin/perl
##
#   Scriptname.............: clieop2psv.pl
#   Version................: 0.0.2
#   License................: GPLv2
#   Author.................: P.A. de Rijk (pieter@de-rijk.com)
#   Purpose................: Convert ClieOp files into psv files
#   Scripting language.....: PERL
#

#####################################################################
# Read the options
# -r [filename] The ClieOp file to read (required)
# -s [filename]	Save as 'filename'      (required)
# -l [filename] Save log also to a file (optional)
# -h  show      Shows help information
#####################################################################
use Getopt::Std;
getopts ('r:s:l:h:', \%options);

my $Version = "0.0.2";

if ( $options{h} eq "show" )
{
	ShowHelpMessage();
	exit 1;
}

if (( $options{r} eq "" ) or ( $options{s} eq "" ) )
{
	print "ERROR: No input (-r [filename]) or output (-s [filename]) are defined!\n\n";
	ShowHelpMessage();
	exit 1;
}

if ( $options{r} eq $options{s} )
{
	print "ERROR: Input file \"$options{r}\" and output file \"$options{s}\" are the same!\n\n";
	ShowHelpMessage();
	exit 1;
}

# Output buffer
my @output;

# Data buffer for reading the arrays out of memory
my @data;

my $counter_x = 0;
my $counter_y = 0;
my $counter_batch = 0;
my $counter_mutaties = 0;

my $OutputFile = $options{s};

my $readfile   = $options{r};

# Regexpressions
my $Regexp_MutatieStart     = '^0100A';
my $Regexp_MutatieOmschr    = '^0160A';
my $Regexp_MutatieTGV       = '^0170B';
my $Regexp_MutatieTGVpl     = '^0173B';
my $Regexp_Verwerkingsdatum = '^0030B';
# Fields
my $verwerkingsdatum, $reknr_betaler, $reknr_begunstigde, $bedrag, $omschrijving, $begunstigde, $woonplaats;

# Define SrcDataBuffer and read the data into memory

open FILEOUT, "> $OutputFile";
print FILEOUT "";
close (FILEOUT);
		 
my $new_entry = 0;



	open (DATAREAD, "< $readfile") ;
  print "- Reading and converting $readfile\n";
	while(<DATAREAD>)
	{
		
		$counter_x = $counter_x + 1;
	  $counter_y = $counter_y + 1;
		
		if ($counter_x eq 10000) {
			print "- [$readfile] Lines: $counter_y  \tBatches: $counter_batch \tMutations: $counter_mutaties \n";
			$counter_x = 0;
		}
		
		$line = $_;
		
	  #New batch is found.				
		if ( $line =~ /($Regexp_Verwerkingsdatum)/i )
		{
			$verwerkingsdatum = substr $line,  6, 6;
			$counter_batch = $counter_batch + 1;
			print "- [$readfile] ==== NEW BATCH FOUND for $verwerkingsdatum =====================================\n";
		}
		
		if (( $new_entry = 1 ) and ( $line =~ /($Regexp_MutatieStart)/i ))
		{
			$output = "$verwerkingsdatum|$reknr_betaler|$reknr_begunstigde|$bedrag|$begunstigde|$woonplaats|$omschrijving";
			$output =~ tr/\n//d;
			
			if ( $bedrag != "" ) 
			{
				# When bedrag is not set don't output the data
 			  open FILEOUT, ">> $OutputFile";
 			  print FILEOUT "$output\n";
 			  close (FILEOUT);
 			  $bedrag = "";
 			  $reknr_betaler = "";
 			  $reknr_begunstigde = "";
 			  $omschrijving = "";
 			  $begunstigde = "";
 			  $woonplaats = "";
	 	  }
		}
		
		if ( $line =~ /($Regexp_MutatieStart)/i  )
		{
			 $line = substr $line, 0 , 41;
			 $line =~ s/\x20{2,}$//g;
			 $new_entry = 1;
			 $bedrag            = substr $line,  9, 12;
			 $reknr_betaler     = substr $line, 21, 10;
			 $reknr_begunstigde = substr $line, 31, 10;
			 
			 $centen            = substr $bedrag, 10, 2;
			 $euro              = substr $bedrag, 0, 10;
			 $bedrag            = "$euro.$centen";
			 
			 # Remove the leading zeros
			 $bedrag            =~ s/^0{1,}//g;
			 
			 $new_entry = $new_entry + 1;
			 $counter_mutaties = $counter_mutaties + 1;
	  }
	  
	  if ( $line =~ /($Regexp_MutatieOmschr)/i )
	  {
	     $line = substr $line, 0 , 37;
	     $line =~ s/\x20{2,}$//g;
	  	 $omschrijving = substr $line, 5;
	  	 $new_entry = $new_entry + 1;
	  }
	  if ( $line =~ /($Regexp_MutatieTGV)/i )
	  {
	  	 $line = substr $line, 0 , 35;
	  	 $line =~ s/\x20{1,}$//g;
	  	 $begunstigde = substr $line, 5;
	  	 $new_entry = $new_entry + 1;
	  }
	  
	  if ( $line =~ /($Regexp_MutatieTGVpl)/i )
	  {
	  	 $line = substr $line, 0 , 45;
	  	 $line =~ s/\x20{1,}$//g;
	  	 $woonplaats = substr $line, 5;
	  	 $new_entry = $new_entry + 1;
	  }
		
		# Get rid of useless spaces
		$line =~ s/\x20{2,}$//g;
		
	} # End of looping through the source file
	close (DATAREAD);


print "Loaded $counter_y lines with $counter_mutaties mutaties and $counter_batch batches\n";

sub ShowHelpMessage
{
	# Show some error stuff
	print "ClieOp03 to pipe-seperated-values version: $Version\n\n";
	print "Options:\n";
	print "\t-r [filename]\tDefine the ClieOp file to read (required)\n";
	print "\t-s [filename]\tDefine the output file (required)\n";
	print "\t-h show      \tShow this message\n";
	print "\nEXAMPLE:\n\tperl $0 -r c:\\somepath\\clieop.txt -s c:\\someotherpath\\clieop.psv\n";
	print "\n\t-or-\n";
	print "\n\t$0 -r \/somepath\/clieop.txt -s \/someotherpath\/clieop.psv\n";
  print "\n\nCopyright (C) 2006 Pieter de Rijk (pieter@de-rijk.com)\n";
  print "This script may only redistributed under the GNU General Public License version 2\n";
}
