
# set pragma
use strict;

# load test module
use Test;

# load the module
use Getopt::ArgvFile qw(argvFile);

# declare number of tests
BEGIN {plan tests=>2;}

# action!
argvFile(home=>1, default=>1);

# declare expected result
my @expected=(
			  '-A',
			  'A',
			  '-b',
			  'bb',
			  '-ccc',
			  'ccc ccc ccc',
			  '-ddd',
			  '\'d1 d2" d3\' d4 d5 d6',
			  '-eee',
			  '"e1 e2\\\' e3" e4 e5 e6',
			  'par1',
			  'par2',
			  'par3',
			  '@casca',
			  '-case',
			  'lower',
			 );

# perform first check
ok(@ARGV==@expected && "@ARGV" eq "@expected");

# declare an alternative array
my @options;

# action!
argvFile(home=>1, default=>1, array=>\@options);

# perform second check
ok(@options==@expected && "@options" eq "@expected");

