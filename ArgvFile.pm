
# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date   | author   | changes
# ---------------------------------------------------------------------------------------
# 1.06    |03.05.02| JSTENZEL | the startup filename scheme is now configurable by the
#         |        |          | new option "startupFilename";
# 1.05    |30.04.02| JSTENZEL | cosmetics: hash access without quotes;
#         |        | JSTENZEL | corrected and improved inline doc;
#         |        | JSTENZEL | using File::Spec::Functions to build filenames,
#         |        |          | for improved portability;
#         |        | JSTENZEL | using Cwd::abs_path() to check if files were read already;
#         |        | JSTENZEL | added support for default files in *current* directory;
# 1.04    |29.10.00| JSTENZEL | bugfix: options were read twice if both default and home
#         |        |          | startup options were read and the script was installed in
#         |        |          | the users homedirectory;
# 1.03    |25.03.00| JSTENZEL | new parameter "prefix";
#         |        | JSTENZEL | POD in option files is now supported;
#         |        | JSTENZEL | using Test in test suite now;
# 1.02    |27.02.00| JSTENZEL | new parameter "array";
#         |        | JSTENZEL | slight POD adaptions;
# 1.01    |23.03.99| JSTENZEL | README update only;
# 1.00    |16.03.99| JSTENZEL | first CPAN version.
# ---------------------------------------------------------------------------------------

# = POD SECTION =========================================================================

=head1 NAME

Getopt::ArgvFile - interpolates script options from files into @ARGV or another array

=head1 VERSION

This manual describes version B<1.06>.

=head1 SYNOPSIS

  # load the module
  use Getopt::ArgvFile qw(argvFile);

  # load another module to evaluate the options, e.g.:
  use Getopt::Long;
  ...

  # solve option files
  argvFile;

  # evaluate options, e.g. this common way:
  GetOptions(%options, 'any');

If options should be processed into another array, this can be done this way:

  # prepare target array
  my @options=('@options1', '@options2', '@options3');

  ...

  # replace file hints by the options stored in the files
  argvFile(array=>\@options);

=head1 DESCRIPTION

This module simply interpolates option file hints in @ARGV
by the contents of the pointed files. This enables option
reading from I<files> instead of or additional to the usual
reading from the command line.

Alternatively, you can process any array instead of @ARGV
which is used by default and mentioned mostly in this manual.

The interpolated @ARGV could be subsequently processed by
the usual option handling, e.g. by a Getopt::xxx module.
Getopt::ArgvFile does I<not> perform any option handling itself,
it only prepares the array @ARGV.

Option files can significantly simplify the call of a script.
Imagine the following:

=over 4

=item Breaking command line limits

A script may offer a lot of options, with possibly a few of them
even taking parameters. If these options and their parameters
are passed onto the program call directly, the number of characters
accepted by your shells command line may be exceeded.

Perl itself does I<not> limit the number of characters passed to a
script by parameters, but the shell or command interpreter often
I<sets> a limit here. The same problem may occur if you want to
store a long call in a system file like crontab.

If such a limit restricts you, options and parameters may be moved into
option files, which will result in a shorter command line call.

=item Script calls prepared by scripts

Sometimes a script calls another script. The options passed onto the
nested script could depend on variable situations, such as a users
input or the detected environment. In such a case, it I<can> be easier
to generate an intermediate option file which is then passed to
the nested script.

Or imagine two cron jobs one preparing the other: the first may generate
an option file which is then used by the second.

=item Simple access to typical calling scenarios

If several options need to be set, but in certain circumstances
are always the same, it could become sligthly nerveracking to type
them in again and again. With an option file, they can be stored
I<once> and recalled easily as often as necessary.

Further more, option files may be used to group options. Several
settings may set up one certain behaviour of the program, while others
influence another. Or a certain set of options may be useful in one
typical situation, while another one should be used elsewhere. Or there
is a common set of options which has to be used in every call,
while other options are added depending on the current needs. Or there
are a few user groups with different but typical ways to call your script.
In all these cases, option files may collect options belonging together,
and may be combined by the script users to set up a certain call.
In conjunction with the possiblity to I<nest> such collections, this is
perhaps the most powerful feature provided by this method.

=item Individual and installationwide default options

The module allows the programmer to enable user setups of default options;
for both individual users or generally I<all> callers of a script.
This is especially useful for administrators who can configure the
I<default> behaviour of a script by setting up its installationwide
startup option file. All script users are free then to completely
forget every already configured setup option. And if one of them regularly
adds certain options to every call, he could store them in his I<individual>
startup option file.

For example, I use this feature to make my scripts both flexible I<and>
usable. I have several scripts accessing a database via DBI. The database
account parameters as well as the DBI startup settings should not be coded
inside the scripts because this is not very flexible, so I implemented
them by options. But on the other hand, there should be no need for a normal
user to pass all these settings to every script call. My solution for this
is to use I<default> option files set up and maintained by an administrator.
This is very transparent, most of the users know nothing of these
(documented ;-) configuration settings ... and if anything changes, only the
option files have to be adapted.

=back

=cut

# PACKAGE SECTION  ###############################################

# force Perl version
require 5.003;

# declare namespace
package Getopt::ArgvFile;

# declare your revision (and use it to avoid a warning)
$VERSION="1.06";
$VERSION=$VERSION;

=pod

=head1 EXPORTS

No symbol is exported by default, but you may explicitly import
the "argvFile()" function.

Example:

  use Getopt::ArgvFile qw(argvFile);

=cut

# export something
require Exporter;
@ISA=qw(Exporter);
@EXPORT_OK=qw(argvFile);

# CODE SECTION  ##################################################

# set pragmas
use strict;

# load libraries
use Carp;
use File::Basename;
use Text::ParseWords;
use File::Spec::Functions;
use Cwd qw(:DEFAULT abs_path chdir);

# METHOD SECTION  ################################################

=pod

=head1 FUNCTIONS

=head2 argvFile()

Scans the command line parameters (stored in @ARGV or an alternatively
passed array) for option file hints (see I<Basics> below), reads the
pointed files and makes their contents part of the source array
(@ARGV by default) replacing the hints.

Because the function was intentionally designed to work on @ARGV
and this is still the default behaviour, this manual mostly speaks about
@ARGV. Please note that it is possible to process I<any> other array
as well.

B<Basics>

An option file hint is simply the filename preceeded by (at least) one
"@" character:

  > script -optA argA -optB @optionFile -optC argC

This will cause argvFile() to scan "optionFile" for options.
The element "@optionFile" will be removed from the @ARGV array and
will be replaced by the options found.

Note: you can choose another prefix by using the "prefix" parameter,
see below.

An option file which cannot be found is quietly skipped.

Well, what is I<within> an option file? It is intended to
store I<command line arguments> which should be passed to the called
script. They can be stored exactly as they would be written in
the command line, but may be spread to multiple lines. To make the
file more readable, space and comment lines (starting with a "#")
are allowed additionally. POD comments are supported as well.
For example, the call

  > script -optA argA -optB -optC cArg par1 par2

could be transformed into

  > script @scriptOptions par1 par2

where the file "scriptOptions" may look like this:

  # option a
  -optA argA

C<>

  =pod
  option b
  =cut
  -optB

C<>

  # option c
  -optC cArg

B<Nested option files>

Option files can be nested. Recursion is avoided globally, that means
that every file will be opened only I<once> (the first time argvFile() finds
a hint pointing to it). This is the simplest implementation, indeed, but
should be suitable. (Unfortunately, there are I<LIMITS>.)

By using this feature, you may combine groups of typical options into
a top level option file, e.g.:

  File ab:

C<>

  # option a
  -optA argA
  # option b
  -optB

C<>

  File c:

C<>

  # option c
  -optC cArg

C<>

  File abc:

C<>

  # combine ab and c
  @ab @c

If anyone provides these files, a user can use a very short call:

  > script @abc

and argvFile() will recursively move all the filed program parameters
into @ARGV.

B<Startup support>

By setting several named parameters, you can enable automatic processing
of I<startup option files>. There are three of them:

The I<default option file> is searched in the installation path
of the calling script, the I<home option file> is searched in the
users home (evaluated via environment variable "HOME"), and the
I<current option script> is searched in the current directory.

By default, all startup option files are expected to be named like
the script, preceeded by a dot, but this can be adapted to individual
needs if preferred, see below.

 Examples:
  If a script located in "/path/script" is invoked in directory
  /the/current/dir by a user "user" whoms "HOME" variable points
  to "/homes/user", the following happens:

C<>

  argvFile()                    # ignores all startup option files;
  argvFile(default=>1)          # searches and expands "/path/.script",
                                # if available (the "default" settings);
  argvFile(home=>1)             # searches and expands "/homes/user/.script",
                                # if available (the "home" settings);
  argvFile(current=>1)          # searches and expands "/the/current/dir/.script",
                                # if available (the "current" settings);
  argvFile(
           default => 1,
           home    => 1,
           current => 1
          )                     # tries to handle all startups.

Any true value will activate the setting it is assigned to.

In case the ".script" name rule does not meet your needs or does not fit
into a certain policy, the expected startup filenames can be set up by
an option C<startupFilename>. The option value may be a scalar used as
the expected filename, or a reference to code returning the name. Such
code will be called I<once> and will receive the name of the script.

  # use ".config"
  argvFile(startupFilename => '.config');

  # emulate the default behaviour,
  # but use an extra dot postfix
  my $nameBuilder=sub {join('', '.', basename($_[0]), '.');}
  argvFile(startupFilename => $nameBuilder);

The contents found in a startup file is placed I<before> all explicitly
set command line arguments. This enables to overwrite a default setting
by an explicit option. If all startup files are read, I<current> startup
files can overwrite I<home> files which have preceedence over I<default>
ones, so that the I<default> startups are most common. In other words,
if the module would not support startup files, you could get the same
result with "script @/path/.script @/homes/user/.script @/the/current/dir/.script".

Note: There is one certain case when overwriting will I<not> work completely
because duplicates are sorted out: if all three types of startup files are
used and the script is started in the installation directory,
the default file will be identical to the current file. The default file is
processed, but the current file is skipped as a duplicate later on and will
I<not> overwrite settings made caused by the intermediately processed home file.
If started in another directory, it I<will> overwrite the home settings.
But the alternative seems to be even more confusing: the script would behave
differently if just started in its installation path. Because a user might
be more aware of configuration editing then of the current path, I choose
the current implementation, but this preceedence might become configurable
in a future version.

If there is no I<HOME> environment variable, the I<home> setting takes no effect
to avoid trouble accessing the root directory.

B<Cascades>

The function supports multi-level (or so called I<cascaded>) option files.
If a filename in an option file hint starts with a "@" again, this complete
name is the resolution written back to @ARGV - assuming there will be
another utility reading option files.

 Examples:
  @rfile          rfile will be opened, its contents is
                  made part of @ARGV.
  @@rfile         cascade: "@rfile" is written back to
                  @ARGV assuming that there is a subsequent
                  tool called by the script to which this
                  hint will be passed to solve it by an own
                  call of argvFile().

The number of cascaded hints is unlimited.

B<Processing an alternative array>

However the function was designed to process @ARGV, it is possible to
process another array as well if you prefer. To do this, simply pass
a I<reference> to this array by parameter B<array>.

 Examples:
  argvFile()                    # processes @ARGV;
  argvFile(array=>\@options);   # processes @options;

B<Choosing an alternative hint prefix>

By default, "@" is the prefix used to mark an option file. This can
be changed by using the optional parameter B<prefix>:

 Examples:
  argvFile();                   # use "@";
  argvFile(prefix=>'~');        # use "~";

Note that the strings "#", "=", "-" and "+" are reserved and I<cannot>
be chosen here because they are used to start plain or POD comments or
are typically option prefixes.

=cut
sub argvFile
 {
  # declare function variables
  my ($maskString, $i, %rfiles, %startup, %seen)=("\0x07\0x06\0x07");

  # detect the host system (to prepare filename handling)
  my $casesensitiveFilenames=$^O!~/^(?:dos|os2|MSWin32)/i;

  # check and get parameters
  confess("[BUG] Getopt::ArgvFile::argvFile() uses named parameters, please provide name value pairs.") if @_ % 2;
  my %switches=@_;

  # perform more parameter checks
  confess('[BUG] The "array" parameter value is no array reference.') if exists $switches{array} and not (ref($switches{array}) and ref($switches{array}) eq 'ARRAY');
  confess('[BUG] The "prefix" parameter value is no defined literal.') if exists $switches{prefix} and (not defined $switches{prefix} or ref($switches{prefix}));
  confess('[BUG] Invalid "prefix" parameter $switches{"prefix"}.') if exists $switches{prefix} and $switches{prefix}=~/^[-#=+]$/;
  confess('[BUG] The "startupFilename" parameter value is neither a scalar nor a code reference.') if exists $switches{startupFilename} and ref($switches{startupFilename}) and ref($switches{startupFilename}) ne 'CODE';

  # set array reference
  my $arrayRef=exists $switches{array} ? $switches{array} : \@ARGV;

  # set prefix
  my $prefix=exists $switches{prefix} ? $switches{prefix} : '@';

  # set up startup filename
  my $startupFilename=exists $switches{startupFilename}
                       ? ref($switches{startupFilename})
                           ? $switches{startupFilename}->($0)
                           : $switches{startupFilename}
                       : join('', '.', basename($0));

  # init startup file pathes
  (
   $startup{default}{path},
   $startup{home}{path},
   $startup{current}{path},
  )=(
     dirname($0),
     exists $ENV{HOME} ? $ENV{HOME} : \007,
     cwd(),
    );

  # If startup pathes are *identical* (script installed in home directory) and
  # both startup flags are set, we can delete one of them (to read the options only once).
  # (Note that we could easily combine this with the subsequent loop, but an extra loop
  # will make it easy to allow extra configuration for "first seen first processed" /
  # "fix processing order" preferences (what if the current directory is the default
  # one, but should overwrite the home settings?).)
  foreach my $type (qw(default home current))
    {
     # skip unused settings
     next unless exists $switches{$type};

     # build filename
     my $cfg=catfile(abs_path($startup{$type}{path}), $startupFilename);

     # remove this setting if the associated file
     # was already seen before (each file should be read once)
     # - or if there is no such file this call
     delete $switches{$type}, next if exists $seen{$cfg} or not -e $cfg;

     # otherwise, note that we saw this file
     $seen{$cfg}=1;
    }

  # check all possible startup files for usage - be careful to handle
  # them in the following order (implemented by alphabetical order here!):
  # FIRST, the DEFAULT startup should be read, THEN the HOME one and finally
  # the CURRENT one - this way, all startup options are placed before command
  # line ones, and the CURRENT settings can overwrite the HOME settings which
  # can overwrite the DEFAULT ones - which are the most common.
  # Note that to achieve this reading order, we have to build the array
  # of filenames in reverse order (because we use unshift() for construction).
  foreach (qw(current home default))
    {
     # anything to do?
     if (exists $switches{$_} and $startup{$_}{path} ne \007)
       {
        # build absolute startup filename
        my $cfg=catfile(abs_path($startup{$_}{path}), $startupFilename);

        # let's proceed this file first - this way,
        # command line options can overwrite configuration settings
        # (we already checked file existence above)
        unshift @$arrayRef, join('', $prefix, $cfg);
       }
    }

  # nesting ...
  while (grep(/^$prefix/, @$arrayRef))
    {
     # declare scope variables
     my (%nr, @c, $c);

     # scan the array for option file hints
     for ($i=0; $i<@$arrayRef; $i++)
       {$nr{$i}=1 if substr($arrayRef->[$i], 0, 1) eq $prefix;}

     for ($i=0; $i<@$arrayRef; $i++)
       {
        if ($nr{$i})
          {
           # an option file - handle it

           # remove the option hint
           $arrayRef->[$i]=~s/$prefix//;

           # if there is still an option file hint in the name of the file,
           # this is a cascaded hint - insert it with a special temporary
           # hint (has to be different from $prefix to avoid a subsequent solution
           # by this loop)
           push(@c, $arrayRef->[$i]), next if $arrayRef->[$i]=~s/^$prefix/$maskString/;

           # skip nonexistent or recursively nested files
           next if !-e $arrayRef->[$i] || -d _ || $rfiles{$casesensitiveFilenames ? $arrayRef->[$i] : lc($arrayRef->[$i])};

           # store filename to avoid recursion
           $rfiles{$casesensitiveFilenames ? $arrayRef->[$i] : lc($arrayRef->[$i])}=1;

           # open file and read its contents
           open(OPT, $arrayRef->[$i]);
           {
            # scopy
            my ($pod);

            while (<OPT>)
              {
               # check for POD directives
               $pod=1 if /^=\w/;
               $pod=0, next if /^=cut/;
               # skip space and comment lines (including POD)
               next if /^\s*$/ || /^\s*#/ || $pod;
               # remove newlines, leading and trailing spaces
               s/\s*\n?$//; s/^\s*//;
               # store options and parameters
               push(@c, shellwords($_));
              }
           }
          }
        else
          {
           # a normal option or parameter - handle it
           push(@c, $arrayRef->[$i]);
          }
       }

     # replace array by expanded array
     @$arrayRef=@c;
    }

  # reset hint character in cascaded hints to $prefix
  @$arrayRef=map {s/^$maskString/$prefix/; $_} @$arrayRef;
 }

# flag this module was read successfully
1;

# POD TRAILER ####################################################

=pod

=head1 NOTES

If a script calling C<argvFile()> with the C<default> switch is
invoked using a relative path, it is strongly recommended to
perform the call of C<argvFile()> in the startup directory
because C<argvFile()> then uses the I<relative> script path as
well.


=head1 LIMITS

If an option file does not exist, argvFile() simply ignores it.
No message will be displayed, no special return code will be set.

=head1 AUTHOR

Jochen Stenzel E<lt>mailto://perl@jochen-stenzel.deE<gt>

=head1 LICENSE

Copyright (c) 1993-2002 Jochen Stenzel. All rights reserved.

This program is free software, you can redistribute it and/or modify it
under the terms of the Artistic License distributed with Perl version
5.003 or (at your option) any later version. Please refer to the
Artistic License that came with your Perl distribution for more
details.

=cut
