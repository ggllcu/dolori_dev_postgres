---
# You can also start simply with 'default'
theme: default
# random image from a curated Unsplash collection by Anthony
# like them? see https://unsplash.com/collections/94734566/slidev
# background: /img/bug.png
# some information about your slides (markdown enabled)
title: I dolori di un giovane dev (vs PostgreSQL)
info: |
  Luca Guglielmi
  2025-01-24
# apply unocss classes to the current slide
# class: text-center
# https://sli.dev/features/drawing
drawings:
  persist: false
# slide transition: https://sli.dev/guide/animations.html#slide-transitions
transition: slide-left
# enable MDC Syntax: https://sli.dev/features/mdc
mdc: true
showLanguage: true
lineNumbers: true
# hideInToc: true
---

# I dolori di un giovane dev (vs PostgreSQL)

Luca Guglielmi

2025-01-24


---
layout: image
image: /img/bug.png
backgroundSize: contain
---

---
layout: section
---

# La situazione

---
src: ./pages/premesse.md
---

---
src: ./pages/situation.md
---

---
src: ./pages/operation.md
---

---
src: ./pages/process.md
---

---
layout: section
---

# Primo step: operazioni preliminari

---
src: ./pages/analysis_1.md
---

---
src: ./pages/solution_1.md
---

---
layout: section
---

# Secondo step: operazione principale

---
src: ./pages/analysis_2.md
---

---
src: ./pages/solution_2_1.md
---

---
src: ./pages/solution_2_2.md
---

---
src: ./pages/solution_2_3.md
---

---
src: ./pages/til_1.md
---

---
src: ./pages/til_2.md
---

---
layout: section
---

# Terzo step

---
src: ./pages/analysis_3.md
---

---
src: ./pages/solution_3.md
---

---

# Quarto step: 

## Uso di `explain analyze`

YOU DON'T SAY!!!

<v-click>

File di circa 70k righe, generati all'interno di un container docker dentro una macchina virtuale accessibile solo via ssh. 

Ho provato con grep, ma l'unica cosa che ho notato e' che a volte __Planning Time__ ed __Execution Time__ sono simili, a volte sono completamente fuori scala.
</v-click>

<v-click>

E' necessario passare l'output su un file per poterlo analizzare:
</v-click>

<v-click>
```sql
\o /path/to/your/file.sql
```
</v-click>

<v-click>
```sh
docker compose cp /path/to/your/file.sql .
```
</v-click>

---

## Funzione originale

<br>

<v-click>

### 10

```sql
Planning Time: 2885.200 ms
Execution Time: 2973.032 ms
```
</v-click>

<br>

<v-click>

### 100

```sql
Planning Time: 2334.413 ms
JIT:
  Functions: 139493
  Options: Inlining false, Optimization false, Expressions true, Deforming true
  Timing: Generation 38582.997 ms, Inlining 0.000 ms, Optimization 10336.241 ms, Emission 162878.320 ms, Total 211797.558 ms
Execution Time: 216691.628 ms
```
</v-click>

---

## Nuova funzione (condizione ridondante)

<br>

<v-click>

### 10
```
Planning Time: 2359.241 ms
Execution Time: 2918.323 ms
```
</v-click>

<v-click>

### 100
```
Planning Time: 2243.924 ms
Execution Time: 3035.774 ms
```
</v-click>

<v-click>

### 1000
```
Planning Time: 2273.605 ms
Execution Time: 4264.941 ms
```
</v-click>

<v-click>

### 10000
```
Planning Time: 2301.638 ms
JIT:
  Functions: 139495
  Options: Inlining false, Optimization false, Expressions true, Deforming true
  Timing: Generation 32651.882 ms, Inlining 0.000 ms, Optimization 9264.750 ms, Emission 165861.856 ms, Total 207778.488 ms
Execution Time: 225298.909 ms
```
</v-click>

---

Sembra che, quando entra in funzione JIT (Just-in-Time Compilation), peggiori le cose invece di migliorarle.

---

## Soluzione 4: disabilitare JIT

Impostiamo la funzione in maniera che disabiliti e poi ripristini __jit__

```sql
SELECT current_setting('jit') INTO previous_jit_setting;

PERFORM set_config('jit', 'false', false);

...

PERFORM set_config('jit', previous_jit_setting, false);
```

<v-click>

```sql
select cdr.populate_tenant_id(10000);
-- Time: 18071.253 ms (00:18.071)
```
</v-click>
<v-click>
```sql
Planning Time: 2650.283 ms
Execution Time: 14057.573 ms
```
</v-click>
<v-click>

Siamo passati da una funzione che va in timeout ogni ora, ad una funzione di 14 secondi. 
</v-click>

---

# Quesiti in sospeso

<br>

<v-clicks>

1. Perche' parte JIT in funzione del parametro?
2. Perche' parte piu' tardi con la seconda (ridondante) condizione sui where?
</v-clicks>

<v-click>

JIT viene eseguito quando il costo di una query supera un certo parametro. 
</v-click>

<v-click>

```sql
SHOW jit_above_cost;
-- 100000
```
</v-click>


---

## Funzione originale

```sql
-- 10
Update on timeseries t  (cost=1.02..17703.43 rows=1850 width=477) (actual time=16.923..20.623 rows=0 loops=1)
...
Hash Join  (cost=1.02..95.30 rows=10 width=478) (actual time=0.007..0.026 rows=0 loops=1)
         Hash Cond: (t_5.id = c_4.id)
```

```sql
-- 100
Update on timeseries t  (cost=8.93..156134.29 rows=18500 width=477) (actual time=174753.610..174764.536 rows=0 loops=1)
...
Hash Join  (cost=8.93..839.40 rows=100 width=478) (actual time=0.012..0.100 rows=0 loops=1)
         Hash Cond: (t_2.id = c_1.id)
```

<v-click>

Andando a vedere dove ci sono le differenze di costo, vediamo che sono in corrispondenza delle `Hash Join`
</v-click>

<v-click>

L'hash join viene eseguito 184 volte in entrambe le query. La differenza di costo totale e' quindi 184 * (849.40 - 95.30) = __138.754,4__, che e' esattamente la differenza di costo tra le due query.
</v-click>

---

## Nuova funzione

<br>

### Total cost

<br>

```sql
-- 10
Update on timeseries t  (cost=0.29..3609.03 rows=194 width=466) (actual time=23.394..28.693 rows=0 loops=1)

-- 100
Update on timeseries t  (cost=9.66..6422.23 rows=284 width=395) (actual time=233.401..238.015 rows=0 loops=1)

-- 1000
Update on timeseries t  (cost=9.66..40690.33 rows=1920 width=356) (actual time=1282.703..1289.448 rows=0 loops=1)

-- 10000
Update on timeseries t  (cost=9.66..390264.94 rows=19200 width=356) (actual time=189298.447..189305.867 rows=0 loops=1)
```

---
layout: image
image: /img/total_cost.svg
backgroundSize: contain
---

---

### Hash join

```sql{all|2,7,12,17|all}
-- 10
Nested Loop  
  (cost=0.29..18.70 rows=1 width=478) (actual time=0.037..0.070 rows=0 loops=1)
         Join Filter: (t_1.id = c.id)

-- 100
Hash Join
  (cost=9.66..25.75 rows=1 width=478) (actual time=2.310..2.341 rows=0 loops=1)
         Hash Cond: (c.id = t_1.id)

-- 1000
Hash Join
  (cost=9.66..129.65 rows=5 width=478) (actual time=1.640..1.693 rows=0 loops=1)
         Hash Cond: (c.id = t_1.id)

-- 10000
Hash Join
  (cost=9.66..1209.58 rows=50 width=478) (actual time=176127.315..176127.358 rows=0 loops=1)
         Hash Cond: (c.id = t_1.id)
```

<v-click>

Abbiamo 184 __Hash Join__, ma per ogni Hash Join scannerizza tutte le partizioni giornaliere. Il comportamento e' esponenziale.
</v-click>

---

## Soluzione 5: limitare le partizioni

Limitare il numero di partizioni su cui viene eseguita la query.

```sql
SELECT DISTINCT id, tableoid::regclass FROM cdr.timeseries 
where tenant_id is null LIMIT 10000;
```

<v-click>

Questa non funziona perche' il limite e' sui valori univoci. Serve anche qui una subquery.
</v-click>

---


```sql{all|2-6|9-26}
FOR distinct_value IN
SELECT DISTINCT tableoid::regclass
FROM
  (SELECT tableoid::regclass
   FROM cdr.timeseries
   LIMIT max_cdr_to_process) subquery 
LOOP 
  EXECUTE format($sql$
      WITH c AS (
          SELECT id, imsi, datetime
          FROM %s
          WHERE tenant_id IS NULL
          LIMIT $1
      )
      UPDATE %s AS t
      SET tenant_id = COALESCE(
          (
              SELECT tenant_id
              FROM cdr.usims AS u
              WHERE u.imsi = c.imsi AND u.datetime <= c.datetime
              ORDER BY datetime DESC
              LIMIT 1
          ), 'Unknown'
      )
      FROM c
      WHERE c.id = t.id AND tenant_id IS NULL
  $sql$, distinct_value, distinct_value) 
  USING max_cdr_to_process;

END LOOP;
```

<style>
code {
  font-size: 10px !important;
}
</style>


---

## Explain analyze singola partizione

```sql
EXPLAIN ANALYZE WITH c AS (
                SELECT id, imsi, datetime
                FROM cdr.timeseries_p2024_09_01
                WHERE tenant_id IS NULL
                LIMIT 10000
            )
            UPDATE cdr.timeseries_p2024_09_01 AS t
            SET tenant_id = COALESCE(
                (
                    SELECT tenant_id
                    FROM cdr.usims AS u
                    WHERE u.imsi = c.imsi AND u.datetime <= c.datetime
                    ORDER BY datetime DESC
                    LIMIT 1
                ), 'Unknown'
            )
            FROM c
            WHERE c.id = t.id AND tenant_id IS NULL;
```

--- 

```sql
Update on timeseries_p2024_09_01 t  (cost=0.56..144205.29 rows=6931 width=243) (actual time=4624.891..4624.894 rows=0 loops=1)
   ->  Nested Loop  (cost=0.56..144205.29 rows=6931 width=243) (actual time=37.199..2501.968 rows=10000 loops=1)
         ->  Subquery Scan on c  (cost=0.00..962.67 rows=10000 width=104) (actual time=36.177..58.421 rows=10000 loops=1)
               ->  Limit  (cost=0.00..862.67 rows=10000 width=40) (actual time=36.163..51.834 rows=10000 loops=1)
                     ->  Seq Scan on timeseries_p2024_09_01  (cost=0.00..2630111.88 rows=30488073 width=40) (actual time=0.336..14.819 rows=10000 loops=1)
                           Filter: (tenant_id IS NULL)
         ->  Index Scan using timeseries_p2024_09_01_id_idx on timeseries_p2024_09_01 t  (cost=0.56..8.46 rows=1 width=147) (actual time=0.213..0.214 rows=1 loops=10000)
               Index Cond: (id = c.id)
               Filter: (tenant_id IS NULL)
         SubPlan 1
           ->  Limit  (cost=0.43..8.45 rows=1 width=44) (actual time=0.028..0.028 rows=1 loops=10000)
                 ->  Index Scan Backward using usims_pkey on usims u  (cost=0.43..8.45 rows=1 width=44) (actual time=0.028..0.028 rows=1 loops=10000)
                       Index Cond: ((imsi = c.imsi) AND (datetime <= c.datetime))
 Planning Time: 1.341 ms
 JIT:
   Functions: 23
   Options: Inlining false, Optimization false, Expressions true, Deforming true
   Timing: Generation 7.764 ms, Inlining 0.000 ms, Optimization 1.826 ms, Emission 33.576 ms, Total 43.166 ms
 Execution Time: 4633.210 ms
```

<v-click>

Velocissima, circa 1/3 della funzione sulla tabella intera. 

Tuttavia, il costo e' comunque superiore alla soglia in cui dovrebbe intervenire JIT. 

Proviamo a disabilitarlo e rilanciamo. 
</v-click>

---

```sql
SET jit = false;
```

```sql
EXPLAIN ANALYZE WITH c AS (
                SELECT id, imsi, datetime
                FROM cdr.timeseries_p2024_09_01
                WHERE tenant_id IS NULL
                LIMIT 10000
            )
            UPDATE cdr.timeseries_p2024_09_01 AS t
            SET tenant_id = COALESCE(
                (
                    SELECT tenant_id
                    FROM cdr.usims AS u
                    WHERE u.imsi = c.imsi AND u.datetime <= c.datetime
                    ORDER BY datetime DESC
                    LIMIT 1
                ), 'Unknown'
            )
            FROM c
            WHERE c.id = t.id AND tenant_id IS NULL;
```

---

```sql
Update on timeseries_p2024_09_01 t  (cost=0.56..144205.29 rows=6931 width=243) (actual time=5354.297..5354.300 rows=0 loops=1)
  ->  Nested Loop  (cost=0.56..144205.29 rows=6931 width=243) (actual time=1.315..2571.315 rows=10000 loops=1)
        ->  Subquery Scan on c  (cost=0.00..962.67 rows=10000 width=104) (actual time=0.399..24.139 rows=10000 loops=1)
              ->  Limit  (cost=0.00..862.67 rows=10000 width=40) (actual time=0.373..16.333 rows=10000 loops=1)
                    ->  Seq Scan on timeseries_p2024_09_01  (cost=0.00..2630111.88 rows=30488073 width=40) (actual time=0.370..14.640 rows=10000 loops=1)
                          Filter: (tenant_id IS NULL)
        ->  Index Scan using timeseries_p2024_09_01_id_idx on timeseries_p2024_09_01 t  (cost=0.56..8.46 rows=1 width=147) (actual time=0.217..0.218 rows=1 loops=10000)
              Index Cond: (id = c.id)
              Filter: (tenant_id IS NULL)
        SubPlan 1
          ->  Limit  (cost=0.43..8.45 rows=1 width=44) (actual time=0.034..0.034 rows=1 loops=10000)
                ->  Index Scan Backward using usims_pkey on usims u  (cost=0.43..8.45 rows=1 width=44) (actual time=0.034..0.034 rows=1 loops=10000)
                      Index Cond: ((imsi = c.imsi) AND (datetime <= c.datetime))
Planning Time: 1.313 ms
Execution Time: 5354.589 ms
```

<v-click>

Il tempo e' piu' o meno lo stesso. Facciamo un po' tutti i casi con la funzione completa e vediamo se c'e' una soglia in cui c'e' un punto critico.
</v-click>

---
layout: image
image: /img/jit_vs_no_jit.svg
backgroundSize: contain
---

---

Circa la meta': JIT ha fatto il suo lavoro correttamente. 

Questi tempi sono dell'intera funzione `populate_tenant_id` e sono sensibilmente piu' lunghi della sola parte di update analizzata prima con la `explain analyze`. 

La select delle partizioni e' una funzione abbastanza lenta, ma ne vale decisamente la pena.

Ad ogni modo, per 10k record siamo passati da piu' di un'ora a 2 secondi:
__ (60 * 60) / 2 = 1800__

Ultima curiosita': provo a ritogliere la condizione inutile.

---

## Con condizione

```sql
EXPLAIN ANALYZE WITH c AS (
                SELECT id, imsi, datetime
                FROM cdr.timeseries_p2024_09_01
                WHERE tenant_id IS NULL
                LIMIT 100000
            )
            UPDATE cdr.timeseries_p2024_09_01 AS t
            SET tenant_id = COALESCE(
                (
                    SELECT tenant_id
                    FROM cdr.usims AS u
                    WHERE u.imsi = c.imsi AND u.datetime <= c.datetime
                    ORDER BY datetime DESC
                    LIMIT 1
                ), 'Unknown'
            )
            FROM c
            WHERE c.id = t.id and tenant_id is null;
```

---

```sql
Update on timeseries_p2024_09_01 t  (cost=0.56..1375388.92 rows=69310 width=243) (actual time=10669.294..10669.296 rows=0 loops=1)
  ->  Nested Loop  (cost=0.56..1375388.92 rows=69310 width=243) (actual time=283.311..2948.045 rows=100000 loops=1)
        ->  Subquery Scan on c  (cost=0.00..9626.69 rows=100000 width=104) (actual time=283.221..406.978 rows=100000 loops=1)
              ->  Limit  (cost=0.00..8626.69 rows=100000 width=40) (actual time=283.215..372.071 rows=100000 loops=1)
                    ->  Seq Scan on timeseries_p2024_09_01  (cost=0.00..2630111.88 rows=30488073 width=40) (actual time=0.094..80.248 rows=100000 loops=1)
                          Filter: (tenant_id IS NULL)
        ->  Index Scan using timeseries_p2024_09_01_id_idx on timeseries_p2024_09_01 t  (cost=0.56..7.79 rows=1 width=147) (actual time=0.011..0.012 rows=1 loops=100000)
              Index Cond: (id = c.id)
              Filter: (tenant_id IS NULL)
        SubPlan 1
          ->  Limit  (cost=0.43..8.45 rows=1 width=44) (actual time=0.013..0.013 rows=1 loops=100000)
                ->  Index Scan Backward using usims_pkey on usims u  (cost=0.43..8.45 rows=1 width=44) (actual time=0.012..0.012 rows=1 loops=100000)
                      Index Cond: ((imsi = c.imsi) AND (datetime <= c.datetime))
Planning Time: 0.495 ms
JIT:
  Functions: 23
  Options: Inlining true, Optimization true, Expressions true, Deforming true
  Timing: Generation 5.431 ms, Inlining 14.174 ms, Optimization 158.188 ms, Emission 110.453 ms, Total 288.245 ms
Execution Time: 10675.000 ms
```

---

## Senza condizione 

```sql
EXPLAIN ANALYZE WITH c AS (
                SELECT id, imsi, datetime
                FROM cdr.timeseries_p2024_09_01
                WHERE tenant_id IS NULL
                LIMIT 100000
            )
            UPDATE cdr.timeseries_p2024_09_01 AS t
            SET tenant_id = COALESCE(
                (
                    SELECT tenant_id
                    FROM cdr.usims AS u
                    WHERE u.imsi = c.imsi AND u.datetime <= c.datetime
                    ORDER BY datetime DESC
                    LIMIT 1
                ), 'Unknown'
            )
            FROM c
            WHERE c.id = t.id;
```

---

```sql
 Update on timeseries_p2024_09_01 t  (cost=0.56..1634642.69 rows=100000 width=243) (actual time=12053.808..12053.811 rows=0 loops=1)
   ->  Nested Loop  (cost=0.56..1634642.69 rows=100000 width=243) (actual time=236.140..3637.446 rows=100000 loops=1)
         ->  Subquery Scan on c  (cost=0.00..9626.69 rows=100000 width=104) (actual time=236.004..370.577 rows=100000 loops=1)
               ->  Limit  (cost=0.00..8626.69 rows=100000 width=40) (actual time=235.993..334.405 rows=100000 loops=1)
                     ->  Seq Scan on timeseries_p2024_09_01  (cost=0.00..2630111.88 rows=30488073 width=40) (actual time=0.045..89.177 rows=100000 loops=1)
                           Filter: (tenant_id IS NULL)
         ->  Index Scan using timeseries_p2024_09_01_id_idx on timeseries_p2024_09_01 t  (cost=0.56..7.79 rows=1 width=147) (actual time=0.015..0.016 rows=1 loops=100000)
               Index Cond: (id = c.id)
         SubPlan 1
           ->  Limit  (cost=0.43..8.45 rows=1 width=44) (actual time=0.016..0.016 rows=1 loops=100000)
                 ->  Index Scan Backward using usims_pkey on usims u  (cost=0.43..8.45 rows=1 width=44) (actual time=0.016..0.016 rows=1 loops=100000)
                       Index Cond: ((imsi = c.imsi) AND (datetime <= c.datetime))
 Planning Time: 1.186 ms
 JIT:
   Functions: 21
   Options: Inlining true, Optimization true, Expressions true, Deforming true
   Timing: Generation 7.595 ms, Inlining 15.107 ms, Optimization 128.686 ms, Emission 91.836 ms, Total 243.224 ms
 Execution Time: 12061.719 ms
```

E' comunque leggermente piu' lenta, ma non di molto. 

--- 

# Ultimo check

All'inizio, il problema era con la funzione a regime, quindi senza alcuna operazione da fare. Ripristino quindi il database con tutti i campi __tenant_id__ popolati

<v-click>

```sql
SELECT COUNT(*) FROM cdr.timeseries WHERE tenant_id IS NULL;

count 
-------
    0
(1 row)

-- Time: 2501.597 ms (00:02.502)
```
</v-click>

<v-click>
```sql
SELECT cdr.populate_tenant_id(10000);
-- Time: 32.993 ms
```
</v-click>

<v-click>

Come aspettato fin dall'inizio, la funzione senza alcun record da modificare e' estremamente veloce ed e' comparabile al tempo della sola `select`
</v-click>

<v-click>

Da __19 minuti__ (un'ora in produzione) a __34 millisecondi__
</v-click>

---

# Conclusioni

<v-clicks>

- Le __subquery__ nelle tabelle partizionate possono essere eccessivamente complesse
- In alcuni casi, delle condizioni ridondanti possono diminuire il carico sul database
- JIT potrebbe essere controproducente nel caso di tabelle molto partizionate
- In generale, se possibile, sarebbe meglio non lavorare mai su tabelle partizionate ma sempre sulla singola partizione
- Una buona conoscenza/dialogo del dominio e del business porta "spesso" a risultati migliori
</v-clicks>

---
layout: section
hideInToc: true
---

# Grazie per l'attenzione