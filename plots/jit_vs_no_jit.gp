set terminal svg enhanced font "Helvetica,14"
set output '../img/jit_vs_no_jit.svg'

unset logscale
set logscale x
set grid lw 1 linetype 1 lc rgb "gray"
set xrange [1:1000000]
set yrange [0:50000]
set key box left inside 
set title "select populate\_missing\_field(n)"
set xlabel "max\_rows [n]"
set ylabel "time [s]"
plot '-' with points pt 7 lc rgb "blue" title "No JIT", '-' with points pt 7 lc rgb "red" title "JIT"
10 55.707
100 72.908
1000 648.344
10000 5114.02
100000 41989.483
e
10 45.214
100 47.519
1000 235.334
10000 2394.478
100000 22711.465
e