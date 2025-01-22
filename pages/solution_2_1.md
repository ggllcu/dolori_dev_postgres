
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