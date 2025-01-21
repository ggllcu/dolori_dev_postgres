set terminal svg enhanced font "Helvetica,14"
set output '../img/select_with_limit_half_data.svg'

set logscale x
set grid lw 1 linetype 1 lc rgb "gray"
set xrange [1:100000]
set yrange [0:3000]
set title "select with limit"
set key box left inside 
set xlabel "limit [n]"
set ylabel "time [ms]"
plot '-' with points pt 7 lc rgb "blue" title "select"
10 1419.836
100 1399.470
1000 2259.829
10000 1393.022
e