### Operazione

<br>

#### Tabella principale main_table

|    |     |     |     |
|--- | --- | --- | --- |
| id | unique_identifier | ... | missing_field |
| uuid() | 123456789 | ... | null |

<br>

<v-click>

#### Tabella ausiliaria helper_table

|    |     |
|--- | --- |
|unique_identifier | missing_field |
| 123456789 | abc |

</v-click>

---

#### Stored procedure

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