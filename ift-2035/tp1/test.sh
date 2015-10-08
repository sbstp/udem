#!/bin/bash
# Permet de tester le programme (avec un mauvais allocateur) à plusieurs reprises
# dans le but de détecter des fuites de mémoire à la suite d'une erreur d'allocation.

input="\
4 4 + =a =b
a b * =c =d
d a - =e
0 =e
e =d
d =b
2 3 * 4 * 5 * 6 * 7 *"

for i in `seq 1 100`; do
    echo "$input" | valgrind --leak-check=full --error-exitcode=1 1> teststdout 2> teststderr ./tp1
    echo "=================================================================="
    echo "Test #$i"
    cat teststdout
    if [ $? -ne 0 ] ; then
        cat teststderr
    fi
done

rm teststdout
rm teststderr
