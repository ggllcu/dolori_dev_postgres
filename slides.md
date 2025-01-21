---
# You can also start simply with 'default'
theme: default
# random image from a curated Unsplash collection by Anthony
# like them? see https://unsplash.com/collections/94734566/slidev
# background: ./img/bug.png
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
---

# I dolori di un giovane dev (vs PostgreSQL)

Luca Guglielmi

2025-01-24


---
layout: image
image: ./img/bug.png
backgroundSize: contain
---

---

<Toc text-sm minDepth="1" maxDepth="3" />

---
layout: section
---

## La situazione

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

## Prima analisi: preliminari

---

A regime, non abbiamo nessun record mancante:

```sql
\timing 
```

<br>

<v-click>

```sql
select count(*) from main_table where missing_fiels is null;

-- tenant_id 
-----------
-- (0 rows)

-- Time: 503.225 ms
```

</v-click>

---

In maniera abbastanza intuibile, a regime la `sql select` non dipende dal parametro `max_rows`.

```sql    
SELECT count(*) FROM cdr.timeseries WHERE tenant_id IS NULL LIMIT 10;
-- Time: 8400.916 ms (00:08.401) // Prima volta

SELECT count(*) FROM cdr.timeseries WHERE tenant_id IS NULL LIMIT 10;
-- Time: 1371.396 ms (00:01.371) // Seconda volta

SELECT count(*) FROM cdr.timeseries ORDER BY id DESC LIMIT 100;
-- Time: 1448.198 ms (00:01.448)

SELECT count(*) FROM cdr.timeseries ORDER BY id DESC LIMIT 1000;
-- Time: 1357.622 ms (00:01.358)
```

---
layout: image
image: ./img/select_with_limit.svg
backgroundSize: contain
---

---

Tuttavia, la `populate_missing_field` e' davvero troppo lenta per ogni possibile test. 

<v-click>

```sql
SELECT cdr.populate_tenant_id(10);
-- Time: 2165909.072 ms (36:05.909)
```

</v-click>
<v-click>

Dimezzo i dati. Ho deciso di tenere comunque i dati di prima per valutare come scalano in base al numero di dati le funzioni precedenti.

</v-click>
<v-click>

```sql
DELETE FROM cdr.timeseries WHERE datetime < '2024-08-15 00:00:00';
```

```sql
SELECT COUNT(*) FROM cdr.timeseries;
-- 43987988
-- Time: 92053.222 ms (01:32.053)
```

</v-click>

---

Ricontrollo la `sql select`:

<v-click>

```sql    
SELECT count(*) FROM cdr.timeseries WHERE tenant_id IS NULL LIMIT 10;
-- Time: 7970.138 ms (00:07.970) // Prima volta

SELECT count(*) FROM cdr.timeseries WHERE tenant_id IS NULL LIMIT 10;
-- Time: 1419.836 ms (00:01.420) // Seconda volta

SELECT count(*) FROM cdr.timeseries ORDER BY id DESC LIMIT 100;
-- Time: 1399.470 ms (00:01.399)

SELECT count(*) FROM cdr.timeseries ORDER BY id DESC LIMIT 1000;
-- Time: 2259.829 ms (00:02.260)

SELECT count(*) FROM cdr.timeseries ORDER BY id DESC LIMIT 10000;
-- Time: 1393.022 ms (00:01.393)
```

</v-click>

---
layout: image
image: ./img/select_with_limit_half_data.svg
backgroundSize: contain
---

---

Gia' qui le cose non mi tornano tantissimo: mi sarei aspettato dei tempi piu' bassi. 

Evidentemente la maggior parte del tempo di esecuzione e' dovuto allo start up del processo e non alla ricerca vera e propria. 

Ad ogni modo, resta costante rispetto al parametro `max_rows`.

---

Torniamo alla funzione `populate_missing_field`.

<v-click>

```sql    
SELECT cdr.populate_tenant_id(10);
-- Time: dai 3 ai 5 minuti, dipende dai test 
```

</v-click>
<v-click>

Impossibile lavorare con questi valori, occorre fare qualcosa.

</v-click>

---

### Soluzione 1: ottimizzazione e indici

Cominciamo con le basi e poi torniamo all'analisi. Facciamo manutenzione, creiamo tutti gli indici necessari e stimiamone i costi. 

```sql 
SELECT pg_size_pretty(pg_database_size('cdr')) AS database_size;
-- 36 GB

VACUUM FULL cdr.timeseries_p2024_09_01;
-- Time: 396354.673 ms (06:36.355)

SELECT pg_size_pretty(pg_database_size('cdr')) AS database_size;
-- 16 GB

REINDEX TABLE cdr.timeseries_p2024_09_01;
-- Time: 261602.583 ms (04:21.603)

SELECT pg_size_pretty(pg_database_size('cdr')) AS database_size;
-- 16 GB
```

---

Avendo un'unica scrittura, un'unica modifica e una decina di operazioni di lettura con `groub_by`, lato prestazioni e' conveniente aggiungere un indice. 

<v-click>

```sql
CREATE INDEX IF NOT EXISTS timeseries_tenant_id_idx 
ON cdr.timeseries (tenant_id);

SELECT pg_size_pretty(pg_database_size('cdr')) AS database_size;
-- 16 GB

CREATE INDEX IF NOT EXISTS usims_imsi_idx ON cdr.usims (imsi);
CREATE INDEX IF NOT EXISTS usims_datetime_idx ON cdr.usims (tenant_id);
CREATE INDEX IF NOT EXISTS usims_tenant_id_idx ON cdr.usims (datetime);

SELECT pg_size_pretty(pg_database_size('cdr')) AS database_size;
-- 16 GB
```

</v-click>

---

Ricominciamo da capo. Ricontrollo la `sql select`:

<v-click>

```sql    
SELECT count(*) FROM cdr.timeseries WHERE tenant_id IS NULL LIMIT 10;
-- Time: 26.399 ms

SELECT count(*) FROM cdr.timeseries ORDER BY id DESC LIMIT 100;
-- Time: 26.045 ms

SELECT count(*) FROM cdr.timeseries ORDER BY id DESC LIMIT 1000;
-- Time: 27.863 ms

SELECT count(*) FROM cdr.timeseries ORDER BY id DESC LIMIT 10000;
-- Time: 25.469 ms
```

</v-click>

<v-click>

Molto meglio (x200) e sempre costante.

</v-click>

---

Torniamo alla funzione `populate_missing_field`.

<v-click>

```sql    
SELECT cdr.populate_tenant_id(10);
-- Time: 5628.454 ms (00:05.628) 

SELECT cdr.populate_tenant_id(20);
-- Time: 6188.688 ms (00:06.189)

SELECT cdr.populate_tenant_id(50);
-- Time: 193403.525 ms (03:13.404) 

SELECT cdr.populate_tenant_id(100);
-- Time: 203911.870 ms (03:23.912)
```

</v-click>

---
layout: image
image: ./img/populate_tenant_id.svg
backgroundSize: contain
---

---

Qui ho fatto il primo (?) errore. Nei primi test ho provato solo valori multipli di 10: 10, 100, 1000.
Probabilmente, se avessi fatto piu' punti, avrei notato una soglia critica e non l'andamento esponenziale. 
 
Ad ogni modo, la funzione ha sicuramente qualcosa che non funziona.
E' evidente che c'e' uno stacco netto tra i vari valori di `max_rows` e questa cosa non mi torna, visto che il risultato delle `select` e' sempre lo stesso.

---

## Seconda analisi: operazione principale

Visto che non ho nessun record in cui ho `tenant_id is null`, ho provato a lanciare l'update senza limit, modificando io alcune righe. Ho usato un `order by id` perche', essendo l'id un `uuid`, speravo di avere dei dati uniformemente distribuiti sulle varie partizioni.

<v-click>

```sql
UPDATE cdr.timeseries
SET tenant_id = NULL
FROM
  (SELECT id
   FROM cdr.timeseries
   ORDER BY id DESC
   LIMIT 10000) AS subquery
WHERE cdr.timeseries.id = subquery.id;

-- Time: 31978.936 ms (00:31.979) 
```

</v-click>

<v-click>

Che comunque e' veloce.
</v-click>

---

A questo punto, ho provato a fare l'update di 10000 record. A livello teorico, non mi aspetto grosse differenze dalla `sql select populate_missing_field(10000);`. 

<v-click>
```sql
UPDATE cdr.timeseries AS t
SET tenant_id = coalesce(
                           (SELECT tenant_id
                            FROM cdr.usims AS u
                            WHERE u.imsi = t.imsi
                              AND u.datetime <= t.datetime
                            ORDER BY datetime DESC
                            LIMIT 1) , 'Unknown')
WHERE t.tenant_id IS NULL;
-- Time: 3043.877 ms (00:03.044)
```
</v-click>

<v-click>

E invece, e' velocissima. Insomma, la `select` non e' un problema, l'`update` non e' un problema -> deve esserci qualcosa che non va nell'uso della __subquery__ con `with`.
</v-click>

---

### Soluzione 2.1: eliminare la subquery

Se il problema e' usando il `with`, ho provato ad aggiungere il limite alla where cosi' da togliermi il problema della __subquery__. 

<v-click>
```sql
UPDATE cdr.timeseries AS t
SET tenant_id = coalesce(
                           (SELECT tenant_id
                            FROM cdr.usims AS u
                            WHERE u.imsi = c.imsi
                              AND u.datetime <= c.datetime
                            ORDER BY datetime DESC
                            LIMIT 1) , 'Unknown')
WHERE t.tenant_id IS NULL
LIMIT 10000;
```
</v-click>

<v-click>

Questa cosa cosa non e' possibile in PostgreSQL.
</v-click>

---

### Soluzione 2.2: usare una view

Ho provato a creare una view con un numero limitato di records: le view sono updateble e le posso passare all'update senza bisogno di `limit`.

<v-click>
```sql
CREATE VIEW cdr.first_null_tenants AS
SELECT id, imsi, tenant_id, datetime
FROM cdr.timeseries
WHERE tenant_id is null limit 10000;
```
</v-click>

<v-click>
```sql
UPDATE cdr.first_null_tenants AS t
SET tenant_id = coalesce(
                           (SELECT tenant_id
                            FROM cdr.usims AS u
                            WHERE u.imsi = c.imsi
                              AND u.datetime <= c.datetime
                            ORDER BY datetime DESC
                            LIMIT 1) , 'Unknown')
WHERE t.tenant_id IS NULL;
```
</v-click>

---

Ovviamente non funziona: le view sono updateble in generale, ma non se sono create con un limit, l'update sulla view fallisce.

Questo e' il motivo per cui la __with__ e' necessaria.

<v-click>
```sql
DROP VIEW cdr.first_null_tenants;
```
</v-click>

---

### Soluzione 2.3: no limits

In teoria, la funzione e' sufficentemente veloce da poter elaborare tutti i dati di un'unica giornata senza scadere nel timeout. 

<v-click>
```sql
UPDATE cdr.timeseries AS t
SET tenant_id = coalesce(
                           (SELECT tenant_id
                            FROM cdr.usims AS u
                            WHERE u.imsi = c.imsi
                              AND u.datetime <= c.datetime
                            ORDER BY datetime DESC
                            LIMIT 1) , 'Unknown')
WHERE t.tenant_id IS NULL;
```
</v-click>

---

Tuttavia, per come e' strutturato postgres e con questo database, questo non e' possibile. Quello che fa postgres, infatti, non e' modificare le righe una ad una, ma aggiungere le righe nuove in un file temporaneo e, a fine operazione, in caso di successo, cancellare di colpo tutte le righe e inserire quelle nuove. Questo serve a garantire l'integrita' del database. 

Non potendo ipotizzare alcuna correttezza dei dati, nel caso peggiore (tutti i record con il campo mancante o una giornata con x10 di dati) lo spazio sul disco si esaurisce e muore tutto.

Inoltre, manda in lock tutta la tabella e blocca tutte le altre operazioni che devono essere fatte in giornata, per cui non e' una soluzione accettabile.

---

### TIL 1

Postgres garantisce l'integrita' per i __single statement__ di default. La struttura:

```sql 
BEGIN
...
update 1;
...
update 2;
...
COMMIT
```

serve per garantire l'integrita' di business in caso di __multiple statement__, come nel caso di piu' update in contemporanea. 

---

### TIL 2

Postgres utilizza una funzione __autovacuum__ per pulire il db dopo alcune operazioni. Questa funzione, nel mio caso, impiegava fino ad un'ora circa. Non me ne ero accorto, e inizialmente questa cosa mi sballava parecchio i test. 

Se fate test intensivi sul db, controllate con un __htop__ o direttamente da __psql__ che non ci siano operazioni di manutenzione di postgres in backgroup perche' vi falserebbero i risultati.

```sql
SELECT * FROM pg_stat_activity WHERE state = 'active';

``` 

---

## Terza analisi: condizioni ridondanti

Ho finito le idee. Torniamo a guardare la funzione:

```sql
WITH c AS
  (SELECT id,
          imsi,
          datetime
   FROM cdr.timeseries
   WHERE tenant_id IS NULL
   LIMIT max_cdr_to_process)
UPDATE cdr.timeseries AS t
SET tenant_id = coalesce(
                           (SELECT tenant_id
                            FROM cdr.usims AS u
                            WHERE u.imsi = c.imsi
                              AND u.datetime <= c.datetime
                            ORDER BY datetime DESC
                            LIMIT 1) , 'Unknown')
FROM c
WHERE t.id = c.id;
```

---

### Soluzione 3: condizione ridondante

E se la facessi cosi' (ma non so perche')?

````md magic-move {lines: true}
```sql
WITH c AS
  (SELECT id,
          imsi,
          datetime
   FROM cdr.timeseries
   WHERE tenant_id IS NULL
   LIMIT max_cdr_to_process)
UPDATE cdr.timeseries AS t
SET tenant_id = coalesce(
                           (SELECT tenant_id
                            FROM cdr.usims AS u
                            WHERE u.imsi = c.imsi
                              AND u.datetime <= c.datetime
                            ORDER BY datetime DESC
                            LIMIT 1) , 'Unknown')
FROM c
WHERE c.id = t.id;
```

```sql{17-18}
WITH c AS
  (SELECT id,
          imsi,
          datetime
   FROM cdr.timeseries
   WHERE tenant_id IS NULL
   LIMIT max_cdr_to_process)
UPDATE cdr.timeseries AS t
SET tenant_id = coalesce(
                           (SELECT tenant_id
                            FROM cdr.usims AS u
                            WHERE u.imsi = c.imsi
                              AND u.datetime <= c.datetime
                            ORDER BY datetime DESC
                            LIMIT 1) , 'Unknown')
FROM c
WHERE c.id = t.id
  AND tenant_id IS NULL;
```
````

---

Impostiamo il campo come null su tutte le righe:

```sql    
UPDATE cdr.timeseries SET tenant_id = null;
-- Time: 5160102.544 ms (01:26:00.103)
```

---

Torniamo alla funzione `populate_missing_field`. 

````md magic-move
```sql    
SELECT cdr.populate_tenant_id(10);
-- Time: 6123.360 ms (00:06.123)
```

```sql    
SELECT cdr.populate_tenant_id(10);
-- Time: 6123.360 ms (00:06.123)

SELECT cdr.populate_tenant_id(20);
-- Time: 6392.647 ms (00:06.393)
```

```sql    
SELECT cdr.populate_tenant_id(10);
-- Time: 6123.360 ms (00:06.123)

SELECT cdr.populate_tenant_id(20);
-- Time: 6392.647 ms (00:06.393)

SELECT cdr.populate_tenant_id(50);
-- Time: 5869.910 ms (00:05.870)
```

```sql    
SELECT cdr.populate_tenant_id(10);
-- Time: 6123.360 ms (00:06.123)

SELECT cdr.populate_tenant_id(20);
-- Time: 6392.647 ms (00:06.393)

SELECT cdr.populate_tenant_id(50);
-- Time: 5869.910 ms (00:05.870)

SELECT cdr.populate_tenant_id(100);
-- Time: 5929.555 ms (00:05.930)
```

```sql    
SELECT cdr.populate_tenant_id(10);
-- Time: 6123.360 ms (00:06.123)

SELECT cdr.populate_tenant_id(20);
-- Time: 6392.647 ms (00:06.393)

SELECT cdr.populate_tenant_id(50);
-- Time: 5869.910 ms (00:05.870)

SELECT cdr.populate_tenant_id(100);
-- Time: 5929.555 ms (00:05.930)

SELECT cdr.populate_tenant_id(1000);
-- Time: 7175.841 ms (00:07.176)
```

```sql    
SELECT cdr.populate_tenant_id(10);
-- Time: 6123.360 ms (00:06.123)

SELECT cdr.populate_tenant_id(20);
-- Time: 6392.647 ms (00:06.393)

SELECT cdr.populate_tenant_id(50);
-- Time: 5869.910 ms (00:05.870)

SELECT cdr.populate_tenant_id(100);
-- Time: 5929.555 ms (00:05.930)

SELECT cdr.populate_tenant_id(1000);
-- Time: 7175.841 ms (00:07.176)

SELECT cdr.populate_tenant_id(10000);
-- Time: 242200.066 ms (04:02.200)
```
````

---
layout: image
image: ./img/populate_tenant_id_double_condition.svg
backgroundSize: contain
---

---

## Quarta Analisi: explain analyze


File di circa 70k righe, generati all'interno di un container docker accessibile solo via ssh. 

Ho provato con grep, ma l'unica cosa che ho notato e' che a volte __Planning Time__ ed __Execution Time__ sono simili, a volte sono completamente fuori scala.

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

### Funzione originale

<br>

<v-click>

#### 10

```sql
Planning Time: 2885.200 ms
Execution Time: 2973.032 ms
```
</v-click>

<br>

<v-click>

#### 100

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

### Nuova funzione (condizione ridondante)

<br>

<v-click>

#### 10
```
Planning Time: 2359.241 ms
Execution Time: 2918.323 ms
```
</v-click>

<v-click>

#### 100
```
Planning Time: 2243.924 ms
Execution Time: 3035.774 ms
```
</v-click>

<v-click>

#### 1000
```
Planning Time: 2273.605 ms
Execution Time: 4264.941 ms
```
</v-click>

<v-click>

#### 10000
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

<v-click>

Sembra che, quando entra in funzione JIT (Just-in-Time Compilation), peggiori le cose invece di migliorarle.
</v-click>

---

### Soluzione 4: disabilitare JIT

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

## Quesiti in sospeso

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

### Funzione originale

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

### Nuova funzione

<br>

#### Total cost

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
image: ./img/total_cost.svg
backgroundSize: contain
---

---

#### Hash join

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

### Soluzione 5: limitare le partizioni

Limitare il numero di partizioni su cui viene eseguita la query.

```sql
SELECT DISTINCT id, tableoid::regclass FROM cdr.timeseries 
where tenant_id is null LIMIT 10000;
```

<v-click>

Questa non funziona perche' il limite e' sui valori univoci. Serve anche qui una subquery.
</v-click>

---


```sql{all|9-26}
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

### Explain analyze singola partizione

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
image: ./img/jit_vs_no_jit.svg
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

### Con condizione

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

### Senza condizione 

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

## Ultimo check

All'inizio, il problema era con la funzione a regime, quindi senza alcuna operazione da fare. Ripristino quindi il database con tutti i campi __tenant_id__ popolati.

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

Come aspettato fin dall'inizio, la funzione senza alcun record da modificare e' estremamente veloce ed e' comparabile al tempo della sola `select`.
</v-click>

---

## Conclusioni

<v-clicks>

- Le __subquery__ nelle tabelle partizionate possono essere eccessivamente complesse
- In alcuni casi, delle condizioni ridondanti possono diminuire il carico sul database
- JIT potrebbe essere controproducente nel caso di tabelle molto partizionate
- In generale, se possibile, sarebbe meglio non lavorare mai su tabelle partizionate ma sempre sulla singola partizione
</v-clicks>

---
layout: section
---

## Grazie per l'attenzione