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

IS_MOJO=$(basename `pwd`)
if [ $IS_MOJO = "mojo" ]; then
    echo "Tidy all files in lib/."
    for f in `find lib/ -name "*.pm"`; do
	echo $f
	perltidy -pro=../resources/scripts/releng/perltidyrc ${f} > ${f}_;
    done
    for f in `find lib/ -name "*.pm"`; do
	mv ${f}_ ${f};
    done
    echo "Tidy all files in t/."
    for f in `find t/ -name "*.t"`; do
	echo $f
	perltidy -pro=../resources/scripts/releng/perltidyrc ${f} > ${f}_;
    done
    for f in `find t/ -name "*.t"`; do
	mv ${f}_ ${f};
    done
else
    echo "This script must be executed from the mojo directory."
fi

