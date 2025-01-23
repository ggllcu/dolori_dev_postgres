
## Soluzione 2.2: usare una view

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
