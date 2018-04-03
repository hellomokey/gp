#!perl -w

use strict;
use warnings;

use Opcode qw(opset opset_to_ops opdesc);

my $plperl_opmask_h   = shift
	or die "Usage: $0 <output_filename.h>\n";

my $plperl_opmask_tmp = $plperl_opmask_h."tmp";
END { unlink $plperl_opmask_tmp }

open my $fh, ">", "$plperl_opmask_tmp"
	or die "Could not write to $plperl_opmask_tmp: $!";

printf $fh "#define PLPERL_SET_OPMASK(opmask) \\\n";
printf $fh "  memset(opmask, 1, MAXO);\t/* disable all */ \\\n";
printf $fh "  /* then allow some... */                       \\\n";

my @allowed_ops = (
	# basic set of opcodes
	qw[:default :base_math !:base_io sort time],
	# require is safe because we redirect the opcode
	# entereval is safe as the opmask is now permanently set
	# caller is safe because the entire interpreter is locked down
	qw[require entereval caller],
	# These are needed for utf8_heavy.pl:
	# dofile is safe because we redirect the opcode like require above
	# print is safe because the only writable filehandles are STDOUT & STDERR
	# prtf (printf) is safe as it's the same as print + sprintf
	qw[dofile print prtf],
	# Disallow these opcodes that are in the :base_orig optag
	# (included in :default) but aren't considered sufficiently safe
	qw[!dbmopen !setpgrp !setpriority],
	# custom is not deemed a likely security risk as it can't be generated from
	# perl so would only be seen if the DBA had chosen to load a module that
	# used it. Even then it's unlikely to be seen because it's typically
	# generated by compiler plugins that operate after PL_op_mask checks.
	# But we err on the side of caution and disable it
	qw[!custom],
);

printf $fh "  /* ALLOWED: @allowed_ops */ \\\n";

foreach my $opname (opset_to_ops(opset(@allowed_ops))) {
	printf $fh qq{  opmask[OP_%-12s] = 0;\t/* %s */ \\\n},
		uc($opname), opdesc($opname);
}
printf $fh "  /* end */ \n";

close $fh
	or die "Error closing $plperl_opmask_tmp: $!";

rename $plperl_opmask_tmp, $plperl_opmask_h
	or die "Error renaming $plperl_opmask_tmp to $plperl_opmask_h: $!";

exit 0;
