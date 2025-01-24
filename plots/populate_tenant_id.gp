set terminal svg enhanced font "Helvetica,14"
set output '../public/img/populate_missing_field.svg'

unset logscale
set grid lw 1 linetype 1 lc rgb "gray"
set xrange [0:120]
set yrange [0:220000]
set key box left inside 
set title "select populate\_missing\_field(n)"
set xlabel "max\_rows [n]"
set ylabel "time [s]"
plot '-' with points pt 7 lc rgb "blue" title "populate"
10 5628.454
20 6188.688
50 193403.525
100 203911.870
e