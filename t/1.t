
# set pragma
use strict;

# load the new module
use Getopt::ArgvFile qw(argvFile);

# display number of test
print "1..1\n";

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

print @ARGV==@expected && "@ARGV" eq "@expected" ? 'ok' : 'not ok', "\n";
