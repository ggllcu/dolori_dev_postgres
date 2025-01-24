
## Soluzione 2.2: usare una view

Ho provato a creare una view con un numero limitato di records: le view sono updateble e le posso passare all'update senza bisogno di `limit`.

<v-click>
```sql
CREATE VIEW first_null_tenants AS
SELECT id, unique_identifier, missing_field, datetime
FROM main_table
WHERE missing_field is null limit 10000;
```
</v-click>

<v-click>
```sql
UPDATE first_null_tenants AS t
SET missing_field = coalesce(
                           (SELECT missing_field
                            FROM helper_table AS u
                            WHERE u.unique_identifier = c.unique_identifier
                              AND u.datetime <= c.datetime
                            ORDER BY datetime DESC
                            LIMIT 1) , 'Unknown')
WHERE t.missing_field IS NULL;
```
</v-click>

---

Ovviamente non funziona: le view sono updateble in generale, ma non se sono create con un limit, l'update sulla view fallisce.

Questo e' il motivo per cui la __with__ e' necessaria.

<v-click>
```sql
DROP VIEW first_null_tenants;
```
</v-click>
