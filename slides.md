---
# You can also start simply with 'default'
theme: default
# random image from a curated Unsplash collection by Anthony
# like them? see https://unsplash.com/collections/94734566/slidev
# background: /img/bug.png
# some information about your slides (markdown enabled)
title: I dolori di un giovane dev (vs PostgreSQL)
info: |
  Luca Guglielmi
  2025-01-23
# apply unocss classes to the current slide
# class: text-center
# https://sli.dev/features/drawing
drawings:
  persist: false
# slide transition: https://sli.dev/guide/animations.html#slide-transitions
transition: slide-left
# enable MDC Syntax: https://sli.dev/features/mdc
mdc: true
showLanguage: true
lineNumbers: true
# hideInToc: true
---

# I dolori di un giovane dev (vs PostgreSQL)

Luca Guglielmi

2025-05-28


---
layout: image
image: /img/bug.png
backgroundSize: contain
---

---
src: ./pages/premesse.md
---

---
layout: section
---

# La situazione

---
src: ./pages/situation.md
---

---
src: ./pages/operation.md
---

---
src: ./pages/process.md
---

---
layout: section
---

# Primo step

---
src: ./pages/analysis_1.md
---

---
src: ./pages/solution_1.md
---

---
layout: section
---

# Secondo step

---
src: ./pages/analysis_2.md
---

---
src: ./pages/solution_2_1.md
---

---
src: ./pages/solution_2_2.md
---

---
src: ./pages/solution_2_3.md
---

---
src: ./pages/til_1.md
---

---
src: ./pages/til_2.md
---

---
layout: section
---

# Terzo step

---
src: ./pages/analysis_3.md
---

---
src: ./pages/solution_3.md
---

---
layout: section
---

# Quarto step

---
src: ./pages/analysis_4.md
---

---
src: ./pages/solution_4.md
---


---
layout: section
---

# Quesiti in sospeso

---
src: ./pages/analysis_5.md
---

---
src: ./pages/solution_5.md
---

---
layout: section
---

# Test

---
src: ./pages/tests.md
---

---
layout: section
---

# Conclusioni

<v-clicks>

- Le __subquery__ nelle tabelle partizionate possono essere eccessivamente complesse
- In alcuni casi, delle condizioni ridondanti possono diminuire il carico sul database
- JIT potrebbe essere controproducente nel caso di tabelle molto partizionate
- In generale, se possibile, sarebbe meglio non lavorare mai su tabelle partizionate ma sempre sulla singola partizione
- Una buona conoscenza/dialogo del dominio e del business porta "spesso" a risultati migliori
</v-clicks>

---
layout: section
hideInToc: true
---

# Grazie per l'attenzione