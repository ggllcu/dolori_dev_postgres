
## Uso di `explain analyze`

File di circa 70k righe, generati all'interno di un container docker dentro una macchina virtuale accessibile solo via ssh. 

Ho provato con grep, ma l'unica cosa che ho notato e' che a volte __Planning Time__ ed __Execution Time__ sono simili, a volte sono completamente fuori scala.

<v-click>

E' necessario passare l'output su un file per poterlo analizzare:
</v-click>

<v-click>
```sql
\o /path/to/your/file.sql
```
</v-click>

<v-click>
```sh
docker compose cp /path/to/your/file.sql .
```
</v-click>

---

### Funzione originale

<br>

<v-click>

#### 10

```sql
Planning Time: 2885.200 ms
Execution Time: 2973.032 ms
```
</v-click>

<br>

<v-click>

#### 100

```sql
Planning Time: 2334.413 ms
JIT:
  Functions: 139493
  Options: Inlining false, Optimization false, Expressions true, Deforming true
  Timing: Generation 38582.997 ms, Inlining 0.000 ms, Optimization 10336.241 ms, Emission 162878.320 ms, Total 211797.558 ms
Execution Time: 216691.628 ms
```
</v-click>

---

### Nuova funzione (condizione ridondante)

<br>

<v-click>

#### 10
```
Planning Time: 2359.241 ms
Execution Time: 2918.323 ms
```
</v-click>

<v-click>

#### 100
```
Planning Time: 2243.924 ms
Execution Time: 3035.774 ms
```
</v-click>

<v-click>

#### 1000
```
Planning Time: 2273.605 ms
Execution Time: 4264.941 ms
```
</v-click>

<v-click>

#### 10000
```
Planning Time: 2301.638 ms
JIT:
  Functions: 139495
  Options: Inlining false, Optimization false, Expressions true, Deforming true
  Timing: Generation 32651.882 ms, Inlining 0.000 ms, Optimization 9264.750 ms, Emission 165861.856 ms, Total 207778.488 ms
Execution Time: 225298.909 ms
```
</v-click>

---

Sembra che, quando entra in funzione JIT (Just-in-Time Compilation), peggiori le cose invece di migliorarle.