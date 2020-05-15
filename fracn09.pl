eval '(exit $?0)' &&
  eval 'exec perl -S $0 ${1+"$@"}' &&
  eval 'exec perl -S $0 $argv:q'
  if 0;

# fracn09.pl - Perl script for designing fractional-N frequency dividers.
# Both phase-accumulator and dual-modulus-prescaler designs are performed.
# Also writes VHDL and Verilog files to implement the divider.
# Copyright (c) Allan Herriman 1999, 2000, 2001, 2002

################################################################################
# Legal notices and Copying information - please see attached readme.txt file.

################################################################################
# Bugs:
#
#  0. It's much easier to read the VHDL comments in the generated VHDL than here!
#
#  1. Currently this doesn't work if the output frequency is more than half
#  the input frequency.  (The "50%" duty cycle output makes this impossible.)
#  If we remove the 50% duty cycle output, then we can have dividers with
#  output frequencies all the way up to the input frequency.
#  Requesting output frequencies > one half the input frequency currently
#  causes the program to terminate with an error message.
#  *** Fixed in version 0.04.  Fout/Fin Ratios > 1/2 result in the 50% duty
#  cycle output being disabled, and a warning message is generated.
#  *** Changed in version 0.07.  Fout/Fin Ratios >= 1/2 now result in the 50%
#  duty cycle output being disabled.
#
#  2. The phase accumulator doesn't allow the constant to be 2 ** 31 or more,
#  because the generated VHDL code uses an integer to hold this number
#  and most VHDL tools only support the minimum required range for integers.
#  This limits the accuracy for this type of divider.
#  A warning message is issued in this case, and the achieved accuracy is
#  listed in the output VHDL file.
#  *** Fixed in version 0.06.  Constants >= 2**31 now are represented by a
#  unsigned constant (e.g. "0101010") rather than an integer.
#
#  3. The "50%" duty cycle output has only a roughly 50% duty cycle, and the
#  duty cycle may vary from cycle to cycle.
#  This will be particularly bad for higher Fout/Fin ratios.
#  If use_phase_accumulator = FALSE, the duty cycle will always be >= 50%,
#  or <= 50%, depending on the particular divider, unless the generic
#  improve_duty_cycle is TRUE, in which case the duty cycle will average to 50%.
#  (A falling edge ff is used when improve_duty_cycle is TRUE.)
#  If use_phase_accumulator = TRUE, the duty cycle will average to 50% in the
#  long term, but it will vary above and below 50% in the short term.
#  ("Short term" and "long term" depend on the divider.  Ratios like
#  Fout/Fin = 0.4 (exactly) will cause "short term" to be effectively infinite.)
#  The duty cycle is made to be closer to 50%
#  by setting the improve_duty_cycle generic, at some cost in area.
#  The 50% duty cycle output is not implemented for Fout/Fin ratios >= 1/2.
#
#  4. The "shebang" line (first line in this file) may need be changed
#  to suit local conditions.  (Only relevant if running under unix.)
#  Also, unix perl will not like carriage returns left at the end of lines
#  by DOS text editors.
#  *** Fixed in version 0.09  Shebang line is now portable.
#
#  5. Sometimes, if the tolerance is very tight, the controller process
#  will contain a case statement with more branches than the VHDL compilers
#  can handle.  Relax the tolerance in this case (or hand code a better
#  controller).  The -g switch might help here, by disabling generation of
#  that code.
#
#  6. The generated VHDL code is probably far from optimal for the
#  particular target architecture you want to use.  You could
#  hand edit the code to improve area and/or speed.
#
#  7.  The flip flop count is only approximate.  VHDL synthesisers may
#  replicate or remove flip flops.
#  The flip flop count also may not accurately reflect the area used in
#  the target architecture, as combinatorial logic and routing also affect
#  the result.
#  (The phase accumulator architecture is better in this respect, as the
#  area results are more predictable.)
#  The only way to accurately determine the area is to run the design through
#  the synthesis, place and route tools.
#
#  8.  There is no phase relationship defined between output_50 and
#  output_pulse.  (This is more a feature than a bug, and will not be fixed,
#  because it is expected that only one of output_50 and output_pulse will
#  be used for a particular design.)
#
#  9.   If the improve_duty_cycle generic is true and Fout < 1/2 Fin,
#  the output_50 output is taken from combinatorial logic,
#  rather than directly from the output of a flip flop.
#  There is no chance of glitches, however, as the comb. logic consists
#  of a two input function, and the inputs can never change at the same time.
#  One input comes from a rising edge triggered flip flop, and the other comes
#  from a falling edge triggered flip flop.
#  (The backend tools might need to be told about the timing requirements.)

################################################################################
# Test Status:
#  1.  Generating the VHDL.  This Perl script has been tested under NT using
#  Perl 5.004 and 5.005, and on HPUX using Perl 5.003.
#  (Watch the carriage returns when using unix Perl.)
#
#  2.  Simulating the VHDL.  The TCL regression test tries many different
#  randomly selected ratios and measures the frequency error and jitter
#  achieved.  So far, tens of thousands of ratios have been tried using
#  Modelsim PE 5.5e, SE 5.4e, PE 5.4d and
#  Simili 1.4 build 34, 1.5 build 17b and 2.0 build 17.
#  Modelsim gives spurious warnings of the form:
#  WARNING[5]: fracn.vhd(259): Nonresolved signal controller_count may have multiple sources.
#  These warnings may safely be ignored as  there can only be one driver
#  for that signal.
#
#  2b.  Simulating the Verilog.  Still undergoing testing...
#
#  3.  Synthesis of the VHDL.
#  Several dividers have been tried
#  in Synplify 6.0.0, 6.2.0, 7.0.2, with Xilinx Virtex-e as a target.
#  It compiled ok, and Synplify didn't give any warnings.
#  The RTL and technology views [Synplify produces schematics from the code]
#  looked ok.
#  Estimated speeds were well above 100MHz in all cases.
#
#  It has also been tested with the MAX+PLUS2 compiler, which didn't work
#  at all.  This appears to be the fault of the MAX+PLUS2 compiler.
#  There is no plan to make the generated code work with this compiler.
#
#  4.  Routing the sythesised EDIF.  This has been tried for a few different
#  dividers in "production designs" running at up to 166MHz.
#  No problems have been encountered.

################################################################################
# Music Disclaimer:
#  This script was written while listening to the following music:
#  The Saints, Joy Division, The Jon Spencer Blues Explosion,
#  My Bloody Valentine, P J Harvey, Slint, Swervedriver, The Birthday Party,
#  Black Flag, The Stooges ...
#  Version 0.09 changes were made while listening to the music of
#  Spencer P. Jones.

################################################################################
# Revision information:
#
#  0.02 Allan H.    Added VHDL code generation.
#
#  0.03 30-11-00 Allan H.
#   Changed initial value of $num_bits from 1 to 0 to allow /2 phase
#   accumulators to only use 1 ff.
#
#  0.04 23-12-00 Allan H.
#   Now allows Fin/Fout ratio to go all the way down to 1
#   (previously only went to 2).
#   The 50% duty cycle output "output" is now disabled for Fout/Fin > 1/2.
#
#   "Odd one out" processing was reintroduced to improve vcom times by
#   reducing the size of the case statement under certain corner cases.
#   This requires async sets on some ff.
#
#  0.05 26-12-00 Allan H.
#   Added negative edge ff to the 50% duty cycle prescaler output to
#   improve the duty cycle.  Borrowed from an idea by Walter Baeck.
#   There is a new generic "improve_duty_cycle" to enable this behaviour.
#
#   Changed controller_table array to a string for memory size reduction.
#   (Particularly noticable with dividers like fracn05.pl -t 1e-7 1e7 9999999)
#   This hurts execution time slightly, but can save hundreds of Mbytes!
#
#  0.06 28-12-00 Allan H.
#   Added recursive controller
#
#   Added -g flag to inhibit generation of "low jitter" controller,
#   as this was causing Modelsim vcom to crash sometimes when the case
#   statement became excessively large.  This would only happen for
#   certain ratios when the tolerance was very tight (1e-10).
#
#   Added -c flag to disable convergence checks.
#
#   Phase accumulator constant can now be > 32 bits.
#
#   Various code cleanups.  (It's still ugly though.)
#
#  0.07 31-12-00 Allan H.
#    Added "improve duty cycle" for the phase accumulator.
#    (This also improves jitter (for the output_50 output of the P.A. only).)
#    Dividers like Fout/Fin = 0.4000 still aren't perfect, as (in this case)
#    the duty cycle will slowly drift between 0.4 and 0.6, but there's not
#    much we can do about this (not using the phase accumulator might be
#    one workaround).  Such poor ratios are quite rare, though.
#    Fout/Fin = 0.5000 caused a problem with code generation for the
#    duty cycle improver, so this ratio now results in the output_50 output
#    being removed.  Previously this only happened for Fout/Fin ratios just
#    greater than 0.5000 .  This does not cause a loss of functionality,
#    as the output_pulse output has a 50% duty cycle for this particular
#    ratio.
#
#  0.08 24-2-01 Allan H.
#    Added -u option to use Synopsys std_logic_unsigned instead of
#    IEEE.numeric_std, as some users had reported that their tools
#    wouldn't work with numeric_std.
#    Also added -s option to use Synopsys std_logic_arith.
#
#    Added -x option, which is ignored.  This worked around a bug in the
#    TCL regression test, which would sometimes have command line arguments
#    that were null strings, which would cause this script to give an error.
#    The -x option can be used in place of the null strings.
#
#    Some minor changes to the generated comments, to reflect recent changes
#    to the code.
#
#  0.09 26-12-01 Allan H.
#    Changed default tab size to 4.
#
#    Added experimental Verilog code generation.  (This may take some time to
#    get right - I'm a Verilog newbie.)
#    Currently only the recursive controller is supported in the generated
#    Verilog file.  This may improve once I work out a reasonable equivalent
#    of the VHDL "generate" statement in Verilog.
#
#    Changed -f option to the base of the output filename, rather than the
#    entire output filename.
#    E.g. before:  "-f file"  produced a file called "file".
#         now:     "-f file"  produces a file called "file.vhd" and another
#                                             called "file.v".
#    There is no way to change the extensions.  VHDL always uses ".vhd", and
#    Verilog always uses ".v".
#
#    Changed email address in generated code to fractional_divider@hotmail.com
#    was: allanherriman@hotmail.com - this gets too much spam, and it's too
#    easy to miss an important email amongst so much rubbish.
#
#    Changed "warnings" from string to array
#
#    Fixed shebang line (first line in file) to make it more portable
#
#    Added ability to indent with tabs instead of spaces.
#    Previously the option "-i n" would indent with n spaces, for n > 0.
#    Now n = 0 will indent with tabs.

################################################################################
# To Do:
#
#  * "Hybrid controller" which is a combination of the recursive controller
#    and the minimum jitter controller.  The swap from recursive controller to
#    minimum jitter controller should be made when the size of the case
#    statement would be small enough (say 16 or 32).
#    This should result in overall savings in area at no cost in speed.
#
#  * More code cleanups.  Sigh.
#
#  * Make generated code look like the FMF or OpenCores coding style (yuck).

use vars qw($version);
$version = "0.09";

use strict;

use POSIX;              # need this for floor() and ceil()
use Text::Tabs;         # need this for expanding tabs

# Error message for command line errors
sub usage_exit {
    foreach my $message (@_) {
        print $message;
    }
    print "\n";
    print "Fractional-N divider VHDL and Verilog code generator\n";
    print "Usage: $0 [options] input_frequency output_frequency\n";
    print "Options:\n";
    print " -t num      sets tolerance of output_frequency (default 1e-7)\n";
    print " -g          inhibit generation of \"low jitter\" controller\n";
    print " -c          inhibit convergence checking (use with caution)\n";
    print " -i num      sets size of code indent (default 4).  Uses tabs if num is 0\n";
    print " -v          toggles verbose mode\n";
    print " -s          use std_logic_arith instead of IEEE.numeric_std (VHDL)\n";
    print " -u          use std_logic_unsigned instead of IEEE.numeric_std (VHDL)\n";
    print " -a string   sets architecture name (VHDL) (default \"rtl\")\n";
    print " -e string   sets entity name (VHDL) or module name (Verilog) (default \"fracn\")\n";
    print " -f string   sets base part of file name (defaults to entity or module name)\n";
    print "             VHDL file is <string>.vhd, and Verilog file is <string>.v\n";
    print "Frequency arguments are in Hz\n";
    print "Examples:\n";
    print "$0 1000000 32768\n";
    print " produces VHDL file fracn.vhd and Verilog file fracn.v which contain a divider\n";
    print " which will produce a 32.768kHz output from a 1MHz input\n";
    print "$0 -a arch -e ent -f file -t 1e-9 77.76e6 1.544e6\n";
    print " produces VHDL file file.vhd and Verilog file file.v which contain a divider\n";
    print " which will produce a 1.544MHz output from a 77.76MHz input\n";
    exit 1;
}

use vars qw(@warnings);
@warnings = (); # the collected set of warnings

# warning messages come here
# messages must not contain '\n'
sub warning {
    foreach my $message (@_) {
        print $message . "\n";
        push @warnings, ("* " . $message . "\n");
    }
}

############### Work out the design requirements ###############################

# some global variables (more later...)
use vars qw($tolerance $entity_name $architecture_name);
use vars qw($base_name $vhdl_name $verilog_name);
use vars qw($low_jitter_controller $convergence_check $tabstop $verbose);
use vars qw($std_logic_arith $std_logic_unsigned);

# default parameters
$tolerance = 1.0e-7;        # default allowable relative tolerance on fout (+/-)
$entity_name = "fracn";     # default name of entity in generated VHDL
$architecture_name = "rtl"; # default name of architecture in generated VHDL
$low_jitter_controller = 1; # on by default
$convergence_check = 1;     # on by default
$tabstop = 4;               # size of indent in generated code
$verbose = -t STDOUT;       # on by default iff connected to tty
$std_logic_arith = 0;       # off by default (default to lib IEEE.numeric_std)
$std_logic_unsigned = 0;    # off by default (default to lib IEEE.numeric_std)

# process command line arguments

use vars qw(@argv_orginal);
@argv_orginal = @ARGV; # save for later...

do {
    use Getopt::Std;        # for command line parsing...
    my %opts;
    getopt('aefhHit', \%opts);

    foreach (keys %opts) {
        #print "$_\t" . (defined $opts{$_} ? $opts{$_} : "undefined") . "\n";
        SWITCH : {
            if (/^a$/) { $architecture_name = $opts{$_}; last SWITCH; }
            if (/^e$/) { $entity_name       = $opts{$_}; last SWITCH; }
            if (/^f$/) { $base_name         = $opts{$_}; last SWITCH; }
            if (/^t$/) { $tolerance         = $opts{$_}; last SWITCH; }
            if (/^i$/) { $tabstop           = $opts{$_}; last SWITCH; }
            if (/^s$/) { $std_logic_arith = 1;           last SWITCH; }
            if (/^u$/) { $std_logic_unsigned = 1;        last SWITCH; }
            if (/^g$/) { $low_jitter_controller = 0;     last SWITCH; }
            if (/^c$/) { $convergence_check = 0;         last SWITCH; }
            if (/^v$/) { $verbose = not $verbose;        last SWITCH; }
            if (/^x$/) {                                 last SWITCH; } # magic ignored option!
            if (/^h$/i) { usage_exit;                    last SWITCH; }   # help
            usage_exit("unknown option '$_'\n");
        }
    }
};

usage_exit("Wrong number of arguments\n") if ($#ARGV != 1);

# more global variables
use vars qw($fin $fout $desired_ratio $min_ratio $max_ratio);
use vars qw($floor_max_ratio $floor_min_ratio $ceil_min_ratio);

$fin = $ARGV[0] + 0;    # input clock frequency (Hz)
$fout = $ARGV[1] + 0;   # desired output frequency (Hz)

# Check for bad input
usage_exit("Bad architecture name option\n")
    if ((not defined $architecture_name) or ($architecture_name !~ /^[a-z][a-z0-9_]+$/i));

usage_exit("Bad entity name option\n")
    if ((not defined $entity_name) or ($entity_name !~ /^[a-z][a-z0-9_]+$/i));

# output file names
$base_name = $entity_name if (not defined $base_name);
$vhdl_name = "$base_name.vhd";
$verilog_name = "$base_name.v";

usage_exit("Indent size must be a number\n") unless ($tabstop > 0 or $tabstop eq "0");

usage_exit("Can't use std_logic_arith and std_logic_unsigned at the same time\n")
    if ($std_logic_arith and $std_logic_unsigned);

# check for input that would cause numeric problems.
usage_exit("frequencies must be > 0Hz\n") if ($fin <= 0 or $fout <= 0);
usage_exit("Fin/Fout ratio too small\n") if ($fin/$fout < 1);
#usage_exit("Fin/Fout ratio too small\n") if ($fin/$fout < 2); # can't do /1 prescaler?!
usage_exit("Fin/Fout ratio too big\n") if (($fin/$fout > 1e12) and $convergence_check);
usage_exit("tolerance must be > 0\n") if ($tolerance <= 0);
usage_exit("tolerance too tight (try something like 0.0000001, or use the -c switch)\n") if (($tolerance < 1e-15) and $convergence_check);
usage_exit("tolerance too loose (try something like 0.0001)\n") if (($tolerance >= 1) and $convergence_check);

$desired_ratio = ($fin / $fout);
$min_ratio = ($fin / ($fout * (1 + $tolerance)));
$max_ratio = ($fin / ($fout * (1 - $tolerance)));

#print "trying ratios between $min_ratio and $max_ratio\n";

# get the integer upper and lower bounds
$floor_max_ratio = floor($max_ratio);
$floor_min_ratio = floor($min_ratio);
$floor_min_ratio = 1 if ($floor_min_ratio == 0);    # fix for ratios close to 1
$ceil_min_ratio  = ceil($min_ratio);

die "numeric problems" if ($floor_max_ratio <= 0 or $floor_min_ratio <= 0);

if (not $low_jitter_controller) {
    warning("Warning: the controller enabled by the \"minimum_jitter\" generic has",
            "  not been implemented due to the -g command line switch.");
}

if ($std_logic_unsigned) {
    warning("Warning: std_logic_unsigned library has been used",
            "  due to the -u command line switch.");
}
if ($std_logic_arith) {
    warning("Warning: std_logic_arith library has been used",
            "  due to the -s command line switch.");
}

############### Design the prescaler (choose a value for n) ####################
print "designing prescaler\n" if ($verbose);

use vars qw($n);    # more global variables

$n = $floor_min_ratio;

# check to see if a straight integer divider will do
if ($floor_max_ratio >= $ceil_min_ratio) {
    warning("Warning: a fractional-N divider is not needed.");
    if ($floor_max_ratio > $ceil_min_ratio) {
        warning("  Integer dividers $ceil_min_ratio to $floor_max_ratio are ok.");
        $n = $floor_max_ratio;
    }
    else {
        warning("  Integer divider $floor_max_ratio is ok.");
        $n = $floor_max_ratio;
    }
}

#print "/$n,/" . ($n + 1) . " prescaler\n";

############## Design the controller (choose values for a and b) ###############
print "designing controller\n" if ($verbose);

use vars qw($a $b $ratio $fout_achieved $error_achieved);    # more global variables

$a = 1;     # number of /n cycles
$b = 0;     # number of /(n+1) cycles

do {
    my $iterations_remaining = $convergence_check ? 1e7 : 1e12;

    # try different values of a and b until the ratio falls between min_ratio and
    # max_ratio
    while (1)
    {
        die "No convergence - try adjusting tolerance or use -c switch\n" .
            "Current values are a=$a b=$b"
            unless (--$iterations_remaining);

        $ratio = ($a * $n + $b * ($n + 1))/($a + $b);

        if ($ratio < $min_ratio) {
            # too small
            $b++;
            next;
        }
        if ($ratio > $max_ratio) {
            # too big
            $a++;
            next;
        }
        # just right, Goldilocks
        last;
    }
};

$fout_achieved = $fin/$ratio;               # Hz
$error_achieved = $fout_achieved - $fout;   # Hz

if (abs($error_achieved / $fout) > $tolerance) {
    warning("Warning: Dual Modulus Prescaler design did not meet frequency tolerance target.");
}

############ Work out the jitter performance ###################################

use vars qw($bad_jitter $good_jitter $controller_table); # more global variables

# calculate jitter performance, for "high jitter" controller architecture
$bad_jitter  = $a * ($ratio - $n) / $fin;
#$bad_jitter = $b * ($n + 1 - $ratio) / $fin; # should be the same

print "calculating controller table\n" if ($verbose);
do {
    # work out distribution of /n,/n+1 for better jitter performance
    # (used in "low jitter" architecture)
    my $used_a = 0;
    my $used_b = 0;

    my $desired_trajectory = $a / ($a + $b);

    # The array controller_table contains the distribution of /n, /n+1
    # (changed from an array to a string in version 0.05 to save space.)
    $controller_table = "";
    # work out first entry (be careful, sometimes $b may be 0)
    if ( $a > $b ) {
        (substr $controller_table, 0, 1) = '1';
        $used_a++;
    }
    else {
        (substr $controller_table, 0, 1) = '0';
        $used_b++;
    }

    # work out rest of table for "maximum interleaving" (which gives minimum jitter)
    for (my $index = 1; $index < $a + $b; $index++)
    {
        if ( $used_a / $index > $desired_trajectory ) {
            (substr $controller_table, $index, 1) = '0';
            $used_b++;
        }
        else {
            (substr $controller_table, $index, 1) = '1';
            $used_a++;
        }
    }

    die "Numeric problem in jitter reducer" unless ($used_a == $a and $used_b == $b);
};

print "estimating jitter\n" if ($verbose);
do {
    my $total_outputs = 0;
    my $total_input_clocks = 0;
    my $max_pos_error = 0;
    my $max_neg_error = 0;

    # now measure the jitter
    for (my $index = 0; $index < $a + $b; $index++)
    {
        $total_input_clocks += (substr $controller_table, $index, 1) ? $n : $n + 1;
        $total_outputs++;
        my $phase_error = $total_input_clocks - ($ratio * $total_outputs);
        $max_pos_error = $phase_error if ( $max_pos_error < $phase_error );
        $max_neg_error = $phase_error if ( $max_neg_error > $phase_error );
    }

    $good_jitter  = ($max_pos_error - $max_neg_error) / $fin;
};


############### Design the recursive controller ################################
print "designing recursive controller\n" if ($verbose);

# The modulus control signal for the prescaler can be generated by another
# fractional-N divider, which in turn can have its modulus control signal
# generated by yet another fractional-N divider, and so on.
# We stop when we don't need another fractional-N divider, and can just use
# a fixed divider.
# The particular arrangement we use also produces the minimum possible jitter.

use vars qw($stage @n_array @m_array @a_array @b_array @i_array); # more global variables
use vars qw($ff_count_recursive_controller); # more global variables

$stage = 0;
# Stage is (roughly) the number of recursive stages needed:
#  Stage  0 is the prescaler we've already designed
#  Stages 1 .. $stage are the recursive dual modulus dividers
#  Stage  $stage + 1 is the fixed divider at the end

$n_array[$stage] = $n;  # this stage divides by n or n+1
$m_array[$stage] = 'X'; # Controls duty cycle of modulus control output from this stage.
$a_array[$stage] = $a;  # This stage requires its modulus control input to be low for this number of cycles
$b_array[$stage] = $b;  # This stage requires its modulus control input to be high for this number of cycles
$i_array[$stage] = 'X'; # Invert the output of this stage

#print "n$stage=$n\tm$stage=\ta$stage=$a\tb$stage=$b\ti$stage=\n";

while ($b_array[$stage] > 1.0001 and $a_array[$stage] > 1.0001) {
    my $n1 = $n_array[$stage];
    my $a1 = $a_array[$stage];
    my $b1 = $b_array[$stage];
    my $n2; my $m2; my $a2; my $b2; my $i2;
    my $determinant;
    die "negative count" if ($n1 < 0 or $a1 < 0 or $b1 < 0);
    $i2 = ($a1 < $b1) ? 1 : 0;
    if ( $i2 ) {
        $n2 = floor(($a1 + $b1) / ($a1));
        $m2 = ceil($b1 / $a1);
        # we have a1, b1, and we know how to determine a1, b1 from a2, b2,
        # so invert the 2x2 matrix to work out a2, b2 from a1, b1.
        $determinant = ($n2 - $m2 + 1);
        die "singular matrix" if ($determinant == 0);
        $a2 = ($m2 * $a1 - ($n2 + 1 - $m2) * $b1) / $determinant;
        $b2 = ((1 - $m2) * $a1 + ($n2 + 1 - $m2) * $b1) / $determinant;
    }
    else {
        $n2 = floor(($a1 + $b1) / ($b1));
        $m2 = ceil($a1 / $b1);
        $determinant = ($m2 - $n2 - 1);
        die "singular matrix" if ($determinant == 0);
        $a2 = (($n2 + 1 - $m2) * $a1 - $m2 * $b1) / $determinant;
        $b2 = (($m2 - $n2 - 1) * $a1 + ($m2 - 1) * $b1) / $determinant;
    }
    $stage++;
    $n_array[$stage] = $n2;
    $m_array[$stage] = $m2;
    $a_array[$stage] = $a2;
    $b_array[$stage] = $b2;
    $i_array[$stage] = $i2;
    #print "n$stage=$n2\tm$stage=$m2\ta$stage=$a2\tb$stage=$b2\ti$stage=$i2\n";
    die "too many stages in recursive controller" if ($stage > 15 and $convergence_check);
}

# fill in the parameters for the last (non-fractional) stage
$n_array[$stage + 1] = $a_array[$stage] + $b_array[$stage] - 1;
$m_array[$stage + 1] = $a_array[$stage];
$a_array[$stage + 1] = 'X';
$b_array[$stage + 1] = 'X';
$i_array[$stage + 1] = 0;

# work out how many ff are used.

$ff_count_recursive_controller = 0;

for (my $s = 1; $s <= $stage + 1; $s++) {
    $ff_count_recursive_controller++;   # for stageN_output retime
    $ff_count_recursive_controller++;   # for stageN_carry retime
    $ff_count_recursive_controller += (ceil(log($n_array[$s] + 1) / log(2))); # counter
}

$ff_count_recursive_controller--;   # no carry from last stage!

############### Design the phase accumulator ###################################
print "designing phase accumulator\n" if ($verbose);

use vars qw($num_bits $c $ratio_pa $fout_achieved_pa $error_achieved_pa); # more global variables

$num_bits = 0;

while (1)
{
    $num_bits++;
    $c =   floor(0.5 + ((2 ** $num_bits) / $desired_ratio));
    next if ($c == 0);

    $ratio_pa = (2 ** $num_bits) / $c;

    last if (($ratio_pa <= $max_ratio) and ($ratio_pa >= $min_ratio));  # ok
    #last if ($c > (2 ** 30));   # avoid overflowing integers in VHDL
    last if (($num_bits > 56) and $convergence_check);   # exceeding Perl floating point accuracy!
}

$fout_achieved_pa = $fin / $ratio_pa;           # Hz
$error_achieved_pa = $fout_achieved_pa - $fout; # Hz

if (abs($error_achieved_pa / $fout) > $tolerance) {
    warning("Warning: Phase accumulator design did not meet frequency tolerance target.");
}

############### Check for Fout > 1/2 Fin #######################################

# If the output frequency is > 1/2 the input frequency, the 50% duty
# cycle output doesn't make sense, so we need to detect this special case.
# We also disable for >= 1/2, to get around code generation problem in
# phase accumulator jitter improver.

use vars qw($gen_50_percent_output); # more global variables

#$gen_50_percent_output = ($fin/$fout >= 2);
#$gen_50_percent_output = (($c <= (2 ** ($num_bits - 1))) and ($n > 1));
$gen_50_percent_output = (($c < (2 ** ($num_bits - 1))) and ($n > 1));  # ver 07

if (not $gen_50_percent_output) {
    warning("Warning: Fin/Fout ratio < 2.",
            "  The 50% duty cycle output \"output_50\" has not been implemented.");
}

#$gen_50_percent_output = 1;    # use this to test test bench.

############### generate some VHDL and Verilog #################################

# open vhdl file
print "opening $vhdl_name\n" if ($verbose);
rename $vhdl_name, "$vhdl_name.bak";
open (VHDL, ">$vhdl_name") or die "Can't open VHDL file $vhdl_name: $!";

# open verilog file
print "opening $verilog_name\n" if ($verbose);
rename $verilog_name, "$verilog_name.bak";
open (VERILOG, ">$verilog_name") or die "Can't open Verilog file $verilog_name: $!";

# subs for optionally expanding tabs to spaces before writing to files
# (the "expand" sub uses the value of the global variable "tabstop")
sub vhdl {
    foreach my $line (@_) {
        print VHDL ($tabstop > 0) ? expand($line) : $line;
    }
}

sub verilog {
    foreach my $line (@_) {
        print VERILOG ($tabstop > 0) ? expand($line) : $line;
    }
}

# write a comment to both files
sub comment
{
    foreach my $line (@_) {
        if ( $line =~ m/^(\t+)(.*)$/s ) {
            # indented comment, maintain leading tabs
            vhdl    $1 . "--" . $2;
            verilog $1 . "//" . $2;
        }
        else {
            # comment at left margin
            vhdl    "--" . $line;
            verilog "//" . $line;
        }
    }
}

# write a solid "separator" line to both files
sub comment_line
{
    vhdl    "-" x 80 . "\n";
    verilog "/" x 80 . "\n";
}

# returns "unsigned" or "std_logic_vector" depending on whether we
# are using IEEE.numeric_std or Synopsys std_logic_unsigned library.
sub unsigned {
    return ($std_logic_unsigned ? "std_logic_vector" : "unsigned");
}

# Work out whether a word is plural (returns "" or "s", depending on whether
# the numeric argument is equal to 1)
sub plural {
    return ($_[0] == 1 ? "" : "s");
}

# function that returns the number of bits needed to hold integer range 0 to arg
sub log2
{
    use integer;
    my $result = 0;
    my $count = $_[0];

    while ($count > 0) {
        $result = $result + 1;
        $count = $count / 2;
    }
    no integer;
    return $result;
}

print "writing to $vhdl_name and $verilog_name\n" if ($verbose);

# write file header
comment_line;
vhdl    "-- File         : $vhdl_name (machine generated)\n";
vhdl    "-- Contains     : entity $entity_name (architecture $architecture_name)\n";
verilog "// File         : $verilog_name (machine generated)\n";
verilog "// Contains     : module $entity_name\n";
comment " Author       : $0  (version $version)\n";
comment " Command Line : $0 @argv_orginal\n";
comment " Date         : " . (scalar localtime) . "\n";
comment " Complain to  : fractional_divider\@hotmail.com\n";
comment "\n";
vhdl    "-- This machine generated VHDL file contains a fixed ratio frequency divider.\n";
verilog "// This machine generated Verilog file contains a fixed ratio frequency divider.\n";
comment " Different styles of dividers can be selected by generics or parameters.\n";
comment "\n";
comment "  use_phase_accumulator = TRUE   selects a \"classic\" phase accumulator\n";
comment "                                 frequency divider\n";
comment "\n";
comment "  use_phase_accumulator = FALSE  selects a frequency divider made up of\n";
comment "                                 a dual modulus prescaler and a controller\n";
comment "                                 In this case, the generics \"minimum_jitter\"\n";
comment "                                 and \"use_recursive_controller\"\n";
comment "                                 control size / jitter tradeoffs in\n";
comment "                                 the controller.\n";
comment "\n";
comment " The phase accumulator style divider has a regular structure (in the sense\n";
comment " that it doesn't change much if the ratio is changed - which is good for\n";
comment " floorplanning) and it is quite easy to understand.\n";
comment " The output frequency is a rational multiple of the input frequency in\n";
comment " the form:\n";
comment "\n";
comment "       c\n";
comment " --------------- * Fin\n";
comment " (2 ** num_bits)\n";
comment "\n";
comment " where c and num_bits are integers.\n";
comment " The hardware consists of a constant adder, so it will be simple to\n";
comment " make it work at high speed.\n";
comment " The output jitter will generally be equal to or just less than one\n";
comment " cycle of the input clock.\n";
comment " Here is a block diagram:\n";
comment " \n";
comment " 'clock'-----------------------+\n";
comment "                               |\n";
comment "             +-------+    +----------+\n";
comment " Constant--->|       |    |          |\n";
comment " 'c'         | Adder |--->| Register |-+-->'phase'\n";
comment "          +->|       |    |          | |\n";
comment "          |  +-------+    +----------+ |\n";
comment "          |                            |\n";
comment "          +----------------------------+\n";
comment "\n";
comment " The MSB of the 'phase' signal has approximately a 50% duty cycle, and\n";
comment " is retimed (in another ff not shown) and used as the 'output_50' output.\n";
comment " The carry output of the adder will be high once every output cycle,\n";
comment " and is registered (in another ff not shown) and used as the\n";
comment " 'output_pulse' output.\n";
comment "\n";
comment "\n";
comment " The dual modulus prescaler divider is somewhat harder to understand, but\n";
comment " it may result in less hardware, and it may enable the exact ratio to\n";
comment " be produced.\n";
comment " In this case, the output frequency is a rational multiple of the input\n";
comment " frequency in the form:\n";
comment "\n";
comment "       (a + b)\n";
comment " ----------------------- * Fin\n";
comment " (a * n) + (b * (n + 1))\n";
comment "\n";
comment " where a, b, and n are integers.\n";
comment " The dual modulus prescaler divides the input clock by n or (n+1).\n";
comment " The controller causes the prescaler to divide by n for a cycles of the\n";
comment " output, and divide by (n+1) for b cycles of the output.\n";
comment " Depending on how these a and b cycles are mixed up, the output\n";
comment " jitter will vary.\n";
comment " There are a number of ways to make the controller.\n";
comment " If the generic use_recursive_controller is TRUE, the controller consists\n";
comment " of a state machine that produces the best interleaving of the a and b cycles,\n";
comment " which gives about the same jitter as the phase accumulator.\n";
comment " If use_recursive_controller is FALSE, the controller consists of a counter\n";
comment " and a lookup table to interleave the a and b cycles.\n";
comment " There are more tradeoffs: if the generic minimum_jitter is FALSE, the lookup\n";
comment " table bunches all the a cycles together, and all the b cycles together.\n";
comment " This results in simple hardware, but may produce lots of jitter.\n";
comment " If the generic minimum_jitter is TRUE, the lookup table produces the best\n";
comment " interleaving of the a and b cycles, but it may result in an excessively\n";
comment " large case statement.\n";

comment " (It will usually be possible to come up with a much better\n";
comment " controller design by hand, but the details vary so much with\n";
comment " the choice of frequencies that it is hard to generalise this\n";
comment " into a simple script.)\n";
if (not $low_jitter_controller) {
    comment " Note: the minimum_jitter controller has not been implemented in this file,\n";
    comment " so don't set the generic minimum_jitter to TRUE.\n";
}
comment " Here is a block diagram:\n";
comment "\n";
comment "             +--------------+\n";
comment "             | Dual modulus | 'prescaler_out'\n";
comment " 'clock'---->|  Prescaler   |------+--------->\n";
comment "             | /n or /(n+1) |      |\n";
comment "             +--------------+      |\n";
comment "                    ^              |\n";
comment "                    |       +------------+\n";
comment "                    |       |            |\n";
comment "                    +-------| Controller |\n";
comment "          'modulus_control' |            |\n";
comment "                            +------------+\n";
comment "\n";
comment "\n";
comment " For a given set of input to output frequency ratio and tolerance,\n";
comment " the only way to work out which type of divider is better is\n";
comment " to try them!  Generally, the phase accumulator is better for\n";
comment " loose tolerances (> 10ppm), and the dual modulus prescaler is\n";
comment " better if the ratio must be exact, but this depends on the ratio.\n";
comment "\n";

comment " Frequency Parameters:\n";
comment " Input Frequency: $fin Hz.\n";
comment " Desired Output Frequency: $fout Hz.\n";
comment " Requested Relative Frequency Error Bounds (+/-) : $tolerance (" . ($tolerance * 1e6) . " ppm)\n";
comment "\n";

comment " Frequency Results (use_phase_accumulator = FALSE) :\n";
comment "  Achieved Output Frequency: $fout_achieved Hz.\n";
comment "  Achieved Relative Frequency Error: " . ($error_achieved / $fout) . " (" . (($error_achieved / $fout) * 1e6) . " ppm)\n";
comment "  Achieved Frequency Error: $error_achieved Hz.\n";
comment "\n";

comment " Frequency Results (use_phase_accumulator = TRUE) :\n";
comment "  Achieved Output Frequency: $fout_achieved_pa Hz.\n";
comment "  Achieved Relative Frequency Error: " . ($error_achieved_pa / $fout) . " (" . (($error_achieved_pa / $fout) * 1e6) . " ppm)\n";
comment "  Achieved Frequency Error: $error_achieved_pa Hz.\n";
comment "\n";

comment " Output Jitter Parameters (use_phase_accumulator = FALSE) :\n";
comment "  The fundamental frequency is " . ($fin / ($a * $n + $b * ($n + 1))) . " Hz.\n";
comment "  The amplitude is $bad_jitter seconds p-p (minimum_jitter = FALSE).\n";
comment "  The amplitude is $good_jitter seconds p-p (minimum_jitter = TRUE).\n";
comment "\n";

comment " Output Jitter Parameters (use_phase_accumulator = TRUE) :\n";
comment "  The fundamental frequency is " . ($fin / (2 ** $num_bits)) . " Hz.\n";
comment "  The amplitude is " . (1 / $fin) . " seconds p-p (approx).\n";
comment "\n";

comment " Design Parameters (use_phase_accumulator = FALSE) :\n";
comment "  Approx " .
           ((ceil(log($n + 1) / log(2)) + 2) + (ceil(log($a + $b) / log(2)) + 1)) .
           " flip flops (" .
           (ceil(log($n + 1) / log(2))) . " in prescaler, " .
           (ceil(log($a + $b) / log(2)) + 1) . " in controller and 2 retimes).\n";
comment "  The recursive controller uses approx $ff_count_recursive_controller flip flop" . (plural $ff_count_recursive_controller) . ".\n";
comment "  The Dual-Modulus Prescaler uses ratios /$n,/" . ($n + 1) . "\n";
comment "  The Output consists of $a cycle" . (plural $a) . " of $n input clock" . (plural $n) . ",\n";
comment "  and $b cycle" . (plural $b) . " of " . ($n + 1) . " input clocks.\n";
comment "  There " . (($a + $b) == 1 ? "is" : "are") . " " . ($a + $b) . " output clock" . (plural ($a + $b)) . " for every " . ($a * $n + $b * ($n + 1)) . " input clock" . (plural ($a * $n + $b * ($n + 1))) . ".\n";
comment "\n";

comment " Design Parameters (use_phase_accumulator = TRUE) :\n";
comment "  Approx " . ($num_bits + 2) . " flip flops ($num_bits in accumulator and 2 retimes)\n";
comment "  There " . ($c == 1 ? "is" : "are") . " " . ($c) . " output clock" . (plural $c) . " for every " . (2**$num_bits) . " input clocks.\n";
comment "\n";
# write summary of all dividers generated
do {
    my $old_tabstop = $tabstop;
    $tabstop = 10;
    comment " Divider summary :\n";
    comment "\n";
    comment " Approx\tApprox\tRelative\tApprox\t\n";
    comment "  ff\tVirtex\tFrequency\tJitter\tDivider\n";
    comment " count\tSlices\tError\t(seconds)\t(generic parameters)\n";
    comment "\n";
    comment "  " .
        ($num_bits + 2) .
        "\ttbd" .
        (sprintf "\t%1.2g", ($error_achieved_pa / $fout)) .
        (sprintf "\t%1.2g", (1 / $fin)) .
        "\tuse_phase_accumulator\n";
    comment "  " .
        ($num_bits + 5) .
        "\ttbd" .
        (sprintf "\t%1.2g", ($error_achieved_pa / $fout)) .
        (sprintf "\t%1.2g", (0.5 / $fin)) .
        "\tuse_phase_accumulator improve_duty_cycle\n";
    comment "  " .
        ((ceil(log($n + 1) / log(2)) + 2) + $ff_count_recursive_controller) .
        "\ttbd" .
        (sprintf "\t%1.2g", ($error_achieved / $fout)) .
        (sprintf "\t%1.2g", $good_jitter) .
        "\tuse_recursive_controller\n";
    comment "  " .
        ((ceil(log($n + 1) / log(2)) + 3) + $ff_count_recursive_controller) .
        "\ttbd" .
        (sprintf "\t%1.2g", ($error_achieved / $fout)) .
        (sprintf "\t%1.2g", $good_jitter) .
        "\tuse_recursive_controller improve_duty_cycle\n";
    comment "  " .
        ((ceil(log($n + 1) / log(2)) + 2) + (ceil(log($a + $b) / log(2)) + 1)) .
        "\ttbd" .
        (sprintf "\t%1.2g", ($error_achieved / $fout)) .
        (sprintf "\t%1.2g", $good_jitter) .
        "\tminimum_jitter\n";
    comment "  " .
        ((ceil(log($n + 1) / log(2)) + 3) + (ceil(log($a + $b) / log(2)) + 1)) .
        "\ttbd" .
        (sprintf "\t%1.2g", ($error_achieved / $fout)) .
        (sprintf "\t%1.2g", $good_jitter) .
        "\tminimum_jitter improve_duty_cycle\n";
    comment "  " .
        ((ceil(log($n + 1) / log(2)) + 2) + (ceil(log($a + $b) / log(2)) + 1)) .
        "\ttbd" .
        (sprintf "\t%1.2g", ($error_achieved / $fout)) .
        (sprintf "\t%1.2g", $bad_jitter) .
        "\t(none)\n";
    comment "  " .
        ((ceil(log($n + 1) / log(2)) + 3) + (ceil(log($a + $b) / log(2)) + 1)) .
        "\ttbd" .
        (sprintf "\t%1.2g", ($error_achieved / $fout)) .
        (sprintf "\t%1.2g", $bad_jitter) .
        "\t(none) improve_duty_cycle\n";
    comment "\n";
    $tabstop = $old_tabstop;
};

comment " Warnings:\n";
comment ((@warnings == 0) ? "  none\n" : @warnings);

comment "\n";
comment " Do not fix bugs by hand editing this file - fix the Perl source instead!\n";
comment_line;

# write library use clauses
vhdl "library ieee;\n";
vhdl "use ieee.std_logic_1164.all;\n";
vhdl "-- " if ($std_logic_unsigned or $std_logic_arith);
vhdl "use ieee.numeric_std.all;\n";
vhdl "use ieee.std_logic_unsigned.all;\n" if ($std_logic_unsigned);
vhdl "use ieee.std_logic_arith.all;\n" if ($std_logic_arith);

# no need for library use clauses in Verilog

# write entity declaration
vhdl "\n";
vhdl "entity $entity_name is\n";
vhdl "\tgeneric (\n";
vhdl "\t\tuse_phase_accumulator : boolean := FALSE;\n";
vhdl "\t\t\t-- TRUE uses classic NCO design.\n";
vhdl "\t\t\t-- FALSE uses prescaler / controller design\n";
vhdl "\t\tuse_recursive_controller  : boolean := TRUE;\n";
vhdl "\t\tminimum_jitter        : boolean := FALSE;\n";
if ($low_jitter_controller) {
    vhdl "\t\t\t-- TRUE may use more hardware, but has lowest jitter\n";
    vhdl "\t\t\t-- (only applies when use_phase_accumulator is FALSE)\n";
}
else {
    vhdl "\t\t\t-- Do not set the minimum_jitter generic to TRUE!\n";
    vhdl "\t\t\t-- This file does not contain the code to support it!\n";
    vhdl "\t\t\t-- (The Perl script was run with the \"-g\" option.)\n";
}
vhdl "\t\timprove_duty_cycle    : boolean := TRUE\n";
vhdl "\t\t\t-- TRUE uses a falling edge ff to make the output duty cycle closer to 50%\n";
vhdl "\t);\n";
vhdl "\tport (\n";
vhdl "\t\tasync_reset       : in  std_logic := '0';\t-- active high reset\n";
vhdl "\t\tclock             : in  std_logic;       \t-- $fin Hz input clock\n";
vhdl "\t\tclock_enable      : in  std_logic := '1';\t-- active high clock enable\n";
if ($gen_50_percent_output) {
    vhdl "\t\toutput_50         : out std_logic;\t-- $fout Hz output - approx 50% duty cycle\n";
}
else {
    vhdl "\t\toutput_50         : out std_logic;\t-- This signal not implemented for this divider!\n";
    vhdl "\t\t                                  \t-- It is only available for ratios > 2.\n";
}
vhdl "\t\toutput_pulse      : out std_logic \t-- $fout Hz output - high for single clock per cycle\n";
vhdl "\t);\n";
vhdl "end $entity_name;\n";
vhdl "\n";
vhdl "architecture $architecture_name of $entity_name is\n";
vhdl "\n";

# write module declaration
verilog "\n";
verilog "module $entity_name (async_reset, clock, clock_enable, output_50, output_pulse);\n";
verilog "\tinput  async_reset; \t// active high reset\n";
verilog "\tinput  clock;       \t// $fin Hz input clock\n";
verilog "\tinput  clock_enable;\t// active high clock enable\n";
if ($gen_50_percent_output) {
    verilog "\toutput output_50;   \t// $fout Hz output - approx 50% duty cycle\n";
}
else {
    verilog "\toutput output_50;   \t// This signal not implemented for this divider!\n";
    verilog "\t                    \t// It is only available for ratios > 2.\n";
}
verilog "\toutput output_pulse;\t// $fout Hz output - high for single clock per cycle\n";
verilog "\n";

# write list of parameters
verilog "\tparameter use_phase_accumulator     = 0;\n";
verilog "\t\t// TRUE uses classic NCO design.\n";
verilog "\t\t// FALSE uses prescaler / controller design\n";
verilog "\tparameter use_recursive_controller  = 1;\n";
verilog "\tparameter minimum_jitter            = 0;\n";
if ($low_jitter_controller) {
    verilog "\t\t// TRUE may use more hardware, but has lowest jitter\n";
    verilog "\t\t// (only applies when use_phase_accumulator is FALSE)\n";
}
else {
    verilog "\t\t// Do not set the minimum_jitter generic to TRUE!\n";
    verilog "\t\t// This file does not contain the code to support it!\n";
    verilog "\t\t// (The Perl script was run with the \"-g\" option.)\n";
}
verilog "\tparameter improve_duty_cycle        = 1;\n";
verilog "\t\t// TRUE uses a falling edge ff to make the output duty cycle closer to 50%\n";
verilog "\n";

# write list of signals and constants
comment "\t definitions for prescaler / controller design\n";
vhdl    "\tconstant n              : positive := $n;\t-- prescaler divides by n or n + 1\n";
verilog "\tparameter n  = $n;\t// prescaler divides by n or n + 1\n";
vhdl    "\tconstant a              : positive := $a;\t-- this many counts of $n\n";
verilog "\tparameter a  = $a;\t// this many counts of $n\n";
vhdl    "\tconstant b              : natural  := $b;\t-- this many counts of " . ($n + 1) . "\n";
verilog "\tparameter b  = $b;\t// this many counts of " . ($n + 1) . "\n";
vhdl    "\tsignal modulus_control  : std_logic;\n";
verilog "\twire modulus_control;\n";
vhdl    "\tsignal prescaler_count  : integer range 0 to n;\n";
verilog "\treg [" . (log2($n) - 1) . ":0] prescaler_count;\n";
vhdl    "\tsignal controller_count : integer range 0 to a + b - 1;\n";
verilog "\treg [" . (log2($a + $b - 1) - 1) . ":0] controller_count;\n";
vhdl    "\tsignal prescaler_out    : std_logic;\n";
verilog "\treg prescaler_out;\n" if ($n > 1);
verilog "\twire prescaler_out;\n" if ($n <= 1);
vhdl    "\tsignal prescaler_out_50 : std_logic;\n";
verilog "\treg prescaler_out_50;\n";
vhdl    "\tsignal duty_correction  : std_logic;\n";
verilog "\treg duty_correction;\n";
comment "\t definitions for recursive controller design\n";
for (my $s = 1; $s <= $stage + 1; $s++) {
    vhdl    "\tconstant n$s             : natural  := $n_array[$s];\t-- prescaler \#$s divides by n$s or n$s + 1\n";
    vhdl    "\tconstant m$s             : positive := $m_array[$s];\t-- determines output duty cycle for prescaler \#$s\n";
    verilog "\tparameter n$s = $n_array[$s];\t// prescaler \#$s divides by n$s or n$s + 1\n";
    verilog "\tparameter m$s = $m_array[$s];\t// determines output duty cycle for prescaler \#$s\n";
}
for (my $s = 1; $s <= $stage + 1; $s++) {
    vhdl    "\tsignal stage$s\_count     : integer range 0 to n$s;\n";
    verilog "\treg [" . (log2($n_array[$s]) - 1) . ":0] stage$s\_count;\n";
}
for (my $s = 1; $s <= $stage + 1; $s++) {
    vhdl    "\tsignal stage$s\_out       : std_logic;\n";
    verilog "\treg stage$s\_out;\n";
}
for (my $s = 1; $s <= $stage; $s++) {
    vhdl    "\tsignal stage$s\_carry     : std_logic;\n";
    verilog "\treg stage$s\_carry;\n";
}

vhdl    "\n";
verilog "\n";
comment "\t definitions for phase accumulator design\n";
vhdl    "\tconstant num_bits       : positive := $num_bits;\t-- size of phase accumulator\n";
verilog "\tparameter num_bits = $num_bits;\t// size of phase accumulator\n";
if (($c >= (2 ** 31)) or $std_logic_arith or $std_logic_unsigned) {
    # avoid overflowing integers in VHDL
    vhdl "\t--constant c            : unsigned(num_bits - 1 downto 0) := to_unsigned($c, num_bits);\n";
    vhdl "\tconstant c              : " . unsigned . "(num_bits - 1 downto 0) := \"";
    # This should be recoded using unpack() ???
    for (my $ctemp = $c, my $bit = $num_bits - 1; $bit >= 0; $bit--) {
        if ($ctemp >= 2 ** $bit) {
            $ctemp -= 2 ** $bit;
            vhdl "1";
        }
        else {
            vhdl "0";
        }
    }
    vhdl "\";\n";
}
else {
    vhdl "\tconstant c              : unsigned(num_bits - 1 downto 0) := to_unsigned($c, num_bits);\n";
}
verilog "\tparameter c = $num_bits\'d$c;\n";
vhdl    "\tsignal phase            : " . unsigned . "(num_bits downto 0);\t-- MSB is carry output from adder\n";
verilog "\treg [$num_bits:0] phase;\t// MSB is carry output from adder\n";
vhdl    "\n";
verilog "\n";

if ($gen_50_percent_output) {
    vhdl "\t-- definitions for phase accumulator design with improved duty cycle\n";
    vhdl "\tsignal carry            : std_logic;\n";
    vhdl "\tsignal d_carry          : std_logic;\n";
    vhdl "\tsignal late             : std_logic;\n";
    vhdl "\tsignal msb              : std_logic;\n";
    vhdl "\tsignal d_msb_1          : std_logic;\n";
    vhdl "\tsignal d_msb_2_neg      : std_logic;\n";
    vhdl "\tsignal phase_diff       : " . unsigned . "(num_bits downto 0);\n";
    vhdl "\n";
}


# begin architecture
vhdl "begin -- $architecture_name\n";
vhdl "\n";

# write standard phase accumulator process
comment_line;
comment " Standard Phase accumulator.\n";
comment " Adds c to phase each clock.\n";
comment " phase(num_bits) is actually the registered carry output.\n";
comment_line;

if ($gen_50_percent_output) {
    # this process does the normal case only.
    # Duty cycle improvement is done in another process
    vhdl "gen_phase_accumulator : if use_phase_accumulator and not improve_duty_cycle generate\n";
}
else {
    # this one process handles both cases
    vhdl "gen_phase_accumulator : if use_phase_accumulator generate\n";
}

vhdl "\tphase_accumulator : process (async_reset, clock)\n";
vhdl "\tbegin\n";
vhdl "\t\tif (async_reset = '1') then\n";
vhdl "\t\t\tphase <= (others => '0');\n";
vhdl "--" if (not $gen_50_percent_output);
vhdl "\t\t\toutput_50 <= '0';\n";
vhdl "\t\telsif (rising_edge(clock)) then\n";
vhdl "\t\t\tif (clock_enable = '1') then\n";
#vhdl "\t\t\t\t-- manage counter\n";
vhdl "\t\t\t\tphase <= ('0' & phase(num_bits - 1 downto 0)) + ('0' & c);\n";
#vhdl "\t\t\t\t-- decode counter\n";
vhdl "--" if (not $gen_50_percent_output);
vhdl "\t\t\t\toutput_50 <= phase(num_bits - 1);\n";
vhdl "\t\t\tend if;\n";
vhdl "\t\tend if;\n";
vhdl "\tend process phase_accumulator;\n";
vhdl "\n";
vhdl "\toutput_pulse <= '1';\t-- special hack for this ratio\n--" if ($c > ((2 ** $num_bits) - 1));
vhdl "\toutput_pulse <= phase(num_bits);\n";
vhdl "\n";
vhdl "end generate gen_phase_accumulator;\n";
vhdl "\n";
verilog "/** this section not yet implemented in the Verilog version */\n\n";

if ($gen_50_percent_output) {
    # write improved duty cycle phase accumulator process
    comment_line;
    comment " Phase accumulator with lower jitter (on output_50) and improved duty cycle.\n";
    #comment " Adds c to phase each clock.\n";
    #comment " phase(num_bits) is actually the registered carry output.\n";
    comment_line;
    vhdl "gen_other_phase_accumulator : if use_phase_accumulator and improve_duty_cycle generate\n";
    vhdl "\tphase_accumulator : process (async_reset, clock)\n";
    vhdl "\t\tvariable new_phase : " . unsigned . "(num_bits - 1 downto 0);\n";
    vhdl "\tbegin\n";
    vhdl "\t\tif (async_reset = '1') then\n";
    vhdl "\t\t\tphase <= (others => '0');\n";
    vhdl "\t\t\toutput_pulse <= '0';\n";
    vhdl "\t\t\tcarry <= '0';\n";
    vhdl "\t\t\td_carry <= '0';\n";
    vhdl "\t\t\tlate <= '0';\n";
    vhdl "\t\t\tmsb <= '0';\n";
    vhdl "\t\t\td_msb_1 <= '0';\n";
    vhdl "\t\telsif (rising_edge(clock)) then\n";
    vhdl "\t\t\tif (clock_enable = '1') then\n";
    #vhdl "\t\t\t\t-- manage counter\n";
    vhdl "\t\t\t\tnew_phase := ('0' & phase(num_bits - 2 downto 0)) + c;\n";
    vhdl "\t\t\t\tphase(num_bits - 2 downto 0) <= new_phase(num_bits - 2 downto 0);\n";
    vhdl "\t\t\t\tcarry <= new_phase(num_bits - 1);\n";
    vhdl "\t\t\t\tif (carry = '1') then\n";
    vhdl "\t\t\t\t\tmsb <= not msb;\t-- toggle msb\n";
    vhdl "\t\t\t\tend if;\n";
    vhdl "\t\t\t\toutput_pulse <= msb and carry;\n";
    #vhdl "\t\t\t\t-- decode counter\n";
    vhdl "\t\t\t\td_carry <= carry;\n";
    vhdl "\t\t\t\td_msb_1 <= msb and not (d_carry and late);\n";
    vhdl "\t\t\t\tif (carry = '1') then\n";
    vhdl "\t\t\t\t\tlate <= phase_diff(num_bits);\n";
    vhdl "\t\t\t\tend if;\n";
    vhdl "\t\t\tend if;\n";
    vhdl "\t\tend if;\n";
    vhdl "\tend process phase_accumulator;\n";
    vhdl "\n";
    vhdl "\tphase_diff <= (phase(num_bits - 2 downto 0) & '0') - ('0' & c);\n";
    vhdl "\n";
    vhdl "\toutput_50 <= d_msb_1 or d_msb_2_neg;\n";
    vhdl "\n";
    vhdl "\tneg_edge : process (async_reset, clock)\n";
    vhdl "\tbegin\n";
    vhdl "\t\tif (async_reset = '1') then\n";
    vhdl "\t\t\td_msb_2_neg <= '0';\n";
    vhdl "\t\telsif (falling_edge(clock)) then\n";
    vhdl "\t\t\tif (clock_enable = '1') then\n";
    vhdl "\t\t\t\td_msb_2_neg <= msb xor (d_carry and not (not late and not msb));\n";
    vhdl "\t\t\tend if;\n";
    vhdl "\t\tend if;\n";
    vhdl "\tend process neg_edge;\n";
    vhdl "\n";
    vhdl "\tassert c(num_bits - 1) = '0' severity failure; \n";
    vhdl "\n";
    vhdl "end generate gen_other_phase_accumulator;\n";
    vhdl "\n";
}
verilog "/** this section not yet implemented in the Verilog version */\n\n";

# write prescaler process
comment_line;
comment " Prescaler.  Divides by either $n or " . ($n+1) . "\n";
comment " depending on whether the signal \"modulus_control\" is '0' or '1'.\n";
comment " Note: the \"terminal count\" is fixed, and the load value is\n";
comment " varied, to give smaller, faster logic (?)\n";
comment_line;
vhdl "gen_prescaler : if not use_phase_accumulator generate\n";
vhdl "\tprescaler : process (async_reset, clock)\n";
vhdl "\tbegin\n";
vhdl "\t\tif (async_reset = '1') then\n";
vhdl "\t\t\tprescaler_count  <= 0;\n";
vhdl "\t\t\tprescaler_out    <= '0';\n" if ($n > 1);
#vhdl "--" if (not $gen_50_percent_output);
vhdl "\t\t\tprescaler_out_50 <= '0';\n";
vhdl "\t\telsif (rising_edge(clock)) then\n";
vhdl "\t\t\tif (clock_enable = '1') then\n";
vhdl "\t\t\t\t-- manage counter\n";
vhdl "\t\t\t\tif (prescaler_count < n) then\n";
vhdl "\t\t\t\t\tprescaler_count <= prescaler_count + 1;\n";
vhdl "\t\t\t\telse\n";
vhdl "\t\t\t\t\tif (modulus_control = '0') then\n";
vhdl "\t\t\t\t\t\tprescaler_count <= 1;\n";
vhdl "\t\t\t\t\telse\n";
vhdl "\t\t\t\t\t\tprescaler_count <= 0;\n";
vhdl "\t\t\t\t\tend if;\n";
vhdl "\t\t\t\tend if;\n";
if ($n > 1) {
    # only need to decode if there are more than 2 states (i.e. > 1 ff)
    vhdl "\t\t\t\t-- decode counter\n";
    vhdl "\t\t\t\tif (prescaler_count < n) then\n";
    vhdl "\t\t\t\t\tprescaler_out <= '0';\n";
    vhdl "\t\t\t\telse\n";
    vhdl "\t\t\t\t\tprescaler_out <= '1';\n";
    vhdl "\t\t\t\tend if;\n";
}
vhdl "\t\t\t\tif (prescaler_count <= n/2) then\n";
#vhdl "--" if (not $gen_50_percent_output);
vhdl "\t\t\t\t\tprescaler_out_50 <= '0';\n";
vhdl "\t\t\t\telse\n";
#vhdl "--" if (not $gen_50_percent_output);
vhdl "\t\t\t\t\tprescaler_out_50 <= '1';\n";
vhdl "\t\t\t\tend if;\n";
vhdl "\t\t\tend if;\n";
vhdl "\t\tend if;\n";
vhdl "\tend process prescaler;\n";
vhdl "\n";
if ($n <= 1) {
    vhdl "\tprescaler_out <= '0' when prescaler_count = 0 else '1';\n";
}
vhdl "\toutput_pulse <= prescaler_out;\n";
vhdl "\n";
vhdl "end generate gen_prescaler;\n";
vhdl "\n";


verilog "\talways @(posedge async_reset or posedge clock ) begin : prescaler\n";
verilog "\t\tif (async_reset)\n";
verilog "\t\t\tbegin\n";
verilog "\t\t\t\tprescaler_count  <= 0;\n";
verilog "\t\t\t\tprescaler_out    <= 0;\n" if ($n > 1);
#verilog "//" if (not $gen_50_percent_output);
verilog "\t\t\t\tprescaler_out_50 <= 0;\n";
verilog "\t\t\tend\n";
verilog "\t\telse\n";
verilog "\t\t\tbegin\n";
verilog "\t\t\t\tif (clock_enable)\n";
verilog "\t\t\t\t\tbegin\n";
verilog "\t\t\t\t\t\t// manage counter\n";
verilog "\t\t\t\t\t\tif (prescaler_count < n)\n";
#verilog "\t\t\t\t\t\t\tbegin\n";
verilog "\t\t\t\t\t\t\tprescaler_count <= prescaler_count + 1;\n";
#verilog "\t\t\t\t\t\t\tend\n";
verilog "\t\t\t\t\t\telse\n";
#verilog "\t\t\t\t\t\t\tbegin\n";
verilog "\t\t\t\t\t\t\tprescaler_count <= modulus_control ? 0 : 1;\n";
#verilog "\t\t\t\t\t\t\t\tif (!modulus_control)\n";
#verilog "\t\t\t\t\t\t\t\t\tbegin\n";
#verilog "\t\t\t\t\t\t\t\t\t\tprescaler_count <= 1;\n";
#verilog "\t\t\t\t\t\t\t\t\tend\n";
#verilog "\t\t\t\t\t\t\t\telse\n";
#verilog "\t\t\t\t\t\t\t\t\tbegin\n";
#verilog "\t\t\t\t\t\t\t\t\t\tprescaler_count <= 0;\n";
#verilog "\t\t\t\t\t\t\t\t\tend\n";
#verilog "\t\t\t\t\t\t\t\tend\n";
if ($n > 1) {
    # only need to decode if there are more than 2 states (i.e. > 1 ff)
    verilog "\t\t\t\t\t\t// decode counter\n";
    verilog "\t\t\t\t\t\tprescaler_out <= (prescaler_count < n) ? 0 : 1;\n";
    #verilog "\t\t\t\t\t\tif (prescaler_count < n) begin\n";
    #verilog "\t\t\t\t\t\t\tprescaler_out <= 0;\n";
    #verilog "\t\t\t\t\t\tend else begin\n";
    #verilog "\t\t\t\t\t\t\tprescaler_out <= 1;\n";
    #verilog "\t\t\t\t\t\tend\n";
}
verilog "\t\t\t\t\t\t// make 50% duty cycle output\n";
verilog "\t\t\t\t\t\tprescaler_out_50 <= (prescaler_count <= n/2) ? 0 : 1;\n";
#verilog "\t\t\t\t\t\tif (prescaler_count <= n/2) begin\n";
##verilog "//" if (not $gen_50_percent_output);
#verilog "\t\t\t\t\t\t\tprescaler_out_50 <= 0;\n";
#verilog "\t\t\t\t\t\tend else begin\n";
##verilog "//" if (not $gen_50_percent_output);
#verilog "\t\t\t\t\t\t\tprescaler_out_50 <= 1;\n";
#verilog "\t\t\t\t\t\tend\n";
verilog "\t\t\t\t\tend\n";
verilog "\t\t\tend\n";
verilog "\t\tend\n";
verilog "\n";
if ($n <= 1) {
    verilog "\tassign prescaler_out = (prescaler_count ? 1 : 0);\n";
}
verilog "\tassign output_pulse = prescaler_out;\n";
verilog "\n";

if ($gen_50_percent_output) {
    # write duty cycle correction process
    comment_line;
    comment " Duty cycle improvement using falling edge flip flop.\n";
    comment_line;
    vhdl "duty_cycle_improver : if improve_duty_cycle and not use_phase_accumulator generate\n";
    vhdl "\timprover : process (async_reset, clock)\n";
    vhdl "\tbegin\n";
    vhdl "\t\tif (async_reset = '1') then\n";
    vhdl "\t\t\tduty_correction <= '0';\n";
    vhdl "\t\telsif (falling_edge(clock)) then\n";
    vhdl "\t\t\tif (clock_enable = '1') then\n";
    vhdl "\t\t\t\tduty_correction <= prescaler_out_50 or modulus_control;\n" if (($n & 1) == 1);
    vhdl "\t\t\t\tduty_correction <= prescaler_out_50 and modulus_control;\n" if (($n & 1) == 0);
    vhdl "\t\t\tend if;\n";
    vhdl "\t\tend if;\n";
    vhdl "\tend process improver;\n";
    vhdl "\n";
    vhdl "\toutput_50 <= duty_correction and prescaler_out_50;\n" if (($n & 1) == 1);
    vhdl "\toutput_50 <= duty_correction or prescaler_out_50;\n" if (($n & 1) == 0);
    vhdl "\n";
    vhdl "end generate duty_cycle_improver;\n";
    vhdl "\n";
    vhdl "no_duty_cycle_improver : if not improve_duty_cycle and not use_phase_accumulator generate\n";
    vhdl "\toutput_50 <= prescaler_out_50;\n";
    vhdl "end generate no_duty_cycle_improver;\n";
    vhdl "\n";
    verilog "/** this section not yet implemented in the Verilog version */\n\n";
    verilog "\n";
    verilog "\tassign output_50 = prescaler_out_50;\n";
    verilog "\n";
}

# write controller process
comment_line;
comment " Controller.\n";
comment " Wobbles the signal \"modulus_control\" to cause the prescaler\n";
comment " to divide by the correct ratio (in the long term).\n";
comment " Modulus_control must be '0' for $a counts of prescaler_out,\n";
comment " and '1' for $b counts (out of a total of " . ($a + $b) . " counts).\n";
comment " The simple way to do this is to just have modulus_control '0' for\n";
comment " all $a counts, then '1' for $b counts, but this may result in severe jitter.\n";
comment " The jitter can be reduced (at some hardware cost) by interleaving\n";
comment " the '0' and '1' counts.\n";
comment " This behaviour can be controlled by the generic parameter \"minimum_jitter\".\n";
comment " Note that there are many hardware / jitter tradeoffs.\n";
comment " Best results may require human intervention!\n";
comment_line;
# high jitter controller
vhdl "high_jitter_controller : if not minimum_jitter and not use_phase_accumulator and not use_recursive_controller generate\n";
vhdl "\tcontroller : process (async_reset, clock)\n";
vhdl "\tbegin\n";
vhdl "\t\tif (async_reset = '1') then\n";
vhdl "\t\t\tmodulus_control <= '0';\n";
vhdl "\t\t\tcontroller_count <= 0;\n";
vhdl "\t\telsif (rising_edge(clock)) then\n";
vhdl "\t\t\tif (clock_enable = '1') then\n";
vhdl "\t\t\t\tif (prescaler_out = '1') then\n";
vhdl "\t\t\t\t\t-- manage counter\n";
vhdl "\t\t\t\t\tif (controller_count < a + b - 1) then\n";
vhdl "\t\t\t\t\t\tcontroller_count <= controller_count + 1;\n";
vhdl "\t\t\t\t\telse\n";
vhdl "\t\t\t\t\t\tcontroller_count <= 0;\n";
vhdl "\t\t\t\t\tend if;\n";
vhdl "\t\t\t\t\t-- decode counter\n";
vhdl "\t\t\t\t\tif (controller_count < a) then\n";
vhdl "\t\t\t\t\t\tmodulus_control <= '0';\n";
vhdl "\t\t\t\t\telse\n";
vhdl "\t\t\t\t\t\tmodulus_control <= '1';\n";
vhdl "\t\t\t\t\tend if;\n";
vhdl "\t\t\t\tend if;\n";
vhdl "\t\t\tend if;\n";
vhdl "\t\tend if;\n";
vhdl "\tend process controller;\n";
vhdl "end generate high_jitter_controller;\n";
vhdl "\n";

if ( $low_jitter_controller ) {
    # low jitter controller
    vhdl "low_jitter_controller : if minimum_jitter and not use_phase_accumulator and not use_recursive_controller generate\n";
    vhdl "\tcontroller : process (async_reset, clock)\n";
    vhdl "\tbegin\n";
    vhdl "\t\tif (async_reset = '1') then\n";
    my $odd_one_out = (($a < $b) or ($b == 0)) ? 1 : 0;
    #$odd_one_out = 1;   # some chips might have problem with async sets
    vhdl "\t\t\tmodulus_control <= " . ($odd_one_out ? "'0'" : "'1'") . ";\n";
    vhdl "\t\t\tcontroller_count <= 0;\n";
    vhdl "\t\telsif (rising_edge(clock)) then\n";
    vhdl "\t\t\tif (clock_enable = '1') then\n";
    vhdl "\t\t\t\tif (prescaler_out = '1') then\n";
    vhdl "\t\t\t\t\t-- manage counter\n";
    vhdl "\t\t\t\t\tif (controller_count < a + b - 1) then\n";
    vhdl "\t\t\t\t\t\tcontroller_count <= controller_count + 1;\n";
    vhdl "\t\t\t\t\telse\n";
    vhdl "\t\t\t\t\t\tcontroller_count <= 0;\n";
    vhdl "\t\t\t\t\tend if;\n";
    vhdl "\t\t\t\t\t-- decode counter\n";
    vhdl "\t\t\t\t\tif (controller_count <= a + b - 1) then\n";
    vhdl "\t\t\t\t\t\tcase controller_count is\n";
    if (($a + $b) > 1) {
        vhdl "\t\t\t\t\t\t\twhen ";

        my $num_printed = 0;
        my $need_separator = 0;
        for (my $index = 0; $index < $a + $b; $index++)
        {
            if ((substr $controller_table, $index, 1) == $odd_one_out) {
                if ($num_printed > 7) {
                    # wrap long lines
                    vhdl " => modulus_control <= " . ($odd_one_out ? "'0'" : "'1'") . ";\n";
                    vhdl "\t\t\t\t\t\t\twhen ";
                    $num_printed = 0;
                    $need_separator = 0;
                }
                vhdl (($need_separator ? "\|" : "") . $index);
                $num_printed++;
                $need_separator = 1;
            }
        }

        vhdl " => modulus_control <= " . ($odd_one_out ? "'0'" : "'1'") . ";\n";
    }
    vhdl "\t\t\t\t\t\t\twhen others => modulus_control <= " . (($odd_one_out xor ($b == 0)) ? "'1'" : "'0'") . ";\n";
    vhdl "\t\t\t\t\t\tend case;\n";
    vhdl "\t\t\t\t\telse\n";
    vhdl "\t\t\t\t\t\tmodulus_control <= '-';\t-- allow logic reductions (?)\n";
    vhdl "\t\t\t\t\tend if;\n";
    vhdl "\t\t\t\tend if;\n";
    vhdl "\t\t\tend if;\n";
    vhdl "\t\tend if;\n";
    vhdl "\tend process controller;\n";
    vhdl "end generate low_jitter_controller;\n";
    vhdl "\n";
}
else {
    vhdl "assert not minimum_jitter or use_recursive_controller or use_phase_accumulator\n";
    vhdl "\treport \"Minimum jitter controller not available, as $0 was run with -g option\"\n";
    vhdl "\tseverity failure;\n";
    vhdl "\n";
}
verilog "/** this section not yet implemented in the Verilog version */\n\n";

# recursive controller
comment_line;
comment " recursive controller\n";
comment " The modulus control signal for the prescaler can be generated by another\n";
comment " fractional-N divider, which in turn can have its modulus control signal\n";
comment " generated by yet another fractional-N divider, and so on.\n";
comment " We stop when we don't need another fractional-N divider, and can just use\n";
comment " a fixed divider.\n";
comment " The particular arrangement we use also produces the smallest possible jitter.\n";
comment " The stageN_count and stageN_out signals have been initialised to non-zero\n";
comment " values to improve the jitter measurements during simulation.  This is not\n";
comment " needed for synthesis, and these values should be set to zero if this\n";
comment " improves synthesis results.\n";
comment " Recursive controller design information (for debugging):\n";
do {
    my $old_tabstop = $tabstop;
    $tabstop = 12;
    for (my $s = 0; $s <= $stage + 1; $s++) {
        comment " " x ($tabstop - 2) . "n$s=$n_array[$s]\tm$s=$m_array[$s]\ta$s=$a_array[$s]\tb$s=$b_array[$s]\ti$s=$i_array[$s]\n";
    }
    $tabstop = $old_tabstop;
};
comment_line;
vhdl "recursive_controller : if not use_phase_accumulator and use_recursive_controller generate\n";
vhdl "\tcontroller : process (async_reset, clock)\n";
vhdl "\tbegin\n";
vhdl "\t\tif (async_reset = '1') then\n";
for (my $s = 1; $s <= $stage + 1; $s++) {
#   comment "\t\t\tstage$s\_count <= 0;\n";
    vhdl "\t\t\tstage$s\_count <= " . ($n_array[$s]) . ";\n";
}
for (my $s = 1; $s <= $stage + 1; $s++) {
#   vhdl "\t\t\tstage$s\_out <= '0';\n";
    vhdl "\t\t\tstage$s\_out <= " . ($i_array[$s] ? "'1'" : "'0'") . ";\n";
}
for (my $s = 1; $s <= $stage; $s++) {
    vhdl "\t\t\tstage$s\_carry <= '0';\n";
}
vhdl "\t\telsif (rising_edge(clock)) then\n";
vhdl "\t\t\tif (clock_enable = '1') then\n";
for (my $s = 1; $s <= $stage + 1; $s++) {
    vhdl "\t\t\t\t-- Stage $s  stage$s\_out is low for " . ($a_array[$s - 1]) . " cycles, and high for " . ($b_array[$s - 1]) . " cycles.\n";
    vhdl "\t\t\t\t-- n$s=$n_array[$s] m$s=$m_array[$s] a$s=$a_array[$s] b$s=$b_array[$s] i$s=$i_array[$s]\n";
    vhdl "\t\t\t\tif (" . ($s > 1 ? ("stage" . ($s - 1) . "_carry") : "prescaler_out" ) . " = '1') then\n";
    vhdl "\t\t\t\t\tif (stage$s\_count < n$s) then\n";
    vhdl "\t\t\t\t\t\tstage$s\_count <= stage$s\_count + 1;\n";
    vhdl "\t\t\t\t\t\tstage$s\_carry <= '0';\n" if ($s <= $stage);
    vhdl "\t\t\t\t\telse\n";
    if ($s <= $stage) {
        vhdl "\t\t\t\t\t\tif (stage" . ($s + 1) . "_out = '0') then\n";
        vhdl "\t\t\t\t\t\t\tstage$s\_count <= 1;\n";
        vhdl "\t\t\t\t\t\telse\n";
        vhdl "\t\t\t\t\t\t\tstage$s\_count <= 0;\n";
        vhdl "\t\t\t\t\t\tend if;\n";
    }
    else {
        vhdl "\t\t\t\t\t\tstage$s\_count <= 0;\n";
    }
    vhdl "\t\t\t\t\t\tstage$s\_carry <= '1';\n" if ($s <= $stage);
    vhdl "\t\t\t\t\tend if;\n";
    vhdl "\t\t\t\t\tif (stage$s\_count < m$s) then\n";
    vhdl "\t\t\t\t\t\tstage$s\_out <= " . ($i_array[$s] ? "'1'" : "'0'") . ";\n";
    vhdl "\t\t\t\t\telse\n";
    vhdl "\t\t\t\t\t\tstage$s\_out <= " . ($i_array[$s] ? "'0'" : "'1'") . ";\n";
    vhdl "\t\t\t\t\tend if;\n";
    vhdl "\t\t\t\telse\n" if ($s <= $stage);
    vhdl "\t\t\t\t\tstage$s\_carry <= '0';\n" if ($s <= $stage);
    vhdl "\t\t\t\tend if;\n";
}
vhdl "\t\t\tend if;\n";
vhdl "\t\tend if;\n";
vhdl "\tend process controller;\n";
vhdl "\n";
vhdl "\tmodulus_control <= stage1_out;\n";
vhdl "\n";
vhdl "end generate recursive_controller;\n";
vhdl "\n";

verilog "\talways @(posedge async_reset or posedge clock ) begin : recursive_controller\n";
verilog "\t\tif (async_reset)\n";
verilog "\t\t\tbegin\n";
for (my $s = 1; $s <= $stage + 1; $s++) {
#   verilog "\t\t\t\tstage$s\_count <= 0;\n";
    verilog "\t\t\t\tstage$s\_count <= " . ($n_array[$s]) . ";\n";
}
for (my $s = 1; $s <= $stage + 1; $s++) {
#   verilog "\t\t\t\tstage$s\_out <= 0;\n";
    verilog "\t\t\t\tstage$s\_out <= " . ($i_array[$s] ? "1" : "0") . ";\n";
}
for (my $s = 1; $s <= $stage; $s++) {
    verilog "\t\t\t\tstage$s\_carry <= 0;\n";
}
verilog "\t\t\tend\n";
verilog "\t\telse\n";
verilog "\t\t\tbegin\n";
verilog "\t\t\t\tif (clock_enable)\n";
verilog "\t\t\t\t\tbegin\n";
for (my $s = 1; $s <= $stage + 1; $s++) {
    verilog "\t\t\t\t\t\t// Stage $s  stage$s\_out is low for " . ($a_array[$s - 1]) . " cycles, and high for " . ($b_array[$s - 1]) . " cycles.\n";
    verilog "\t\t\t\t\t\t// n$s=$n_array[$s] m$s=$m_array[$s] a$s=$a_array[$s] b$s=$b_array[$s] i$s=$i_array[$s]\n";
    verilog "\t\t\t\t\t\tif (" . ($s > 1 ? ("stage" . ($s - 1) . "_carry") : "prescaler_out" ) . ") begin\n";
    verilog "\t\t\t\t\t\t\tif (stage$s\_count < n$s) begin\n";
    verilog "\t\t\t\t\t\t\t\tstage$s\_count <= stage$s\_count + 1;\n";
    verilog "\t\t\t\t\t\t\t\tstage$s\_carry <= 0;\n" if ($s <= $stage);
    verilog "\t\t\t\t\t\t\tend else begin\n";
    if ($s <= $stage) {
        verilog "\t\t\t\t\t\t\t\tif (!stage" . ($s + 1) . "_out) begin\n";
        verilog "\t\t\t\t\t\t\t\t\tstage$s\_count <= 1;\n";
        verilog "\t\t\t\t\t\t\t\tend else begin\n";
        verilog "\t\t\t\t\t\t\t\t\tstage$s\_count <= 0;\n";
        verilog "\t\t\t\t\t\t\t\tend\n";
    }
    else {
        verilog "\t\t\t\t\t\t\t\tstage$s\_count <= 0;\n";
    }
    verilog "\t\t\t\t\t\t\t\tstage$s\_carry <= 1;\n" if ($s <= $stage);
    verilog "\t\t\t\t\t\t\tend\n";
    verilog "\t\t\t\t\t\t\tif (stage$s\_count < m$s) begin\n";
    verilog "\t\t\t\t\t\t\t\tstage$s\_out <= " . ($i_array[$s] ? "1" : "0") . ";\n";
    verilog "\t\t\t\t\t\t\tend else begin\n";
    verilog "\t\t\t\t\t\t\t\tstage$s\_out <= " . ($i_array[$s] ? "0" : "1") . ";\n";
    verilog "\t\t\t\t\t\t\tend\n";
    verilog "\t\t\t\t\t\tend else begin\n" if ($s <= $stage);
    verilog "\t\t\t\t\t\t\tstage$s\_carry <= 0;\n" if ($s <= $stage);
    verilog "\t\t\t\t\t\tend\n";
}
verilog "\t\t\t\t\tend\n";
verilog "\t\t\t\tend\n";
verilog "\t\t\tend\n";
verilog "\n";
verilog "\tassign modulus_control = stage1_out;\n";
verilog "\n";


vhdl "end $architecture_name;\n";

verilog "endmodule\n";

# write file footer
comment_line;
vhdl    "-- <EOF> $vhdl_name\n";
verilog "// <EOF> $verilog_name\n";
comment_line;

#vhdl "deliberate syntax error to test the regression test script\n";

print "closing $vhdl_name\n" if ($verbose);
close VHDL;
print "closing $verilog_name\n" if ($verbose);
close VERILOG;
