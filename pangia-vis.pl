#!/usr/bin/env perl
use Cwd;
use strict;

my $bin_dir = Cwd::realpath($0);
$bin_dir =~ s/pangia-vis\.pl//;
my $pvis_dir = "$bin_dir/pangia-vis";
my $refresh_peroid = 0;
my $no_show = 0;
my $debug = "";
my $overwrite = 0;

# get tsv file - either the first or the last argument
my $tsvfile = Cwd::realpath($ARGV[0]);
if(!-e $tsvfile){
    $tsvfile = Cwd::realpath($ARGV[-1]);
}

# parsing optional arguments
my $args = join(",",@ARGV);
if( $args =~ /-refresh.(\d+)/ ){
    $refresh_peroid=$1;
    $refresh_peroid *= 1000;
}
if( $args =~ /-no-show/ ){
    $no_show = 1;
}
if( $args =~ /-debug/ ){
    $debug = "--log-level debug";
}
if( $args =~ /-overwrite/ ){
    $overwrite = 1;
}

# get project prefix
if( @ARGV > 0 )
{
    my ($prefix) = $tsvfile =~ /^(.*)\.report\.tsv/;

    if( -e $tsvfile && $tsvfile=~/\.report\.tsv/ ){
        if( -d "${prefix}_tmp" ){
            if( -d $prefix ){
                print STDERR "[WARNING] Genome coverage directory existed: $prefix/.\n";
                print STDERR "[WARNING] Overwriting the directory...\n" if $overwrite;
            }

            if( !-d $prefix || $overwrite){
                print STDERR "[INFO] Generating genome coverage data...\n";
                my $ecode = system("$pvis_dir/scripts/depth_scale_down.sh ${prefix}_tmp/merged_sam $prefix");
                if( $ecode ){
                    print STDERR "[ERROR] Failed to calculate genome coverage data.\n";
                }
                else{
                    print STDERR "[INFO] Done.\n";
                }
            }
        }
        else{
            if( -d $prefix ){
                print STDERR "[INFO] Genome coverage directory existed: $prefix/.\n";
            }
            else{
                print STDERR "[WARNING] ${prefix}_tmp directory not found. Genome coverage plot is unavailable.\n";
            }
        }
    }
    else{
        die( "[ERROR] Input PanGIA result not found: $tsvfile\n" );
    }

    unless($no_show){
        print STDERR "[INFO] Opening PanGIA-VIS application on http://localhost:5006/pangia-vis\n";
        my $cmd = "bokeh serve $pvis_dir --show $debug --args $tsvfile $refresh_peroid 1>&2";
        if($debug){
            print STDERR "[INFO] Launching Bokeh: $cmd\n";
        }
        system($cmd)
    }
}
else{
    die("USAGE: ./pangia-vis.pl path_to/pangia.report.tsv [--refresh <sec>|--no-show] [--overwrite]\n");
}
