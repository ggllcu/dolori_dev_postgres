
## Soluzione 5: limitare le partizioni

Limitare il numero di partizioni su cui viene eseguita la query.

```sql
SELECT DISTINCT id, tableoid::regclass FROM main_table 
where missing_field is null LIMIT 10000;
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
   FROM main_table
   LIMIT max_rows) subquery 
LOOP 
  EXECUTE format($sql$
      WITH c AS (
          SELECT id, unique_identifier, datetime
          FROM %s
          WHERE missing_field IS NULL
          LIMIT $1
      )
      UPDATE %s AS t
      SET missing_field = COALESCE(
          (
              SELECT missing_field
              FROM helper_table AS u
              WHERE u.unique_identifier = c.unique_identifier AND u.datetime <= c.datetime
              ORDER BY datetime DESC
              LIMIT 1
          ), 'Unknown'
      )
      FROM c
      WHERE c.id = t.id AND missing_field IS NULL
  $sql$, distinct_value, distinct_value) 
  USING max_rows;

END LOOP;
```

<style>
code {
  height: 100%;
}
.slidev-code-line-numbers {
      height: 100%;
}
.slidev-code{
      height: 100%;
}
</style>


---

### Explain analyze singola partizione

```sql
EXPLAIN ANALYZE WITH c AS (
                SELECT id, unique_identifier, datetime
                FROM main_table_p2024_09_01
                WHERE missing_field IS NULL
                LIMIT 10000
            )
            UPDATE main_table_p2024_09_01 AS t
            SET missing_field = COALESCE(
                (
                    SELECT missing_field
                    FROM helper_table AS u
                    WHERE u.unique_identifier = c.unique_identifier AND u.datetime <= c.datetime
                    ORDER BY datetime DESC
                    LIMIT 1
                ), 'Unknown'
            )
            FROM c
            WHERE c.id = t.id AND missing_field IS NULL;
```

--- 

```sql
Update on timeseries_p2024_09_01 t  (cost=0.56..144205.29 rows=6931 width=243) (actual time=4624.891..4624.894 rows=0 loops=1)
   ->  Nested Loop  (cost=0.56..144205.29 rows=6931 width=243) (actual time=37.199..2501.968 rows=10000 loops=1)
         ->  Subquery Scan on c  (cost=0.00..962.67 rows=10000 width=104) (actual time=36.177..58.421 rows=10000 loops=1)
               ->  Limit  (cost=0.00..862.67 rows=10000 width=40) (actual time=36.163..51.834 rows=10000 loops=1)
                     ->  Seq Scan on timeseries_p2024_09_01  (cost=0.00..2630111.88 rows=30488073 width=40) (actual time=0.336..14.819 rows=10000 loops=1)
                           Filter: (missing_field IS NULL)
         ->  Index Scan using timeseries_p2024_09_01_id_idx on timeseries_p2024_09_01 t  (cost=0.56..8.46 rows=1 width=147) (actual time=0.213..0.214 rows=1 loops=10000)
               Index Cond: (id = c.id)
               Filter: (missing_field IS NULL)
         SubPlan 1
           ->  Limit  (cost=0.43..8.45 rows=1 width=44) (actual time=0.028..0.028 rows=1 loops=10000)
                 ->  Index Scan Backward using usims_pkey on usims u  (cost=0.43..8.45 rows=1 width=44) (actual time=0.028..0.028 rows=1 loops=10000)
                       Index Cond: ((unique_identifier = c.unique_identifier) AND (datetime <= c.datetime))
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
                SELECT id, unique_identifier, datetime
                FROM main_table_p2024_09_01
                WHERE missing_field IS NULL
                LIMIT 10000
            )
            UPDATE main_table_p2024_09_01 AS t
            SET missing_field = COALESCE(
                (
                    SELECT missing_field
                    FROM helper_table AS u
                    WHERE u.unique_identifier = c.unique_identifier AND u.datetime <= c.datetime
                    ORDER BY datetime DESC
                    LIMIT 1
                ), 'Unknown'
            )
            FROM c
            WHERE c.id = t.id AND missing_field IS NULL;
```

---

```sql
Update on timeseries_p2024_09_01 t  (cost=0.56..144205.29 rows=6931 width=243) (actual time=5354.297..5354.300 rows=0 loops=1)
  ->  Nested Loop  (cost=0.56..144205.29 rows=6931 width=243) (actual time=1.315..2571.315 rows=10000 loops=1)
        ->  Subquery Scan on c  (cost=0.00..962.67 rows=10000 width=104) (actual time=0.399..24.139 rows=10000 loops=1)
              ->  Limit  (cost=0.00..862.67 rows=10000 width=40) (actual time=0.373..16.333 rows=10000 loops=1)
                    ->  Seq Scan on timeseries_p2024_09_01  (cost=0.00..2630111.88 rows=30488073 width=40) (actual time=0.370..14.640 rows=10000 loops=1)
                          Filter: (missing_field IS NULL)
        ->  Index Scan using timeseries_p2024_09_01_id_idx on timeseries_p2024_09_01 t  (cost=0.56..8.46 rows=1 width=147) (actual time=0.217..0.218 rows=1 loops=10000)
              Index Cond: (id = c.id)
              Filter: (missing_field IS NULL)
        SubPlan 1
          ->  Limit  (cost=0.43..8.45 rows=1 width=44) (actual time=0.034..0.034 rows=1 loops=10000)
                ->  Index Scan Backward using usims_pkey on usims u  (cost=0.43..8.45 rows=1 width=44) (actual time=0.034..0.034 rows=1 loops=10000)
                      Index Cond: ((unique_identifier = c.unique_identifier) AND (datetime <= c.datetime))
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

Questi tempi sono dell'intera funzione `populate_missing_field` e sono sensibilmente piu' lunghi della sola parte di update analizzata prima con la `explain analyze`. 

<v-click>

La select delle partizioni e' una funzione abbastanza lenta, ma ne vale decisamente la pena.
</v-click>

<v-click>

Ad ogni modo, per 10k record siamo passati da piu' di un'ora a 2 secondi:
__ (60 * 60) / 2 = 1800__
</v-click>

<v-click>

Ultima curiosita': provo a ritogliere la condizione inutile.
</v-click>