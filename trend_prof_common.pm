#
# see License.txt for copyright and terms of use
#

# Some library functions that the different steps share.

# these are some functions that several make_* use

######################################################################
# thanks to http://support.internetconnection.net/CODE_LIBRARY/Perl_URL_Encode_and_Decode.shtml
sub urlEncode {
    my ($str) = @_;
    $str =~ s/([^A-Za-z0-9\.\/])/sprintf("%%%02X", ord($1))/seg;
    return $str;
}
######################################################################
# thanks to http://support.internetconnection.net/CODE_LIBRARY/Perl_URL_Encode_and_Decode.shtml
sub urlDecode {
    my ($str) = @_;
    $str =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
    return $str;
}

######################################################################
sub textToEscapedHtml {
    my ($s) = @_;
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    $s =~ s/\"/&quot;/g;
    return $s;
}

######################################################################
sub demangleFilename {
    my ($filename) = @_;
    $filename =~ s,\#\#,/,g;
    $filename =~ s,\#,/,g;
    for (my $i=0; $i<10; ++$i) { 
        $filename =~ s,[^/]*//?\^,,; 
    }
    $filename =~ s,^.*/(.*/.*)$,$1,;
    return $filename;
}

######################################################################
sub trow {
    my ($s, $stuff) = @_;
    $s = defined($s) ? $s : '';
    $stuff = defined($stuff) ? $stuff : '';
    return "\n<tr $stuff>$s\n</tr>";
}

sub td {
    my ($s, $stuff) = @_;
    $s = defined($s) ? $s : '&nbsp;';
    $stuff = defined($stuff) ? $stuff : '';
    return "\n\t<td $stuff> $s </td>";
}

sub th {
    my ($s, $stuff) = @_;
    $s = defined($s) ? $s : '&nbsp;';
    $stuff = defined($stuff) ? $stuff : '';
    return "\n\t<th $stuff> $s </th>";
}

sub ahref {
    my ($url, $text, $stuff) = @_;
    $stuff = defined($stuff) ? $stuff : '';
    return qq{<a href="$url" $stuff>$text</a>};
}

#########################################################################
sub runOrDie {
    my ($cmd) = @_;
    my $res = system($cmd);
    die ("'$cmd': " . explainDeath($res) . "\n") unless (0 == $res);
}

#########################################################################
sub runOrWarn {
    my ($cmd) = @_;
    my $res = system($cmd);
    warn ("'$cmd': " . explainDeath($res) . "\n") unless (0 == $res);
}

#########################################################################
sub explainDeath {
    my $exitCode = shift @_;
    if ($exitCode == -1) {
        return "failed to execute: $!\n";
    } elsif ($exitCode & 127) {
        return sprintf("died with signal %d, %s coredump\n",
                       ($exitCode & 127),  ($exitCode & 128) ? 'with' : 'without');
    } else {
        return sprintf(" exited with value %d\n", $exitCode >> 8);
    }
}

######################################################################
sub findFilesMatching {
    my ($dir, $pattern, $visited) = @_;
    my @result;    
    if (!exists($visited->{$dir})) {
        $visited->{$dir} = 1;
        opendir(DIR, $dir) or die "$dir: $!";
        my @entries = readdir(DIR);
        closedir(DIR) or die "$!";
        foreach my $entry (@entries) {
            next if '.' eq $entry;
            next if '..' eq $entry;
            $entry = "$dir/$entry";
            if (-l $entry) {
                $entry = resolveLinkRelativeTo($entry, $dir);
            }
            next unless defined($entry);
            if (-f $entry && $entry =~ m/$pattern/x) {
                $entry =~ s,^\./,,;
                push(@result, $entry);
            } 
            elsif (-d $entry) {
                push(@result, findFilesMatching($entry, $pattern, $visited));
            }
        }
    }
    return @result;
}

######################################################################
sub resolveLinkRelativeTo {
    my ($link, $dir) = @_;
    my $tooManyLinks = 10;
    while (-l $link && $tooManyLinks-- > 0) {
        $link = readlink($link);
        if (defined($link) && $link !~ m,^/,) {
            $link = "$dir/$link";
        } 
    }
    return (-l $link) ? undef : $link;    
}

######################################################################
sub readSourceLinesFile {
    my ($lines, $file) = @_;
    die $file unless -r $file;
    open(SRC, '<', $file) or die "$file: $!";
    while (my $line = <SRC>) {
        if ($line =~ m(^\s*(\d+)\s*\:(.*)$)) {
            my $num = $1;
            my $code = $2;
            $lines->[$num] = $code;
        }
        else {
            die "Strange line in '$file' : '$line'";
        }
    }
    close(SRC) or die "$file: $!";
}

######################################################################
sub readSourceFile {
    my ($lines, $file) = @_;
    die $file unless -r $file;
    open(SRC, '<', $file) or die "$file: $!";
    my $num = 1;
    while (my $line = <SRC>) {
        chomp($line);
        $lines->[$num] = $line;
        $num++;
    }
    close(SRC) or die "$file: $!";
}

######################################################################
sub readWorkloadsFile {
    my ($indexToWorkload, $file) = @_;
    die $file unless -f $file;
    open(SIZES, '<', $file) or die "ERROR opening $file: $!";
    my @workloads;
    my $indexExists = 1;
    while(1) {
        my $line = <SIZES>;
        last unless defined $line;
        $line =~ s/^\s*\#.*$//;       # delete comment lines
        next if ($line =~ /^\s*$/);   # skip blank lines
        # look for the classname followed by colon
        if ($line =~ m/^\s*workload:/i) {
            my %record;
            while(1) {
                $line = <SIZES>;
                last unless defined $line;
                # we are done at a blank line; check for blank lines first as
                # comments do not break a paragraph
                last if $line =~ /^\s*$/;
                # skip comment lines
                next if $line =~ m/^\s*\#.*$/;
                # parse line
                die "ERROR illegal line:$line" unless $line =~m/^\s*([a-zA-Z0-9_]+)\s*=\s*(.*)$/;
                my ($fName, $fValue) = ($1, $2);
                $record{lc($fName)} = $fValue;
            }
            unless (exists($record{'size'}) && exists($record{'name'})) {
                my $ks = join(',', keys(%record));
                die "ERROR records in $file must have entries 'name' and 'size'.  Found instead ($ks)";
            }
            $indexExists = 0 unless exists($record{'index'});
            $record{'dir'} = mangleWorkloadName($record{'name'}) unless exists $record{'dir'};
            push(@workloads, \%record);
        } else {
            die "ERROR $file can only have 'workload:' as a class, but I read '$line'\n";
        }
    }
    close(SIZES) or die "closing $file: $!";
    if ($indexExists) {
        foreach $rec (@workloads) {
            $indexToWorkload->[$rec->{'index'}] = $rec;
        }
    } else {
        my $index = 0;
        foreach $rec (sort {$a->{'size'} <=> $b->{'size'}} @workloads) {
            $indexToWorkload->[$index] = $rec;
            $indexToWorkload->[$index]->{'index'} = $index;
            ++$index;
        }        
    }
    foreach my $rec (@$indexToWorkload) {
        $rec->{'filename'} = sprintf('%0.4d_%s.data', $rec->{'index'}, $rec->{'dir'});
    }
}

######################################################################
sub readSourcefileMap {
    my ($displaynameToGcno, $displaynameToSource, $file) = @_;
    open(SFM, '<', $file) or die "$file: $!";
    while(1) {
        my $line = <SFM>;
        last unless defined $line;
        $line =~ s/^\s*\#.*$//;       # delete comment lines
        next if ($line =~ /^\s*$/);   # skip blank lines
        # look for the classname followed by colon
        if ($line =~ m/^\s*sourcefile:/i) {
            my %record;
            while(1) {
                $line = <SFM>;
                last unless defined $line;
                # we are done at a blank line; check for blank lines first as
                # comments do not break a paragraph
                last if $line =~ /^\s*$/;
                # skip comment lines
                next if $line =~ m/^\s*\#.*$/;
                # parse line
                die "ERROR illegal line:$line" unless $line =~m/^\s*([a-zA-Z0-9_]+)\s*=\s*(.*)$/;
                my ($fName, $fValue) = ($1, $2);
                $record{lc($fName)} = $fValue;
            }
            unless (exists($record{'displayname'}) 
                && exists($record{'gcno'})
                && exists($record{'source'})) {
                my $ks = join(',', keys(%record));
                die "ERROR $file must have entries 'displayName', 'gcno', and 'source'.  Found instead ($ks).";
            }
            $displaynameToGcno->{$record{'displayname'}} = $record{'gcno'};
            $displaynameToSource->{$record{'displayname'}} = $record{'source'};
        } else {
            die "ERROR $file can only have 'sourcefile:' as a class, but I read '$line'\n";
        }
    }
    close(SFM) or die "$file: $!";
}

######################################################################
# input: a line of text from a .gcov file
# output: either the line number, { block number | undef}, count or undef
sub parseGcovDigestLine {
    my ($line) = @_;
    my $srcFile;
    my $lineNumber;
    my $block;
    my $count;
    chomp $line;
    if ($line =~ /^\s*(.*)\s+(\d+)\s+(\d+)?\s+(\d+)\s*$/) {
        $srcFile = $1;
        $lineNumber = $2;
        $block = $3;
        $count = $4;
        $block = '' if !defined($block);
    } else {
        die "ERROR: parseGcovDigestLine can't parse '$line'" if ($debugMode);
    }
    return ("$srcFile.$lineNumber.$block", $count);
}

######################################################################
# input: a line of text from a .gcov file
# output: either the line number, { block number | undef}, count or undef
sub parseGcovLine {
    my ($gcovline) = @_;
    my $lineNumber;
    my $block;
    my $count;
    chomp $gcovline;
    if ($gcovline=~ m/^\s*([^:\s]+)\s*:\s*(\d+)-block\s*(\d+)\s*$/) {
        # a basic block within a source line; ($lineNumber, $block, $count) are all defined
        $lineNumber = $2;
        $block = $3;
        $count = $1;
        $count = 0 if ($count =~ m/\#\#\#\#\#/ || $count =~ m/\$\$\$\$\$/);
        if (!defined($lineNumber) || !defined($block) || !defined($count) || '-' eq $count) {
            die "STRANGE ERROR parsing '$gcovline': lineNumber='$lineNumber' block='$block' count='$count'";
        }
    }            
    elsif ($gcovline=~ m/^\s*-\s*:\s*([^:\s]+)\s*:(.*)$/) {
        # a non-executable line according to gcov (the first field is a '-');
        # we leave ($lineNumber, $block, $count) undef
    }
    elsif ($gcovline=~ m/^\s*([^:\s]+)\s*:\s*([^:\s]+)\s*:(.*)$/) {
        # a source line; ($lineNumber, $count) are defined; $block is undef
        $lineNumber = $2;
        $count = $1;
        $count = 0 if ($count =~ m/\#\#\#\#\#/ || $count =~ m/\$\$\$\$\$/);
        if (!defined($lineNumber) || defined($block) || !defined($count) || '-' eq $count) {
            die "STRANGE ERROR parsing '$gcovline': lineNumber='$lineNumber' block='$block' count='$count'";
        }
    } else {
        # we couldn't parse the line
        warn "ERROR: Couldn't parse line '$gcovline'" if $debugMode;
    }
    return ($lineNumber, $block, $count)
}

######################################################################
# output of the fit script
sub parseFitLine {
    my ($fit, $fitLine, $debugMode) = @_;
    return unless defined($fitLine);
    $fitLine =~ s/^\s+//;
    $fitLine =~ s/\s+$//;
    my ($type, $n, $coef0, $coef1, $rsq, $mre, $umre, $avgssr, $uavgssr, $minLinX, $maxLinX, $sumLinY, $sx, $sy) 
        = split(/\t/, $fitLine);
    $fit->{'type'} = $type;
    $fit->{'n'} = $n;
    $fit->{'coef0'} = $coef0;
    $fit->{'coef1'} = $coef1;
    $fit->{'rsq'} = $rsq;
    $fit->{'mre'} = $mre;
    $fit->{'umre'} = $umre;
    $fit->{'avgssr'} = $avgssr;
    $fit->{'uavgssr'} = $uavgssr;
    $fit->{'minLinX'} = $minLinX;
    $fit->{'maxLinX'} = $maxLinX;
    $fit->{'sumLinY'} = $sumLinY;
    $fit->{'sx'} = $sx;
    $fit->{'sy'} = $sy;
    if ($debugMode) {
        die unless defined($fit->{'coef0'});
        die unless defined($fit->{'coef1'});
        die unless defined($fit->{'n'});
        die unless $fit->{'n'} > 0;
        die unless defined($fit->{'rsq'});
        die unless $fit->{'rsq'} + 0.000001 > 0.0;
        die unless $fit->{'rsq'} - 0.000001 < 1.0;
        die unless defined($fit->{'mre'});
        die unless $fit->{'mre'} + 0.000001 > 1.0;
    }
}


######################################################################
#output of the fit script
sub oldReadFit {
    my ($fit, $file, $debugMode) = @_;
    die $file unless -r $file;
    open(FIT, '<', $file) or die "$file: $!";
    my $line = <FIT>; #fit file is single line
    die "ERROR: empty fit file" unless defined $line;
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
    my ($type, $total, $n, $rsq, $mre, $avgssr, $coef0, $coef1, $inter1, $inter2, $inter3, $sx, $sy, $maxy, $linMre, $linSsr, $sumLinY) = split(/\t/, $line);
    $fit->{'type'} = $type;
    $fit->{'total'} = $total;
    $fit->{'n'} = $n;
    $fit->{'rsq'} = $rsq;
    $fit->{'mre'} = $mre;
    $fit->{'avgssr'} = $avgssr;
    $fit->{'coef0'} = $coef0;
    $fit->{'coef1'} = $coef1;
    $fit->{'inter1'} = $inter1;
    $fit->{'inter2'} = $inter2;
    $fit->{'inter3'} = $inter3;
    $fit->{'sx'} = $sx;
    $fit->{'sy'} = $sy;
    $fit->{'maxy'} = $maxy;
    $fit->{'linMre'} = $linMre;
    $fit->{'linSsr'} = $linSsr;
    $fit->{'sumLinY'} = $sumLinY;
    close(FIT) or die "$file: $!";
    if ($debugMode) {
        die $file unless defined($fit->{'coef0'}) && defined($fit->{'coef1'});
        die $file unless defined($fit->{'n'}) && ($fit->{'n'} > 0);
        die $file unless defined($fit->{'total'}) && ($fit->{'total'} >= $fit->{'n'});
        die $file unless defined($fit->{'mre'}) && ($fit->{'mre'} + 0.000001 > 1.0);
    }
}

######################################################################
# take a fit and make prediction for what happens at input size n
sub evalFitAt {
    my ($fit, $n) = @_;
    die unless exists($fit->{'type'});
    die unless exists($fit->{'coef0'});
    die unless exists($fit->{'coef1'});
    my $coef0 = $fit->{'coef0'};
    my $coef1 = $fit->{'coef1'};
    if ('powerlaw' eq $fit->{'type'}) {
        die unless $n > 0;
        return ($coef0 * exp($coef1 * log($n)));
    }
    elsif ('linear' eq $fit->{'type'}) {
        return ($coef0 + $coef1 * $n);
    }
    elsif ('exp' eq $fit->{'type'}) {
        return ($coef0 * exp($n * $coef1));
    }
    elsif ('log' eq $fit->{'type'}) {
        die unless $n > 0;
        return ($coef0 + $coef1 * log($n));
    }
    else {
        die "Unknown fit type $fit->{type}\n";
    }
}

######################################################################
sub readClusterFile {
    my ($loc2cluster, $cluster2locs, $clusterFile) = @_;
    open(CLUST, '<', $clusterFile) 
	or die "ERROR: can't open cluster file '$clusterFile': $!";
    my @c2ls;
    while (my $line = <CLUST>) {
        $line =~ s/[\s\n]+$//;
        next unless $line;
        next if $line =~ m/^\s*\(/;
	my @locs = split("\t", $line);
	push(@c2ls, \@locs);
    }
    close(CLUST) or die "ERROR: can't close cluster file '$clusterFile': $!";
    my @sorted = sort { $#{$b} <=> $#{$a} } @c2ls;
    for (my $clust=0; $clust <= $#sorted; ++$clust) {
	my $locs = $sorted[$clust];
	$cluster2locs->[$clust] = $locs;
	foreach my $loc (@$locs) {
	    $loc2cluster->{$loc} = $clust;
	}
    }
}

######################################################################
sub readResidualsFile  {
    my ($file, $resid) = @_;
    die $file unless -r $file;
    open(RESIDFILE, '<', $file) or die "ERROR opening residuals file $file: $!";
    my $i=0;
    while ( my $line = <RESIDFILE> )  {
        chomp $line;
        $line =~ s/^\s+//;
        next if $line =~ m/^\#/;
        my ($x, $r) = split(/\s+/, $line);
        $resid->[$i] = $r if defined($r);
        $i += 1;
    }
    close(RESIDFILE) or die "ERROR closing residuals file $file: $!";
}

######################################################################
sub mangleWorkloadName {
    my ($name) = @_;
    $name =~ s,[/\s\n\\\(\)\[\]\<\>\$\%\&\*\'\"\`\?\@],\#,g;
    return $name;
}
######################################################################
sub mangleSourceFileName {
    my ($name) = @_;
    $name =~ s,^0_config/,,;
    $name =~ s,//+,/,g;  # foo//bar => foo/bar
    $name =~ s,[\n\s\!\$\%\&\*\(\)\[\]\'\"\?\@\>\<],_,g;
    $name =~ s,^\./,,;   # ./foo => foo
    $name =~ s,/\./,/,g; # foo/./bar => foo/bar
    $name =~ s,[/\\:],\#,g;
    return $name;    
}

######################################################################
# turn a string into a float
# return undef if it's invalid
# stolen from the perl cookbook
sub strToFloat {
    use POSIX qw(strtod);
    my $str = shift;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    $! = 0;
    my ($num, $unparsed) = strtod($str);
    if (($str eq '') || ($unparsed != 0) || $!) {
        return;
    } else {
        return $num;
    }
}

######################################################################
# dsw: this is just 'mkdir -p'
sub mkdirAndParents {
  my ($file) = @_;
  my $oldPath="";
  my $path;
  for $f(split /\//, $file) {
    $path="${oldPath}${f}";
    next if $path eq "";        # skip blank paths
    next if -e $path;           # don't make extant things
    die "mkdir failed making '$path'" unless mkdir $path;
  } continue {
    $oldPath="${path}/";
  }
}


###########################################################################
sub fit {
    my ($type, $loc, $xs, $ys, $debugMode) = @_;
    my $eps = 0.000001;
    my $dologx;
    my $dology;
    if ('linear' eq $type)      { $dologx = 0; $dology = 0; }
    elsif ('powerlaw' eq $type) { $dologx = 1; $dology = 1; }
    elsif ('log' eq $type)      { $dologx = 1; $dology = 0; }
    elsif ('exp' eq $type)      { $dologx = 0; $dology = 1; }
    else { die "Unknown type: '$type'\n"; }
    my $n = 0;
    my $total = 0;
    my $sumLinY = 0.0;
    my $minLinX = 9e9;
    my $maxLinX = 0;
    my $sx = 0.0;
    my $sy = 0.0;
    my $sxx = 0.0;
    my $syy = 0.0;
    my $sxy = 0.0;
    my @maxys = (0,0,0);
    for (my $idx=0; $idx <= $#{$xs}; ++$idx) {
        die "STRANGE ERROR: undefined xs[$idx] at $loc" if !defined($xs->[$idx]) && $debugMode;
        die "STRANGE ERROR: undefined ys[$idx] at $loc" if !defined($ys->[$idx]) && $debugMode;
        # untransformed point
        my $ux = $xs->[$idx];
        my $uy = $ys->[$idx];
        $total += 1;
        next if ($uy<=0);
        next if ($dologx && $ux<=0);
        $sumLinY += $uy;
        $minLinX = $ux if ($ux < $minLinX);
        $maxLinX = $ux if ($ux > $maxLinX);
        # now take the logs if applicable
        my $x = $dologx ? log($ux) : $ux;
        my $y = $dology ? log($uy) : $uy;
        #
        $n += 1;
        $sx += $x;
        $sy += $y;
        $sxx += $x ** 2;
        $syy += $y ** 2;
        $sxy += $x * $y;
        push(@maxys, $y);
        @maxys = sort { $b <=> $a } @maxys;
        @maxys = @maxys[0..2];
    }
    if ($n < 0) { warn "WARNING: integer overflow an '$loc': skipping"; return; }
    elsif ($n <= 1) { return; } # at the very least we need to skip these -- avg ssr isn't defined
    return if $n < 10; # a set-able paramter.  ignore fits when we see fewer than 10 points
    # common subexpressions
    my $txy = $n * $sxy - $sx * $sy;
    my $tx =  $n * $sxx - $sx ** 2;
    my $ty =  $n * $syy - $sy ** 2;
    #print "txy:$txy tx:$tx ty:$ty sx:$sx sy:$sy sxx:$sxx syy:$syy sxy:$sxy n:$n\n";

    my $slope = 0;
    my $intercept = 0;
    my $rsq = 0;
    my $msg = "$loc: (txy:$txy tx:$tx ty:$ty sx:$sx sy:$sy sxx:$sxx syy:$syy sxy:$sxy n:$n)";
    if (abs($tx) < $eps) {
        # don't return a fit if there's no variation in the xs
        #warn "$msg tx is close to zero\n";
        return;
    } elsif (abs($ty) < $eps) {
        # there was very little variation in the ys -- just return a constant fit
        #warn "$msg ty is close to zero\n";
        return unless 'linear' eq $type;
        $slope = 0;
        $intercept = $sy / $n; 
        $rsq = 0; # R^2 is undefined if there's no variation and useless if there is little variation
    } else {
        # nothing unusual -- do the fit
        $slope = $txy / $tx;
        $intercept = ($sy - $slope * $sx) / $n;
        $rsq = ($txy ** 2) / ($tx * $ty);
    }
    my $coef0 = $dology ? exp($intercept) : $intercept;
    my $coef1 = $slope;

    # compute the residuals and  some other stuff
    my $ssr = 0.0;
    my $ussr = 0.0;
    my $premre = 0.0;
    my $upremre = 0.0;
    for (my $idx=0; $idx <= $#{$xs}; ++$idx) {
        # untransformed point
        my $ux = $xs->[$idx];
        my $uy = $ys->[$idx];
        next if ($uy<=0);
        next if ($dologx && $ux<=0);
        # now take the logs if applicable
        my $x = $dologx ? log($ux) : $ux;
        my $y = $dology ? log($uy) : $uy;
        # the model's prediction and the residual
        my $yhat = $intercept + $slope*$x;
        my $resid = $y - $yhat;
        # the model's prediction in untransformed space; the residual in same
        my $uyhat = $dology ? exp($yhat) : $yhat;
        my $uresid = $uy - $uyhat;
        #
        $ssr += $resid**2;
        $ussr += $uresid**2;
        #
        my $yOrOne = (abs($y)<1.0 ? 1.0 : $y);
        $premre += log( ($yOrOne + abs($resid)) / $yOrOne );
        my $uyOrOne = (abs($uy)<1.0 ? 1.0 : $uy);
        $upremre += log( ($uyOrOne + abs($uresid)) / $uyOrOne );
    }
    my $avgssr = sqrt($ssr / ($n-1));
    my $uavgssr = sqrt($ussr / ($n-1));
    my $mre = exp($premre / $n);
    my $umre = exp($upremre / $n);
    return ($n, $coef0, $coef1, $rsq, $mre, $umre, $avgssr, $uavgssr, $minLinX, $maxLinX, $sumLinY, $sx, $sy);
}


######################################################################
######################################################################
# perl insists that your module evaluate to true
1;
