
## Analisi dell'`Update`

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