### Analisi preliminari


```sql
\timing 
```

<v-click> 

A regime, non abbiamo nessun record mancante:

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
image: /img/select_with_limit.svg
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

<v-click>

Gia' qui le cose non mi tornano tantissimo: mi sarei aspettato dei tempi piu' bassi. 

Evidentemente la maggior parte del tempo di esecuzione e' dovuto allo start up del processo e non alla ricerca vera e propria. 

Ad ogni modo, resta costante rispetto al parametro `max_rows`.
</v-click>

<v-click>

Comunque il problema non e' nella select.
</v-click>

---
layout: image
image: /img/select_with_limit_half_data.svg
backgroundSize: contain
---

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