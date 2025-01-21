set terminal svg enhanced font "Helvetica,14"
set output '../img/total_cost.svg'

set logscale x
set logscale y
set grid lw 1 linetype 1 lc rgb "gray"
set xrange [1:100000]
set yrange [1000:1000000]
set title "total cost"
set key box left inside 
set xlabel "limit [n]"
set ylabel "time [ms]"
plot '-' with points pt 7 lc rgb "blue" title "total cost"
10 3609
100 6422
1000 40690
10000 390264
e