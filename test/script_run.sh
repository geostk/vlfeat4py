SRC=..
INC=../..
LIB=../../lib

PROG=kmeans
g++ -o test_vl_$PROG $SRC/vl_$PROG.cpp test_vl_$PROG.cpp -I $INC -L $LIB -larmadillo -lvl
./test_vl_$PROG
valgrind --leak-check=summary ./test_vl_$PROG