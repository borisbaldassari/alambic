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


# Return code:
#  * 0 if ok
#  * 1 if dependencies not met


PB_V=5.26.2
VERSION=3.3.4-dev
LOG=alambic_install.log

IS_MOJO=$(basename `pwd`)
if [ $IS_MOJO != "mojo" ]; then
    echo "Please run this script from the mojo directory."
    exit 255
fi

echo "\nHi! I'm going to install Alambic [$VERSION]\n"
echo "Hi! I'm going to install Alambic [$VERSION]" > $LOG

_check_prerequisite() {
    CMD=$1
    printf "  * Checking prerequisite [$CMD]..."
    printf "  * Checking prerequisite [$CMD]..." >> $LOG
    P_CMD=`which $CMD`
    O_CMD=$?
    if [ $O_CMD -eq 0 ]; then
        echo " [$P_CMD]."
        echo " [$P_CMD]." >> $LOG
    else
        echo " ERROR: $CMD is required. Please install it and re-run me."
        echo " ERROR: $CMD is required. Please install it and re-run me." >> $LOG
        exit 1
    fi
}

echo "# Checking system prerequisites."
echo "# Checking system prerequisites." >> $LOG
# Not debian: libcurl-devel perl-CPAN libxml2-devel openssl-devel
CMDS="wget passwd gcc make bzip2 git openssl pandoc" # libexpat1-dev"
for c in `echo $CMDS | tr ' ' '\n'`; do
    _check_prerequisite $c;
done

PERL_VERSION=`perl -e "print $^V"`
echo "  * Checking perl version.. Found Perl $PERL_VERSION"
echo "  * Checking perl version.. Found Perl $PERL_VERSION" >> $LOG

# Download perlbrew and install it.
printf "  * Checking if perlbrew is installed..."
printf "  * Checking if perlbrew is installed..." >> $LOG
perlbrew list > /dev/null
PB_IS_OK=$?
if [ $PB_IS_OK -ne 0 ]; then
    echo "\n  * Perlbrew not installed. Installing it right now."
    echo "\n  * Perlbrew not installed. Installing it right now." >> $LOG
    \curl -L https://install.perlbrew.pl | bash
    echo "  * Adding perlbrew init procedure to ~/.bashrc and sourcing it."
    echo "  * Adding perlbrew init procedure to ~/.bashrc and sourcing it." >> $LOG
    echo 'source ~/perl5/perlbrew/etc/bashrc' >> ~/.bashrc
    source ~/.bashrc
else
    echo " OK."
    echo " OK." >> $LOG
fi


# Using perlbrew, install cpanm, recent version of perl, and all modules

# Get last perl version from 5.24 series
PB_V_R=`perlbrew list | grep  " perl-$PB_V" | cut -d- -f2`

echo "# Identifying available perls: found [$PB_V_R]."
echo "# Identifying available perls: found [$PB_V_R]." >> $LOG

# Checking if cpanm is installed
printf "  * Checking if cpanm is installed..."
printf "  * Checking if cpanm is installed..." >> $LOG
cpanm 2>&1 > /dev/null
P_V=$?
if [ $P_V -ne 1 ]; then
    echo " Nope.\n  * Installing cpanm."
    echo " Nope.\n  * Installing cpanm." >> $LOG
    perlbrew install-cpanm
else
    echo " OK."
    echo " OK." >> $LOG
fi


# Checking if perl $PB_V is installed
printf "  * Checking if perl-$PB_V is installed..."
printf "  * Checking if perl-$PB_V is installed..." >> $LOG
perl --version | grep $PB_V > /dev/null
if [ $? -ne 0 ]; then
    echo " Nope.\n  * Installing cpanm and perl $PB_V."
    echo " Nope.\n  * Installing cpanm and perl $PB_V." >> $LOG
    perlbrew --notest install perl-$PB_V_R
else
    echo " OK."
    echo " OK." >> $LOG
fi


# Checking if all modules are installed
perlbrew switch perl-$PB_V
#perlbrew switch perl-$PB_V_R

echo "# Installing perl modules.."
echo "# Installing perl modules.." >> $LOG
POSTGRES_HOME=/usr/pgsql-9.5
cpanm Sub::Identify DBI DBD::Pg inc::Module::Install Digest::MD5 Crypt::PBKDF2 Date::Parse DateTime File::chdir File::Basename File::Copy File::Path File::stat List::Util List::MoreUtils Minion Mojolicious Mojo::JSON Mojo::UserAgent Mojo::Pg XML::LibXML Text::CSV Time::localtime Mojolicious::Plugin::Mail Test::More Clone Test::Perl::Critic Net::IDN::Encode IO::Socket::SSL Git::Repository JIRA::REST Mojolicious::Plugin::InstallablePaths Pod::ProjectDocs GitLab::API::v4 Moose HTML::Entities Template Mojolicious::Plugin::Minion::Admin URI::Escape::XS >> $LOG

if [ $? -eq 0 ]; then
    echo "# Perl modules installed"
    echo "# Perl modules installed" >> $LOG
fi

# If alambic.conf exists, use its values
if [ -e alambic.conf ]; then
    echo "# Found alambic.conf."
    echo "# Found alambic.conf." >> $LOG
else
    echo "# Configuring Postgresql database..."
    read -p "  * Postgresql server name: [localhost] " PG_HOST
    PG_HOST=${PG_HOST:-}
    read -p "  * Postgresql user: [alambic] " PG_USER
    PG_USER=${PG_USER:-alambic}
    read -p "  * Postgresql password: [pass4alambic] " PG_PASSWD
    PG_PASSWD=${PG_PASSWD:-pass4alambic}
    read -p "  * Postgresql alambic db: [alambic_db] " PG_DB_AL
    PG_DB_AL=${PG_DB_AL:-alambic_db}
    read -p "  * Postgresql minion db: [minion_db] " PG_DB_MI
    PG_DB_MI=${PG_DB_MI:-minion_db}
    read -p "  * Alambic port: [3010] " AL_PORT
    AL_PORT=${AL_PORT:-3010}
fi

echo "\n# Checking R installation.."
_check_prerequisite "R";
_check_prerequisite "Rscript";
R_VERSION=`R --version | grep "R version"`
echo "# Found R version: ${R_VERSION}."

_check_r_prerequisite() {
    CMD=$1
    printf "  * Checking R prerequisite [$CMD]..."
    printf "  * Checking R prerequisite [$CMD]..." >> $LOG

    P_CMD=`Rscript -e "if (!require(\"$CMD\")) install.packages(c(\"$CMD\"), repos=\"http://cran.r-project.org\")" 2>/dev/null`
    O_CMD=$?
    if [ $O_CMD -eq 0 ]; then
        echo " [ok]."
        echo " [ok]." >> $LOG
    else
        echo " ERROR: $CMD is required. Please install it and re-run me."
        echo " ERROR: $CMD is required. Please install it and re-run me." >> $LOG
        exit 1
    fi
}

CMDS="BH DBI NLP R6 RColorBrewer Rcpp SnowballC assertthat backports base64enc bitops caTools colorspace curl dichromat digest dplyr dygraphs evaluate ggplot2 ggthemes googleVis gtable hexbin highr htmltools htmlwidgets httr jsonlite knitr labeling lazyeval magrittr markdown mime munsell openssl packrat pander plotly plyr purrr reshape2 rmarkdown rprojroot scales slam stringi stringr tibble tidyr tm viridisLite wordcloud xtable xts yaml zoo"
for c in $CMDS; do
    _check_r_prerequisite $c;
done

# Everything is fine, we can simply install Alambic now.
echo "Everything seems to be fine. You can now run Alambic.\n"

#perlbrew off



