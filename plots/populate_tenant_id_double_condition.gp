set terminal svg enhanced font "Helvetica,14"
set output '../public/img/populate_tenant_id_double_condition.svg'

unset logscale
set logscale x
set grid lw 1 linetype 1 lc rgb "gray"
set xrange [1:100000]
set yrange [2000:250000]
set key box left inside 
set title "select populate\_missing\_field(n)"
set xlabel "max\_rows [n]"
set ylabel "time [s]"
plot '-' with points pt 7 lc rgb "blue" title "populate"
10 6123.360
20 6392.647
50 5869.910
100 5929.555
1000 7175.841
10000 242200.066
e