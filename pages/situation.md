## Database

<v-click>

- una tabella con 180 partizioni, una per ogni giorno
- ~ 40 milioni di record per giorno inseriti giornalmente
- nessuna garanzia sui dati
- alcuni giorni possono arrivare x10 dati
- necessita' di poter operare su dei vecchi record
- un ambiente di pre prod ridotto con circa 1/3 dei dati
- un ambiente di test con solo due giorni di dati fatti tramite restore
</v-click>