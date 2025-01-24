
## Soluzione 4: disabilitare JIT

Impostiamo la funzione in maniera che disabiliti e poi ripristini __jit__

```sql
SELECT current_setting('jit') INTO previous_jit_setting;

PERFORM set_config('jit', 'false', false);

...

PERFORM set_config('jit', previous_jit_setting, false);
```

<v-click>

```sql
select cdr.populate_missing_field(10000);
-- Time: 18071.253 ms (00:18.071)
```
</v-click>
<v-click>
```sql
Planning Time: 2650.283 ms
Execution Time: 14057.573 ms
```
</v-click>
<v-click>

Siamo passati da una funzione che va in timeout ogni ora, ad una funzione di 14 secondi. 
</v-click>