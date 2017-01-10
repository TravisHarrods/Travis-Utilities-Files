package Travis::Utilities::Files;

#==============================================================================
# Class TRAVIS::file is file manager. It provides a multiple file iterator and/
# or a list of input file(s).
#
# Authors: Hugo Devillers, Travis Harrods
# Created: 12-MAI-2015
# Updated: 10-JAN-2017
#==============================================================================

#==============================================================================
# REQUIEREMENTS
#==============================================================================
# OOp manager
use Moose;
# Log manager
use Travis::Utilities::Log;
# Base
use File::Glob;
use File::Basename;

#==============================================================================
# STATIC PRIVATE VARIABLES
#==============================================================================
# Iterator id
my $iter = -1;
# Path list
my @path = ();
# Log tool
my $log = Travis::Utilities::Log->new();

#==============================================================================
# ATTRIBUTS
#==============================================================================
our $VERSION = 0.01;
# Input path(s) in string
has 'input' => (
	is => 'rw',
	isa => 'Str',
	default => '',
	reader => 'get_input',
	writer => 'set_input'
);
# File format
has 'format' => (
	is => 'rw',
	isa => 'Str',
	default => '',
	reader => 'get_format',
	writer => 'set_format'
);
# Directory depth exploration
has 'depth' => (
	is => 'rw',
	isa => 'Int',
	default => 1,
	reader => 'get_depth',
	writer => 'set_depth'
);
# Must be non empty
has 'non_empty' => (
	is => 'ro',
	isa => 'Bool',
	default => 1,
	reader => 'get_non_empty'
);

#==============================================================================
# BUILDER
#==============================================================================
sub BUILD
{
  my $self = shift;

  # format can be a list of formats
  if($self->get_format =~ /[\,\;\s]/)
  {
  	my @tmp = split(/[\,\;\s]/, $self->get_format);
  	my $regex = '('.join('|', @tmp).')';
  	$self->set_format($regex);
  }

  # if input is not null
  if($self->get_input ne '')
  {
  	$self->add_from_input($self->get_input);
  	$self->check_empty();
  }
}

#==============================================================================
# METHODS
#==============================================================================
sub add_from_input
{
	my $self = shift;
	my $input = shift;
	my $depth = shift;

	if(!defined($depth))
	{
		$depth = $self->get_depth;
	}

	my $format = $self->get_format;

	# Input is a single file name
	if(-f $input)
	{
		if($format ne '')
		{
			if($input =~ m/\.$format$/i)
			{
				push @path, $input;
			}
		}
		else
		{
			push @path, $input;
		}
	}
	# Input is a directory name
	elsif(-d $input)
	{
		if($depth > 0)
		{
			my @tmp = ();
			$self->add_from_glob($input, 1, \@tmp);
			foreach (@tmp)
			{
				$self->add_from_input($_, $depth-1);
			}
		}

	}
	# Input is a multiple entry (coma, semi-colone or space separator)
	elsif($input =~ /[\,\;\s]/)
	{
		my @tmp = split(/[\,\;\s]/, $input);
		foreach (@tmp)
		{
			$self->add_from_input($_, $depth);
		}
	}
	# Input is incomplete (eg.: path/*)
	elsif($input =~ /\*/)
	{
		my @tmp = ();
		$self->add_from_glob($input, 0, \@tmp);
		foreach (@tmp)
		{
			$self->add_from_input($_, $depth-1);
		}

	}
	# No solution
	else
	{
		$log->error("Cannot find file or directory named $input.");
	}
}

sub add_from_glob
{
	my $self = shift;
	my $patt = shift;
	my $isDir = shift;
	my $refPath = shift;

	my @tmp;
	if($isDir!=0)
	{
		@tmp = File::Glob::bsd_glob($patt.'/*');
	}
	else
	{
		@tmp = File::Glob::bsd_glob($patt);
	}
	if(scalar(@tmp)!=0)
	{
		if($self->get_format ne '')
		{
			foreach (@tmp)
			{
				my $format = $self->get_format;
				if($_=~ /\.$format$/i)
				{
					push @{$refPath}, $_;
				}
			}
		}
		else
		{
			foreach (@tmp)
			{
				push @{$refPath}, $_;
			}
		}
	}
	else
	{
		$log->error("No file found with the pattern $patt.");
	}
}

sub check_empty
{
	my $self = shift;
	if(scalar(@path)==0)
	{
		if($self->get_non_empty == 1)
		{
			$log->fatal('No file found in '.$self->get_input.'.');
		}
		else
		{
			$log->warning('No file found in '.$self->get_input.'.');
		}
	}
}

sub count_files
{
   my $self = shift;
   return(scalar(@path));
}

sub print
{
	my $self = shift;
	my $sep = shift;

	if(!defined($sep))
	{
		$sep = "\n";
	}
	foreach (@path)
	{
		print $_.$sep;
	}
}

sub get_paths
{
	my $self = shift;
	my $array = shift;

	if(defined($array))
	{
		foreach (@path)
		{
			push @{$array}, $_;
		}
	}
	else
	{
		return(@path);
	}
}

sub get_path
{
	my $self = shift;
	if($iter == -1)
	{
		$log->fatal("You must call method ->next at least one time before using".
		" this method.");
	}
	else
	{
		return($path[$iter]);
	}
}

sub get_dir
{
   my $self = shift;
	if($iter == -1)
	{
		$log->fatal("You must call method ->next at least one time before using".
		" this method.");
	}
	else
	{
	   my $dir = $path[$iter];
	   my $toRM = basename($dir);
	   $dir =~ s/$toRM$//;
	   if($dir eq '')
	   {
	      $dir = './';
	   }
	   return($dir);
	}
}

sub get_basename
{
	my $self = shift;
	if($iter == -1)
	{
		$log->fatal("You must call method ->next at least one time before using".
		" this method.");
	}
	else
	{
		return(basename($path[$iter]));
	}
}

sub get_extention
{
  my $self = shift;
  if($iter == -1)
	{
		$log->fatal("You must call method ->next at least one time before using".
		" this method.");
	}
	else
	{
    my $bn = $self->get_basename;
    if($bn =~ /\.(\w+)$/)
    {
      return($1);
    }
    else
    {
      $log->warning("No extention found for file $bn.");
      return('NULL');
    }
  }
}

sub next
{
	my $self = shift;
	if($iter < scalar(@path)-1)
	{
		$iter++;
		return(1);
	}
	else
	{
		return(0);
	}
}

sub random_path
{
   my $self = shift;
   my $length = shift;
   if(!defined($length))
   {
      $length = 10;
   }
   my $let = 'ABCDEFGhIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_';
   my @possible = split('', $let);
   my $nLetters = scalar(@possible);

   my $value = '';
   my $id = 0;

   while($id < $length)
   {
      $value .= $possible[int(rand($nLetters))];
      $id++
   }

   return($value);
}

sub random_dir
{
   my $self = shift;
   my $prefix = shift;
   my $suffix = shift;
   my $create = shift;
   if(!defined($prefix))
   {
      $prefix = '';
   }
   if(!defined($suffix))
   {
      $suffix = '';
   }
   if(!defined($create))
   {
      $create =0;
   }

   my $new_dir = $prefix.$self->random_path(10).$suffix;

   while(-d $new_dir)
   {
      # The directory already exists
      $new_dir = $prefix.$self->random_path(10).$suffix;
   }

   if($create != 0)
   {
      eval
      {
         mkdir $new_dir;
      };
      if($@)
      {
         $log->fatal('Cannot create the random directory : '.$@);
      }
   }

   return($new_dir);
}

return(1);
