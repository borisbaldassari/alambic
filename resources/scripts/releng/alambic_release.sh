#########################################################
#
# Copyright (c) 2015-2017 Castalia Solutions and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   Boris Baldassari - Castalia Solutions
#
#########################################################

AL_V=3.3.2-dev
AL_DIR_PERLDOC=doc/public/perldoc/

AL_DESC="Alambic developer documentation (Perlpod). Checkout the \
official web site at https://alambic.io for more information."

# Check that we are in the mojo directory.

IS_MOJO=$(basename `pwd`)
if [ -e 'mojo' ]; then 
    echo "\nHi. working on version [$AL_V] of Alambic.\n";
else 
    echo "This script must be executed from the Alambic home directory (i.e. there must be a mojo dir). Exiting."
    exit 10;
fi

# Create temp directory in /tmp

AL_TMP=`mktemp -d`
echo "----- Creating tmp directory: $AL_TMP."
echo ""

# Create log file

AL_LOG=${PWD}/resources/scripts/releng/alambic_checks.txt
echo "----- Creating log file: $AL_LOG."
echo "\nHi. working on version [$AL_V] of Alambic.\n" > $AL_LOG


# Check TODOs

echo "" | tee -a $AL_LOG
echo "----- Checking the number of TODOs." | tee -a $AL_LOG
TODOS=`grep -Ri todo mojo/lib mojo/t doc/ | wc -l`
if [ $TODOS -gt 0 ]; then
    echo "[ERR] Found $TODOS TODOs." | tee -a $AL_LOG
else
    echo "[OK]  Found zero TODO." | tee -a $AL_LOG
fi

# Checking that alambic.conf has the correct version

echo "" | tee -a $AL_LOG
echo "----- Checking Alambic version [$AL_V]." | tee -a $AL_LOG

cd mojo
TMP_V=`grep alambic_version alambic.conf | cut -d\" -f4`
TMP_V=${TMP_V:-none}

if [ $AL_V = $TMP_V ]; then
    echo "[OK]  Checking that alambic.conf has the correct version [$TMP_V]." | tee -a $AL_LOG
else
    echo "[ERR] Conf file alambic.conf has a wrong version [$TMP_V]." | tee -a $AL_LOG
fi

# Checking version in alambic_ci image..
TMP_V=`grep alambic_version ../docker/image_ci/alambic.conf | cut -d\" -f4`
TMP_V=${TMP_V:-none}

if [ $AL_V = $TMP_V ]; then
    echo "[OK]  Checking that image_ci/alambic.conf has the correct version [$TMP_V]." | tee -a $AL_LOG
else
    echo "[ERR] Conf file image_ci/alambic.conf has a wrong version [$TMP_V]." | tee -a $AL_LOG
fi

# Checking version in alambic_test image..
TMP_V=`grep alambic_version ../docker/image_test/alambic.conf | cut -d\" -f4`
TMP_V=${TMP_V:-none}

if [ $AL_V = $TMP_V ]; then
    echo "[OK]  Checking that image_test/alambic.conf has the correct version [$TMP_V]." | tee -a $AL_LOG
else
    echo "[ERR] Conf file image_test/alambic.conf has a wrong version [$TMP_V]." | tee -a $AL_LOG
fi


# Generate SLOC reports

echo "" | tee -a $AL_LOG
echo "----- Executing SLOCCount on Alambic code." | tee -a $AL_LOG

sloccount --addlang html lib/ t/ 2>/dev/null | grep -i "perl=" > $AL_TMP/sloccount_report.txt
SLOC_PERL_LIB=`perl -ne 'if ( m!^\d+\s+lib\s+.*perl=(\d+)$! ) { print "$1" }' $AL_TMP/sloccount_report.txt`
SLOC_PERL_T=`perl -ne 'if ( m!^\d+\s+t\s+.*perl=(\d+)$! ) { print "$1" }' $AL_TMP/sloccount_report.txt`
echo "\nFound:" | tee -a $AL_LOG
echo "  * $SLOC_PERL_LIB lines of Perl code in lib dir." | tee -a $AL_LOG
echo "  * $SLOC_PERL_T lines of Perl code in test (t/) dir." | tee -a $AL_LOG
cd ..

# Tidy source files

echo "" | tee -a $AL_LOG
echo "----- Tidying source files." | tee -a $AL_LOG

echo "Tidy all files in mojo/lib/."
for f in `find mojo/lib/ -name "*.pm"`; do
    echo $f
    perltidy -pro=resources/scripts/releng/perltidyrc ${f} > ${f}_;
done
for f in `find mojo/lib/ -name "*.pm"`; do
    mv ${f}_ ${f};
done
echo "Tidy all files in mojo/t/."
for f in `find mojo/t/ -name "*.t"`; do
    echo $f
    perltidy -pro=resources/scripts/releng/perltidyrc ${f} > ${f}_;
done
for f in `find mojo/t/ -name "*.t"`; do
    mv ${f}_ ${f};
done

# Generate web site

echo "" | tee -a $AL_LOG
echo "----- Generating web site from markdown." | tee -a $AL_LOG

rm -rf doc/dump/*
doc/webapp.pl dump

# Generate all perldoc

echo "" | tee -a $AL_LOG
echo "----- Generating perldoc html files in doc section." | tee -a $AL_LOG

rm -rf $AL_DIR_PERLDOC
pod2projdocs -out $AL_DIR_PERLDOC -lib mojo/lib/ -title "Alambic Perldoc" -desc $AL_DESC

# Finished!

echo "" | tee -a $AL_LOG
echo "----- Processing completed. Have a good day!" | tee -a $AL_LOG
