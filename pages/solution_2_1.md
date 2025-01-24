
## Soluzione 2.1: eliminare la subquery

Se il problema e' usando il `with`, ho provato ad aggiungere il limite alla where cosi' da togliermi il problema della __subquery__. 

<v-click>
```sql
UPDATE main_table AS t
SET missing_field = coalesce(
                           (SELECT missing_field
                            FROM helper_table AS u
                            WHERE u.unique_identifier = c.unique_identifier
                              AND u.datetime <= c.datetime
                            ORDER BY datetime DESC
                            LIMIT 1) , 'Unknown')
WHERE t.missing_field IS NULL
LIMIT 10000;
```
</v-click>

<v-click>

Questa cosa cosa non e' possibile in PostgreSQL.
</v-click>