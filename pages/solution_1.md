## Soluzione 1: ottimizzazione e indici

Cominciamo con le basi e poi torniamo all'analisi. Facciamo manutenzione, creiamo tutti gli indici necessari e stimiamone i costi. 

```sql 
SELECT pg_size_pretty(pg_database_size('cdr')) AS database_size;
-- 36 GB

VACUUM FULL main_table_p2024_09_01;
-- Time: 396354.673 ms (06:36.355)

SELECT pg_size_pretty(pg_database_size('cdr')) AS database_size;
-- 16 GB

REINDEX TABLE main_table_p2024_09_01;
-- Time: 261602.583 ms (04:21.603)

SELECT pg_size_pretty(pg_database_size('cdr')) AS database_size;
-- 16 GB
```

---

Le contro indicazioni degli indici sono operazioni piu' lente in scrittura e modifica, e maggior spazio occupato sul disco

<v-click>

Sono piu' efficaci in caso di cardinalita' bassa
</v-click>

<v-click>

Avendo un'unica scrittura, un'unica modifica e una decina di operazioni di lettura con `groub_by`, lato prestazioni e' conveniente aggiungere tutti gli indici necessari
</v-click>

<v-click>

```sql
CREATE INDEX IF NOT EXISTS timeseries_missing_field_idx 
ON main_table (missing_field);

SELECT pg_size_pretty(pg_database_size('cdr')) AS database_size;
-- 16 GB

CREATE INDEX IF NOT EXISTS usims_unique_identifier_idx ON helper_table (unique_identifier);
CREATE INDEX IF NOT EXISTS usims_datetime_idx ON helper_table (missing_field);
CREATE INDEX IF NOT EXISTS usims_missing_field_idx ON helper_table (datetime);

SELECT pg_size_pretty(pg_database_size('cdr')) AS database_size;
-- 16 GB
```

</v-click>

---

Ricominciamo da capo. Ricontrollo la `sql select`:

<v-click>

```sql    
SELECT count(*) FROM main_table WHERE missing_field IS NULL LIMIT 10;
-- Time: 26.399 ms

SELECT count(*) FROM main_table ORDER BY id DESC LIMIT 100;
-- Time: 26.045 ms

SELECT count(*) FROM main_table ORDER BY id DESC LIMIT 1000;
-- Time: 27.863 ms

SELECT count(*) FROM main_table ORDER BY id DESC LIMIT 10000;
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
SELECT cdr.populate_missing_field(10);
-- Time: 5628.454 ms (00:05.628) 

SELECT cdr.populate_missing_field(20);
-- Time: 6188.688 ms (00:06.189)

SELECT cdr.populate_missing_field(50);
-- Time: 193403.525 ms (03:13.404) 

SELECT cdr.populate_missing_field(100);
-- Time: 203911.870 ms (03:23.912)
```

</v-click>

---
layout: image
image: /img/populate_missing_field.svg
backgroundSize: contain
---

---

Qui ho fatto il primo (?) errore. Nei primi test ho provato solo valori multipli di 10: 10, 100, 1000.
Probabilmente, se avessi fatto piu' punti, avrei notato una soglia critica e non l'andamento esponenziale. 
 
Ad ogni modo, la funzione ha sicuramente qualcosa che non funziona.
E' evidente che c'e' uno stacco netto tra i vari valori di `max_rows` e questa cosa non mi torna, visto che il risultato delle `select` e' sempre lo stesso (0).