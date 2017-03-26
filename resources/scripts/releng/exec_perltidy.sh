

IS_MOJO=$(basename `pwd`)
if [ $IS_MOJO = "mojo" ]; then
    echo "Tidy all files in lib/."
    for f in `find lib/ -name "*.pm"`; do
	perltidy -pro=../resources/scripts/releng/perltidyrc ${f} > ${f}_;
    done
    for f in `find lib/ -name "*.pm"`; do
	mv ${f}_ ${f};
    done
    echo "Tidy all files in t/."
    for f in `find t/ -name "*.t"`; do
	perltidy -pro=../resources/scripts/releng/perltidyrc ${f} > ${f}_;
    done
    for f in `find t/ -name "*.t"`; do
	mv ${f}_ ${f};
    done
else
    echo "This script must be executed from the mojo directory."
fi

