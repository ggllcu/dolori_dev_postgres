set terminal svg enhanced font "Helvetica,14"
set output '../img/select_with_limit.svg'

set logscale x
set grid lw 1 linetype 1 lc rgb "gray"
set xrange [1:10000]
set yrange [0:3000]
set title "select with limit"
set key box left inside 
set xlabel "limit [n]"
set ylabel "time [ms]"
plot '-' with points pt 7 lc rgb "blue" title "select"
10 1371.396
100 1448.198
1000 1357.622
e