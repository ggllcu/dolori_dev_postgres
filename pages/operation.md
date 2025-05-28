## Operazione

<br>

### Tabella principale main_table

|    |     |     |     |
|--- | --- | --- | --- |
| id | unique_identifier | ... | missing_field |
| uuid() | 123456789 | ... | null |

<br>

<v-click>

### Tabella ausiliaria helper_table

|   |   |   |
|---|---|---|
|unique_identifier | missing_field | datetime |
| 123456789 | abc | 2025-01-23 |

</v-click>

---

### Stored procedure

```sql{all|2-7|10-15|8-9,16-17}
WITH c AS
  (SELECT id,
          unique_identifier,
          datetime
   FROM main_table
   WHERE missing_field IS NULL
   LIMIT max_rows)
UPDATE main_table AS t
SET missing_field = coalesce(
                           (SELECT missing_field
                            FROM helper_table AS u
                            WHERE u.unique_identifier = c.unique_identifier
                              AND u.datetime <= c.datetime
                            ORDER BY datetime DESC
                            LIMIT 1) , 'Unknown')
FROM c
WHERE t.id = c.id;
```