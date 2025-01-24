
## Analisi dell'`Update`

Visto che non ho nessun record in cui ho `missing_field is null`, ho provato a lanciare l'update senza limit, modificando io alcune righe. Ho usato un `order by id` perche', essendo l'id un `uuid`, speravo di avere dei dati uniformemente distribuiti sulle varie partizioni.

<v-click>

```sql
UPDATE main_table
SET missing_field = NULL
FROM
  (SELECT id
   FROM main_table
   ORDER BY id DESC
   LIMIT 10000) AS subquery
WHERE main_table.id = subquery.id;

-- Time: 31978.936 ms (00:31.979) 
```

</v-click>

<v-click>

Che comunque e' veloce.
</v-click>

---

A questo punto, ho provato a fare l'update di 10000 record. A livello teorico, non mi aspetto grosse differenze dalla `select populate_missing_field(10000);`. 

<v-click>
```sql
UPDATE main_table AS t
SET missing_field = coalesce(
                           (SELECT missing_field
                            FROM helper_table AS u
                            WHERE u.unique_identifier = t.unique_identifier
                              AND u.datetime <= t.datetime
                            ORDER BY datetime DESC
                            LIMIT 1) , 'Unknown')
WHERE t.missing_field IS NULL;
-- Time: 3043.877 ms (00:03.044)
```
</v-click>

<v-click>

E invece, e' velocissima. Insomma, la `select` non e' un problema, l'`update` non e' un problema -> deve esserci qualcosa che non va nell'uso della __subquery__ con `with`.
</v-click>