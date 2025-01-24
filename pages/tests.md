
## Con condizione

```sql
EXPLAIN ANALYZE WITH c AS (
                SELECT id, unique_identifier, datetime
                FROM main_table_p2024_09_01
                WHERE missing_field IS NULL
                LIMIT 100000
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
            WHERE c.id = t.id and missing_field is null;
```

---

```sql
Update on timeseries_p2024_09_01 t  (cost=0.56..1375388.92 rows=69310 width=243) (actual time=10669.294..10669.296 rows=0 loops=1)
  ->  Nested Loop  (cost=0.56..1375388.92 rows=69310 width=243) (actual time=283.311..2948.045 rows=100000 loops=1)
        ->  Subquery Scan on c  (cost=0.00..9626.69 rows=100000 width=104) (actual time=283.221..406.978 rows=100000 loops=1)
              ->  Limit  (cost=0.00..8626.69 rows=100000 width=40) (actual time=283.215..372.071 rows=100000 loops=1)
                    ->  Seq Scan on timeseries_p2024_09_01  (cost=0.00..2630111.88 rows=30488073 width=40) (actual time=0.094..80.248 rows=100000 loops=1)
                          Filter: (missing_field IS NULL)
        ->  Index Scan using timeseries_p2024_09_01_id_idx on timeseries_p2024_09_01 t  (cost=0.56..7.79 rows=1 width=147) (actual time=0.011..0.012 rows=1 loops=100000)
              Index Cond: (id = c.id)
              Filter: (missing_field IS NULL)
        SubPlan 1
          ->  Limit  (cost=0.43..8.45 rows=1 width=44) (actual time=0.013..0.013 rows=1 loops=100000)
                ->  Index Scan Backward using usims_pkey on usims u  (cost=0.43..8.45 rows=1 width=44) (actual time=0.012..0.012 rows=1 loops=100000)
                      Index Cond: ((unique_identifier = c.unique_identifier) AND (datetime <= c.datetime))
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
                SELECT id, unique_identifier, datetime
                FROM main_table_p2024_09_01
                WHERE missing_field IS NULL
                LIMIT 100000
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
            WHERE c.id = t.id;
```

---

```sql
 Update on timeseries_p2024_09_01 t  (cost=0.56..1634642.69 rows=100000 width=243) (actual time=12053.808..12053.811 rows=0 loops=1)
   ->  Nested Loop  (cost=0.56..1634642.69 rows=100000 width=243) (actual time=236.140..3637.446 rows=100000 loops=1)
         ->  Subquery Scan on c  (cost=0.00..9626.69 rows=100000 width=104) (actual time=236.004..370.577 rows=100000 loops=1)
               ->  Limit  (cost=0.00..8626.69 rows=100000 width=40) (actual time=235.993..334.405 rows=100000 loops=1)
                     ->  Seq Scan on timeseries_p2024_09_01  (cost=0.00..2630111.88 rows=30488073 width=40) (actual time=0.045..89.177 rows=100000 loops=1)
                           Filter: (missing_field IS NULL)
         ->  Index Scan using timeseries_p2024_09_01_id_idx on timeseries_p2024_09_01 t  (cost=0.56..7.79 rows=1 width=147) (actual time=0.015..0.016 rows=1 loops=100000)
               Index Cond: (id = c.id)
         SubPlan 1
           ->  Limit  (cost=0.43..8.45 rows=1 width=44) (actual time=0.016..0.016 rows=1 loops=100000)
                 ->  Index Scan Backward using usims_pkey on usims u  (cost=0.43..8.45 rows=1 width=44) (actual time=0.016..0.016 rows=1 loops=100000)
                       Index Cond: ((unique_identifier = c.unique_identifier) AND (datetime <= c.datetime))
 Planning Time: 1.186 ms
 JIT:
   Functions: 21
   Options: Inlining true, Optimization true, Expressions true, Deforming true
   Timing: Generation 7.595 ms, Inlining 15.107 ms, Optimization 128.686 ms, Emission 91.836 ms, Total 243.224 ms
 Execution Time: 12061.719 ms
```

E' comunque leggermente piu' lenta, ma non di molto. 

--- 

## Ultimo check

All'inizio, il problema era con la funzione a regime, quindi senza alcuna operazione da fare. Ripristino quindi il database con tutti i campi __missing_field__ popolati

<v-click>

```sql
SELECT COUNT(*) FROM main_table WHERE missing_field IS NULL;

count 
-------
    0
(1 row)

-- Time: 2501.597 ms (00:02.502)
```
</v-click>

<v-click>
```sql
SELECT cdr.populate_missing_field(10000);
-- Time: 32.993 ms
```
</v-click>

<v-click>

Come aspettato fin dall'inizio, la funzione senza alcun record da modificare e' estremamente veloce ed e' comparabile al tempo della sola `select`
</v-click>

<v-click>

Da __19 minuti__ (un'ora in produzione) a __34 millisecondi__
</v-click>
