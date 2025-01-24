
## Soluzione 2.3: no limits

In teoria, la funzione e' sufficentemente veloce da poter elaborare tutti i dati di un'unica giornata senza scadere nel timeout. 

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
WHERE t.missing_field IS NULL;
```
</v-click>

---

Tuttavia, per come e' strutturato PostgreSQL e con questo database, questo non e' possibile. Quello che fa PostgreSQL, infatti, non e' modificare le righe una ad una, ma aggiungere le righe nuove in un file temporaneo e, a fine operazione, in caso di successo, cancellare di colpo tutte le righe e inserire quelle nuove. Questo serve a garantire l'integrita' del database.

<v-click>

Non potendo ipotizzare alcuna correttezza dei dati, nel caso peggiore (tutti i record con il campo mancante o una giornata con x10 di dati) lo spazio sul disco si esaurisce e muore tutto.
</v-click>

<v-click>

Inoltre, manda in lock tutta la tabella e blocca tutte le altre operazioni che devono essere fatte in giornata, per cui non e' una soluzione accettabile.
</v-click>
