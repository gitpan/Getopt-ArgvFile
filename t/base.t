
# set pragma
use strict;

# load modules
use Cwd;
use Test::More qw(no_plan);

# load the module
use Getopt::ArgvFile qw(argvFile);

# action!
argvFile(default=>1);

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
is(@ARGV, @expected);
eq_array(\@ARGV, \@expected);

# clear @ARGV, try another startup path
undef(@ARGV);
{
 # adapt expectations (nestings does not work because
 # the default tests use the installation directory)
 my @current=@expected[0..$#expected-2];

 # run it where the files are
 my $dir=cwd();
 chdir('t');
 argvFile(current=>1);
 chdir($dir);

 # check results
 is(@ARGV, @current);
 eq_array(\@ARGV, \@current);
}

# declare an alternative array
my @options;

# action!
argvFile(default=>1, array=>\@options);

# perform next check
is(@options, @expected);
eq_array(\@options, \@expected);




