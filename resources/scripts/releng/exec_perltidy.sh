

IS_MOJO=$(basename `pwd`)
if [ $IS_MOJO = "mojo" ]; then
    for f in `find lib/ -name "*.pm"`; do perltidy ${f} > ${f}_; done
    for f in `find lib/ -name "*.pm"`; do mv ${f}_ ${f}; done
    echo "Tidied all files in lib/."
else
    echo "This script must be executed from the mojo directory."
fi

