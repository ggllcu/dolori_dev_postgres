
## Analisi della funzione completa

Ho finito le idee. Torniamo a guardare la funzione:

```sql
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
