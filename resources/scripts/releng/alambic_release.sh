

AL_V=3.3.1-dev

# Check that we are in the mojo directory.
IS_MOJO=$(basename `pwd`)
if [ -e 'mojo' ]; then #|| [ -e 'doc' ]; then
    #if [ $IS_MOJO != "mojo" ]; then
    echo "\nHi. working on version [$AL_V] of Alambic.\n";
else 
    echo "This script must be executed from the Alambic home directory (i.e. there must be a mojo dir). Exiting."
    exit 10;
fi

# Create temp directory in /tmp
echo "----- Creating tmp directory: $AL_TMP."
AL_TMP=`mktemp -d`

# Create log file
AL_LOG=resources/scripts/releng/alambic_checks.txt
echo "----- Creating log file: $AL_LOG."
echo "\nHi. working on version [$AL_V] of Alambic.\n" > $AL_LOG


# Checking that alambic.conf has the correct version
echo "" | tee $AL_LOG
echo "----- Checking Alambic version." | tee $AL_LOG

cd mojo
TMP_V=`grep alambic_version alambic.conf | cut -d\" -f4`
TMP_V=${TMP_V:-none}

if [ $AL_V = $TMP_V ]; then
    echo "[OK]  Checking that alambic.conf has the correct version." | tee $AL_LOG
else
    echo "[ERR] Conf file alambic.conf has a wrong version [$TMP_V]." | tee $AL_LOG
fi

# Generate SLOC reports
echo "" | tee $AL_LOG
echo "----- Executing SLOCCount on Alambic code." | tee $AL_LOG
sloccount --addlang html lib/ t/ 2>/dev/null | grep -i "perl=" > $AL_TMP/sloccount_report.txt
SLOC_PERL_LIB=`perl -ne 'if ( m!^\d+\s+lib\s+.*perl=(\d+)$! ) { print "$1" }' $AL_TMP/sloccount_report.txt`
SLOC_PERL_T=`perl -ne 'if ( m!^\d+\s+t\s+.*perl=(\d+)$! ) { print "$1" }' $AL_TMP/sloccount_report.txt`
echo "  * Found $SLOC_PERL_LIB lines of Perl code in lib dir." | tee $AL_LOG
echo "  * Found $SLOC_PERL_T lines of Perl code in test (t/) dir." | tee $AL_LOG

cd ..


# Generate all perldoc



# Generate web site

