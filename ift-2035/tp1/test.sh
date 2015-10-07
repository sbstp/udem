#!/bin/bash
# Permet de tester le programme (avec un mauvais allocateur) à plusieurs reprises
# dans le but de détecter des fuites de mémoire à la suite d'une erreur d'allocation.

input="\
4 4 + =x =z
z x +
y x +
x x * =o
o x * =p
"

for i in `seq 1 100`; do
    echo $input | valgrind --leak-check=full --error-exitcode=1 1> teststdout 2> teststderr ./tp1
    if [ $? -ne 0 ] ; then
        echo "=================================================================="
        echo "Test #$i"
        cat teststdout
        echo ""
        cat teststderr
    fi
done

rm teststdout
rm teststderr
