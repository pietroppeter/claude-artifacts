## Translation notes for the Italian version of "Localizing nimib pages", written by Claude. Building it
## writes it.po from messages.pot (which index.nim writes); then build index.nim again. See README.md.
## Every message is given by its key: the English is in the template, and the page shows it.
import std/os
import nimib except md
import tabelline, tabelline/nimib
import lingua, page, notes, review

const srcDir = currentSourcePath().parentDir

nbInit
nb.doc.filename = srcDir.parentDir / "notes-it.html"
nb.usePage("Translation notes: Italian",
           "How the page Localizing nimib pages was translated into Italian: conventions, glossary, choices, and every message beside its English.")
nb.useLingua(["en"], ["English"])
nb.useNotes("it")
nbReview(tversion = 1, tpage = "nimib-localization/notes-it", tsource = "nimib-localization/src/it.nim")

nbTitle "12 November 2026 · for [Localizing nimib pages](index.html)",
  "Translation notes: Italian",
  """
How the page [Localizing nimib pages](index.html) was put into Italian, by Claude: the
conventions that hold for the whole translation, the words chosen for its terms, the messages
it could translate in more than one way, and every message beside its English. This page is
also what writes the Italian catalog, `it.po`: reviewing the translation is reviewing this page.
"""
nbVersion 1, "12 November 2026"

nbToc

nbText """
## How to review

Read the Italian column, and comment in the review mode (**✎ Review**) on anything that is
wrong, stiff, or could be said better. A comment on a convention or on a word of the glossary
is applied everywhere it holds. Where Claude saw more than one good translation, the message
is a *choice*: the options are lettered, A is the one used, and to pick another select it and
say so. When a round of comments is applied, the messages nobody commented on count as
reviewed, and the catalog stops marking them `machine`.
"""

nbText """
## Conventions

- **Register.** Plain and impersonal, as the English is: no *tu* and no *voi*. The reader is
  *chi legge*, not *il lettore*, so that no noun has a gender.
- **Sentence by sentence.** Each message follows its English sentence by sentence, so it can be
  checked against it, but in Italian word order; nothing is added or left out.
- **What stays in English.** Names of tools and libraries, everything in `code`, file names,
  `msgid` and `msgstr`, and two words Italian programmers use as they are: *output* and
  *build* (*la build*). *Artifact* stays too.
- **Headings.** Capitalized as sentences, as in the English. A heading is two messages, the
  heading and its line in the contents: they say the same.
- **Typography.** The straight apostrophe of the source (`'`), accented letters as Italian
  writes them (*è*, *perché*), and numbers in prose as the English has them: they are examples
  of both conventions.
- **Markdown and links.** As in the English: the same marks and the same addresses, even where
  the page linked is in English only.
"""

nbText """
## Glossary

The terms of the page, and the Italian used for each everywhere.
"""

type Term = tuple[english, italian, notThis, why: string]
let glossary: seq[Term] = @[
  ("chunk", "pezzo", "frammento, blocco", "*Blocco* is already nimib's word for a block; *pezzo* is plain."),
  ("message", "messaggio", "stringa", "gettext's own word, in its Italian manual too."),
  ("catalog", "catalogo", "", "As gettext says it."),
  ("template (`.pot`)", "modello", "template", "Plain Italian; the file name says the rest."),
  ("key", "chiave", "", ""),
  ("switch (of languages)", "selettore", "interruttore", "It picks one of several, it does not turn on and off."),
  ("build (a page)", "costruire; *la build*", "generare, compilare", "The verb in prose, the noun as programmers say it."),
  ("output", "output", "uscita, risultato", "As Italian programmers say it."),
  ("locale", "locale (feminine)", "impostazioni locali", "The word of CLDR's Italian users, *la locale*."),
  ("review mode", "modalità revisione", "modalità di revisione", "Shorter, like a name."),
  ("heading", "titolo", "intestazione", "*Intestazione* is the header of the page."),
  ("header (of the page)", "intestazione", "testata", ""),
  ("reader", "chi legge", "lettore", "No gender."),
  ("tool", "strumento", "tool", "")]
nbTable glossary:
  tabHeader "Glossary"
  colsLabel:
    english: "English"
    italian: "Italian"
    notThis: "Not this"
    why: "Why"
  fmtMarkdown ["english", "italian", "why"]
  optCssTheme()

nbText """
## Choices

The messages Claude could translate in more than one way. They are also in their place among
the messages below; here they are together, for a quicker look.
"""

nbChoice "1db5d6", ["Superficie", "Area"],
  "*Superficie* is what an Italian atlas writes for the size of an island; *area* is understood but sounds translated."

nbChoice "f86729", ["nimib, in più di una lingua", "nimib, in più lingue"],
  "A follows the English; B is shorter and says the same. The header has room for either."

nbChoice "323698", ["Pagine nimib in più lingue", "Localizzare le pagine nimib", "Tradurre le pagine nimib"],
  "*Localizzare* is the trade's word, but outside it an Italian reader hears little in it; A says what the page is about. It is also the title of the browser tab only in English: the `<title>` is not translated yet."

nbChoice "49930b", ["Da Claude", "Tradotti da Claude", "Di Claude"],
  "A column header must be short, and it stands after *Tradotti*, which it reads with. B is clearer on its own but makes the column the widest of the table on a phone."

nbChoice "197da8", ["## Gli output nella lingua di chi legge", "## L'output nella lingua del lettore"],
  "*Chi legge* avoids a noun with a gender, as everywhere here; *output* stays English, as Italian programmers say it, and plural to match the English."

nbChoice "6a09b7", ["## Come è fatto", "## Com'è costruito", "## Come funziona dentro"],
  "A is how Italian says it of a thing; B is closer to *built*; C says what the section does, but no other page uses it. The contents (*How it is built*, without `##`) take the same words."

nbText """
## The messages

Every message of the page, in its order, the English on the left (above, on a phone), the
Italian on the right. The small code beside each is its key.
"""

nbText "### The table of tools (words from the code)"

nbMsg "96d946", "Messaggi nel codice"

nbMsg "228222", "un messaggio: una stringa del programma"

nbMsg "dc7ba4", "un file PO per lingua"

nbMsg "27ee71", "il programma sceglie la lingua quando gira; ogni strumento di traduzione legge il PO"

nbMsg "29cba3", "un messaggio con un id, con plurali e generi scritti da chi traduce"

nbMsg "019462", "un file FTL per lingua"

nbMsg "b4c88b", "una traduzione può avere varianti che l'originale non ha (Firefox di Mozilla)"

nbMsg "8153cb", "un messaggio con segnaposto e varianti"

nbMsg "e985e1", "dove il programma li tiene"

nbMsg "640070", "uno standard Unicode, stabile da CLDR 47 (marzo 2025)"

nbMsg "6a48d8", "una stringa marcata `tr`"

nbMsg "41411e", "file Nim per locale, scritti dallo strumento"

nbMsg "14ace8", "scelta in compilazione; alpha, a detta del suo autore"

nbMsg "fcbbb8", "una stringa"

nbMsg "7b85c8", "un file INI"

nbMsg "9ab4eb", "scelta in compilazione, con `-d:`"

nbMsg "09780c", "Un documento diviso in segmenti"

nbMsg "e73fc2", "un paragrafo"

nbMsg "dc4169", "file PO, estratti da `make gettext`"

nbMsg "72ab00", "un sito per lingua; Jupyter Book 1 si basa su questo"

nbMsg "65ff69", "un paragrafo, un titolo, una voce di elenco"

nbMsg "3812d1", "un file PO per lingua, estratto da `mdbook-xgettext`"

nbMsg "8e7c73", "un libro per lingua: Comprehensive Rust, Rust by Example"

nbMsg "599dde", "Un file per lingua"

nbMsg "c189e7", "un file intero: `index.qmd`, `index.it.qmd`"

nbMsg "7c3c15", "uno accanto all'altro nel progetto"

nbMsg "e64763", "un sito con un selettore di lingua; babeldown abbozza la traduzione con DeepL"

nbMsg "094fb5", "una pagina intera (`post.it.md`), e le parole del tema"

nbMsg "dac599", "accanto alla pagina; le parole del tema in `i18n/it.toml`"

nbMsg "56b85e", "un sito per lingua, ogni pagina collegata alle sue traduzioni"

nbMsg "bc09e1", "niente di integrato"

nbMsg "1a5c2c", "una cartella o un repository per lingua"

nbMsg "cc0bb3", "ogni libro per conto suo"

nbMsg "bd5fe2", "Un sorgente, tutte le lingue"

nbMsg "6731d9", "uno span o un div con un `lang`"

nbMsg "961d08", "nel sorgente stesso"

nbMsg "0e6852", "un filtro tiene una sola lingua"

nbMsg "006197", "un documento MyST"

nbMsg "cb4524", "un repository per lingua, tenuto al passo da una GitHub Action"

nbMsg "ae2e5b", "di QuantEcon: Claude traduce ogni modifica, una persona la rivede"

nbMsg "71e76d", "Dati nella locale di chi legge"

nbMsg "a5e18f", "numeri, valute e date in una tabella"

nbMsg "15fa55", "tutte le locale di CLDR, nella libreria"

nbMsg "059029", """`tabella(data, locale = "it")`"""

nbMsg "8eb40e", "Come traducono gli altri"

nbMsg "d1a15a", "Strumento"

nbMsg "4ef47a", "Cosa si traduce"

nbMsg "daeb72", "Dove stanno le traduzioni"

nbMsg "930471", "Cosa riceve chi legge"

nbText "### The islands (words from the code)"

nbMsg "8b68c6", "Sicilia"

nbMsg "812378", "Sardegna"

nbMsg "8fc823", "Cipro"

nbMsg "aa4503", "Corsica"

nbMsg "761728", "Creta"

nbMsg "4ef8ae", "Le isole più grandi del Mediterraneo"

nbMsg "c3f9a0", "Superficie in km², abitanti in milioni, arrotondati"

nbMsg "fea391", "Isola"

# 1db5d6: a choice, given above

nbMsg "839006", "Abitanti"

nbText "### The top of the page, and the contents"

# f86729: a choice, given above

nbMsg "17b7a2", "12 novembre 2026 · ricerca per [nimib](https://github.com/pietroppeter/nimib)"

# 323698: a choice, given above

nbMsg "f284cd", """Come si può leggere una pagina nimib in più di una lingua? Questa pagina guarda come fanno
gettext, Fluent, Sphinx, mdBook, Quarto, Hugo e altri, abbozza tre modi in cui potrebbe farlo
nimib, e prova i due migliori in una piccola libreria, **lingua**. La pagina è il suo stesso
esempio: il selettore in alto la mostra in italiano, da un catalogo che lingua tiene aggiornato."""

nbMsg "12f183", """Il testo italiano è stato tradotto da Claude e nessuno l'ha ancora rivisto: il catalogo segna
ogni voce `machine` finché qualcuno non lo fa. Le scelte di Claude, le sue convenzioni e ogni
messaggio fianco a fianco sono nelle [note di traduzione](notes-it.html), la pagina da
rivedere. Un pezzo senza traduzione appare in inglese, separato da una riga tratteggiata."""

nbMsg "c7b7fe", "Tre cose da tradurre"

nbMsg "7516e4", "Come fanno gli altri"

nbMsg "0dcee1", "Due famiglie, e cosa insegnano"

nbMsg "388ca9", "Cosa ha nimib che agli altri manca"

nbMsg "0f8446", "Tre modi di scriverlo"

nbMsg "4d749c", "lingua, un prototipo"

nbMsg "fd42e2", "Gli output nella lingua di chi legge"

nbMsg "270797", "Un caso reale: la storia delle isole"

nbMsg "5b3498", "Cosa servirebbe a nimib"

nbMsg "b093ef", "Domande aperte"

nbMsg "908a32", "Come è fatto"

nbMsg "24c008", "I file"

nbMsg "a2c773", "Fonti"

nbMsg "871f67", "Indice"

nbText "### In *Three things to translate*"

nbMsg "0faab1", "## Tre cose da tradurre"

nbMsg "6fe976", "Torna all'indice"

nbMsg "947d7e", """Una pagina nimib è un programma Nim che scrive una pagina. Per leggerla in un'altra lingua
cambiano tre cose diverse, e ognuna chiede il suo strumento:"""

nbMsg "b0f6a4", """- **Il testo**: quello che dice `nbText`, la parte più grande, scritta da una persona.
- **Le parole della pagina stessa**: l'intestazione, il piè di pagina, un'etichetta come
  *output*, i pulsanti della modalità revisione. Poche, e uguali in ogni pagina di un sito.
- **Quello che stampa il codice**: numeri, date e tabelle, che in ogni lingua hanno le loro
  convenzioni (25,460 in inglese è 25.460 in italiano), e ogni testo che il codice scrive."""

nbMsg "330dd1", """Poi c'è quello che va detto al browser: `<html lang="en-us">`, che nimib scrive in ogni
pagina, qualunque sia la sua lingua. Lo leggono i lettori di schermo, la sillabazione e i
motori di ricerca."""

nbMsg "93b1ea", """Le parole del mestiere: *internazionalizzazione* (i18n) è preparare un programma a essere
tradotto; *localizzazione* (l10n) è tradurlo; una *locale* è una lingua con le sue convenzioni
per numeri, date e valute (`it`, `de-CH`)."""

nbText "### In *How others do it*"

nbMsg "d9ebec", "## Come fanno gli altri"

nbMsg "bf2d29", """Tredici strumenti, in cinque famiglie. I primi sono librerie per i messaggi nel codice; gli
altri sono per documenti e siti. I link a ciascuno sono in *Fonti*, alla fine."""

nbText "### In *Two families, and what they teach*"

nbMsg "f574db", "## Due famiglie, e cosa insegnano"

nbMsg "3b66b3", "Lasciando da parte le librerie, gli strumenti per i documenti sono di due tipi."

nbMsg "fa0f1c", """**Un file per lingua** (Quarto con babelquarto, Hugo, MkDocs, Docusaurus): la pagina italiana
è una copia di quella inglese, tradotta. Semplice da avviare e da capire, e la traduzione può
dire le cose a modo suo. Ma quando la pagina inglese cambia, niente dice quale parte
dell'italiano non è più aggiornata, e anche il codice è copiato: in un notebook, ogni blocco di
codice vivrebbe, e girerebbe, due volte."""

nbMsg "add561", """**Un documento diviso in segmenti** (Sphinx, mdBook con i suoi helper): il sorgente resta
l'unica pagina, uno strumento ne divide il testo in paragrafi, e ogni paragrafo è un messaggio
di un catalogo, nel formato PO di gettext. Un paragrafo che cambia è un messaggio nuovo, così il
catalogo sa esattamente cosa ritradurre; il codice non è mai copiato; e qualunque editor PO
(Poedit, Weblate, Crowdin) ci lavora. La traduzione segue l'originale paragrafo per paragrafo,
e questo è anche il suo limite."""

nbMsg "d1e80c", "Tre lezioni per nimib:"

nbMsg "71cdd2", """- L'unità che funziona per i documenti è il paragrafo: abbastanza piccolo da vedere cosa è
  cambiato, abbastanza grande da tradurlo bene. mdbook-i18n-helpers è passato dalle pagine
  intere ai paragrafi per questo.
- Il PO è la lingua franca (vedi sotto). Un formato nuovo taglierebbe fuori nimib da ogni
  strumento che usano i traduttori, e da trent'anni di convenzioni su come tenere una
  traduzione al passo.
- Una bozza della macchina e una revisione umana è come si fanno oggi le traduzioni (babeldown
  con DeepL, QuantEcon con Claude). Il catalogo deve dire quali voci una persona ha controllato."""

nbMsg "ccf67e", """**Che cos'è un file PO.** gettext, lo strumento del progetto GNU per tradurre i programmi,
tiene le sue traduzioni dagli anni Novanta in file *portable object*: testo semplice, un file
per lingua, e un elenco di voci. Ogni voce è un `msgid`, il testo nella lingua sorgente, e un
`msgstr`, la sua traduzione; sopra vanno i commenti, per chi traduce (`# `), dello strumento
che ha estratto il testo (`#. `), o dei flag (`#, fuzzy`: una traduzione da ricontrollare). Qui
un commento dice `machine` (non ancora rivista) e dà la chiave del messaggio. Un modello,
`.pot`, ha ogni `msgid` e traduzioni vuote; `msgmerge` allinea il `.po` di una lingua a un
modello nuovo, e tiene in fondo le voci non più usate, come `#~`. Essendo testo semplice con
una voce per paragrafo, un file PO si legge bene in un diff e in una pull request, e Poedit,
Weblate, Crowdin, Transifex e Lokalize lo modificano tutti. Due voci del catalogo di questa
pagina:"""

nbText "### In *What nimib has that the others lack*"

nbMsg "91fb4b", "## Cosa ha nimib che agli altri manca"

nbMsg "9bf032", "Gli strumenti qui sopra lavorano su file di testo. Una pagina nimib è un programma, e questo le dà quattro cose:"

nbMsg "c044e9", """- **I blocchi sono valori.** nimib sa quale blocco è testo, quale codice e quale output,
  quindi non deve mai indovinare cosa tradurre, come deve fare uno strumento che legge Markdown.
- **Il codice gira quando la pagina viene costruita.** Può girare una volta per lingua e
  stampare numeri, date e tabelle nel modo di ogni lingua. Nessun altro strumento qui
  localizza gli output.
- **Un solo programma scrive tutte le lingue.** La stessa esecuzione può scrivere una pagina
  con un selettore, o un file per lingua, senza una seconda build.
- **Le parole della pagina sono di nimib.** L'intestazione, il piè di pagina e la modalità
  revisione possono prendere le loro parole dallo stesso catalogo del testo."""

nbText "### In *Three ways to write it*"

nbMsg "968f74", "## Tre modi di scriverlo"

nbMsg "aad740", """**A. Tutte le lingue nel sorgente.** Ogni blocco di testo porta con sé le sue traduzioni,
come fanno i div con `lang` di Pandoc:"""

nbMsg "af5336", """Tutto è in un posto solo, e una pagina breve è facile da tenere allineata. Che chi traduce debba
modificare Nim conta poco quando traduce Claude e una persona rivede. Ma il sorgente diventa
due volte più lungo per ogni lingua, e niente dice quando l'inglese è cambiato e l'italiano no."""

nbMsg "93b6a3", """**B. Il sorgente resta com'è; un catalogo accanto.** `nbText` non cambia. Il testo della
pagina è diviso in pezzi, e ogni pezzo è una voce di `it.po`:"""

nbMsg "a04bc9", """Un pezzo che cambia perde la sua traduzione e appare in inglese finché non viene ritradotto,
così niente resta indietro senza che si veda; il sorgente resta corto com'era; e ogni strumento
PO funziona."""

nbMsg "0d89db", """**C. Codice che gira una volta per lingua.** Per quello che il codice calcola, `nbEach` fa
girare una parte della pagina una volta per lingua, con `lang` impostato su di essa, e ogni
stringa del suo codice che è testo per chi legge viene tradotta, senza segni nel codice:"""

nbMsg "ff63fd", """Non sono in concorrenza: **B per il testo, C per gli output**, e A per niente, o per una nota
che serve in una sola lingua. Poi, due modi di consegnare il risultato: una pagina con un
selettore (un artifact, un post, una pagina condivisa con un link), o un file per lingua, con i
link fra loro che leggono i motori di ricerca (un sito, un libro)."""

nbText "### In *lingua, a prototype*"

nbMsg "a920c7", "## lingua, un prototipo"

nbMsg "4bc140", """lingua è B e C in circa 300 righe di Nim, senza dipendenze oltre a nimib. Non cambia niente
in nimib: sostituisce il modo in cui sono disegnati i blocchi di testo, cosa che nimib permette.
Questa pagina la usa; le sue prime righe sono:"""

nbMsg "5beac3", """e finisce con `nbSaveLingua` dove una pagina finisce con `nbSave`. In mezzo è una normale
pagina nimib. Ecco come lingua divide un testo in pezzi:"""

nbMsg "97b0f6", """Un titolo, un paragrafo e un elenco: tre messaggi. Un blocco di codice è un pezzo a sé, e non
si traduce. Ogni pezzo è un `msgid` del catalogo. Quando la pagina viene costruita, lingua
incontra ogni pezzo e li scrive tutti, in ordine, nel modello `messages.pot`, ciascuno con una
chiave corta ricavata dal suo testo. Il catalogo italiano `it.po` è poi scritto dalle
[note di traduzione](notes-it.html): una pagina nimib fatta da Claude, con le convenzioni della
traduzione, le scelte fatte, e ogni messaggio in inglese e in italiano fianco a fianco, ciascuno
indicato dalla sua chiave. Rivedere la traduzione è rivedere quella pagina. Questo è il catalogo
che ha scritto:"""

nbMsg "1e6740", """Quando la pagina viene disegnata, ogni pezzo è scritto in ogni lingua, ciascuno in un elemento
con il suo `lang`; il selettore nell'intestazione ne mostra uno e nasconde gli altri, ricorda la
scelta, e legge `?lang=it` nell'indirizzo. Senza JavaScript la pagina è in inglese. Un titolo
prende il suo id dall'inglese, così un link a una sezione funziona in entrambe le lingue."""

nbMsg "2336fe", """La tabella qui sotto è contata quando la pagina viene costruita: ogni messaggio della pagina
(i pezzi del suo testo, e le parole dei suoi blocchi e delle sue tabelle), e quanti hanno una
traduzione."""

nbMsg "ac41a3", "I cataloghi di questa pagina"

nbMsg "9a73db", "Lingua"

nbMsg "f8611f", "Messaggi"

nbMsg "5fc652", "Tradotti"

# 49930b: a choice, given above

nbMsg "3d94d6", "Mancanti"

nbText "### In *Outputs in the reader's language*"

# 197da8: a choice, given above

nbMsg "3b64e0", """Ecco C all'opera. Il codice qui sotto gira due volte, una in inglese e una in italiano, e il
selettore in alto mostra l'una o l'altra esecuzione. La tabella è di tabelline, che riceve la
lingua come locale; i nomi delle isole, le etichette e il titolo vengono dal catalogo, anche se
nel codice non c'è nessun `tr`."""

nbMsg "0d0b09", """Le cifre sono raggruppate e i decimali segnati come fa ogni lingua (25,460 e 4.8 in inglese;
25.460 e 4,8 in italiano), e la data è scritta nell'ordine e con le parole di ogni lingua, dai
dati CLDR che tabelline si porta dietro. `std/times` di Nim sa fare una parte del lavoro:
`format` accetta una `DateTimeLocale` con i nomi dei mesi e dei giorni, ma nessun dato per
nessuna lingua tranne l'inglese."""

nbMsg "1dcdec", """`nbEach` fa girare il suo corpo una volta per lingua, quindi quello che definisce vive al suo
interno: qui `islands` non si vede dopo il blocco. `lang` è la lingua dell'esecuzione (`en`, poi
`it`). `nbEach` è una macro: prima che il corpo giri, ogni stringa che sembra testo (una
maiuscola iniziale, o uno spazio, e nessun indirizzo) è sostituita dalla sua traduzione, come
se fosse scritta `tr"Sicily"`. `"area"`, `"yMMMEd"` e `"2026-11-12"` restano come sono. Il codice
mostrato è il codice come è scritto, uguale nelle due esecuzioni; cambia solo il suo output.
Dove la regola sbaglia, `tr"..."` segna una stringa a mano, e `nbEachRaw` non traduce niente."""

nbText "### In *A real case: the islands story*"

nbMsg "b5904a", "## Un caso reale: la storia delle isole"

nbMsg "4e8fc9", """Mentre questa pagina veniva scritta, la storia delle isole del Mediterraneo di tabelline ha
avuto la sua versione italiana, costruita nel modo più semplice. Vale la pena confrontarla,
perché ha scelto diversamente quasi a ogni passo:"""

nbMsg "3559bc", """- **Una build per lingua.** `isole.nim` è l'unico sorgente; `isole_it.nim` è di due righe,
  `const lang = "it"` e `include isole`. Due pagine, due esecuzioni, e ogni output è nella sua
  lingua senza `nbEach`.
- **`tr` per tutto.** Ogni testo che chi legge vede, blocchi di testo compresi, passa da
  `tr"..."`, che cerca l'inglese in un semplice file di testo di coppie `en:` e `it:`. Un `it:`
  vuoto tiene l'inglese.
- **Una chiave mancante fa fallire la build.** Viene scritta in un file di ciò che manca, così le
  due lingue non possono allontanarsi; lingua invece mostra l'inglese e lo conta.
- **I dati tradotti alla fonte.** I valori sono tradotti dove i dati vengono letti, e i nomi
  delle isole vengono dalle etichette italiane di Wikidata: nessun catalogo per loro."""

nbMsg "108f41", """Funzionano entrambi. Costruire una volta per lingua è più semplice per un sito, dove ogni
lingua ha comunque il suo indirizzo; una pagina con un selettore va bene per una pagina
condivisa con un link. Far fallire la build è una scelta che un progetto dovrebbe poter fare:
lingua potrebbe accettare un'opzione `strict`."""

nbMsg "b1623b", """Quello che ha trovato mancante è più utile di come è stato fatto. Oltre a `<html lang>`, che
imposta da JavaScript, e alle parole inglesi della modalità revisione, del selettore di stile,
del piè di pagina e di *Show code*:"""

nbMsg "22292a", """- **tabelline non ha una locale per tutta la pagina.** Ogni `tabella()` riceve
  `locale = lang`, e `initTabellaPreview` non ne riceve affatto, quindi la locale viene
  impostata sulla tabella dopo.
- **`fmtInteger` in un blocco `summaryRows` ignora la locale della tabella.**
- **Le etichette delle righe di riepilogo vengono da identificatori** (`total: agg.sum`), quindi
  serve `textTransform tr` per tradurle; e **`fmtCountry` dà solo nomi inglesi**, sistemato
  allo stesso modo.
- **Le ancore dei titoli perdono le lettere accentate** quando un titolo diventa un id. lingua
  lo evita prendendo gli id dall'inglese, ma una pagina scritta in italiano ci inciamperebbe.
- **Le immagini**: le mappe (SVG) e le foto hanno parole inglesi dentro, che nessun catalogo di
  testo raggiunge."""

nbText "### In *What nimib would need*"

nbMsg "20c63a", "## Cosa servirebbe a nimib"

nbMsg "80f7d8", """lingua funziona senza cambiare nimib, ma ha dovuto aggirare cinque cose, e la storia delle
isole ne aggiunge una sesta. Ognuna è una piccola modifica, e quasi tutte aiuterebbero
qualunque pagina, tradotta o no:"""

nbMsg "f455ca", """- **La lingua della pagina.** nimib scrive `<html lang="en-us">` in ogni pagina. Un `lang` in
  `nimib.toml` (o `nb.lang`) lo sistemerebbe; lingua sostituisce l'intera pagina per scriverlo.
- **Uno stato mentre si disegna.** nimib disegna con funzioni che non possono cambiare niente
  (`noSideEffect`), così lingua tiene il suo catalogo in una globale e dice
  `{.cast(noSideEffect).}` per leggerlo. Basterebbe un posto nel documento per gli aiutanti
  di un blocco.
- **Salvare più di una volta.** `nbSave` scrive un file; `nbSaveEach` di lingua lo chiama una
  volta per lingua. Un nimibook ne avrebbe bisogno per ogni capitolo, con un selettore nel menu.
- **Le parole di nimib stesso.** Il tema predefinito e la modalità revisione hanno parole
  inglesi nel loro HTML e nei loro script; potrebbero prenderle da un piccolo catalogo
  distribuito con nimib.
- **La modalità revisione.** Il suo export dovrebbe dire quale lingua è stata letta, così un
  commento sull'italiano diventa una modifica a `it.po`, e segnare una voce come rivista
  toglierebbe `machine`.
- **Gli id dei titoli per ogni lingua.** Lo slug di un titolo dovrebbe tenere le lettere
  accentate (`perché` come `perche`, non `perch`), o essere preso dalla lingua sorgente come fa
  lingua."""

nbMsg "23a3ae", """Per tabelline, la storia delle isole chiede una locale per tutta la pagina (un'opzione che
ogni `tabella` e `initTabellaPreview` seguano), che ogni formato segua la locale della tabella
(`fmtInteger` nelle righe di riepilogo), e i nomi dei paesi in ogni lingua di CLDR."""

nbText "### In *Open questions*"

nbMsg "dfcec3", "## Domande aperte"

nbMsg "572106", """- **Il codice.** Commenti e stringhe nei blocchi di codice qui restano in inglese.
  mdbook-i18n-helpers traduce un blocco di codice come un unico messaggio; per una pagina nimib
  vorrebbe dire far girare codice tradotto, quindi probabilmente è meglio lasciarlo stare.
- **Un pezzo che cambia.** Un refuso corretto in inglese fa del suo pezzo un messaggio nuovo, e
  l'italiano si perde finché non viene ritradotto. `msgmerge` tiene la vecchia traduzione come
  *fuzzy* quando il testo nuovo è simile; lingua potrebbe fare lo stesso.
- **Plurali e generi.** `tr` con `%` basta per una pagina. I messaggi con plurali richiedono
  MessageFormat 2 o Fluent, e non ho trovato una libreria Nim per nessuno dei due.
- **Quanto grande un sito.** Un catalogo per pagina va bene per una pagina; un libro o un sito
  potrebbero volerne uno per capitolo, o uno solo per tutto, come ha mdBook.
- **Da destra a sinistra.** L'arabo o l'ebraico richiederebbero `dir="rtl"` e un tema che lo
  segua."""

nbText "### In *How it is built*"

# 6a09b7: a choice, given above

nbMsg "387385", """lingua è un file solo, `lingua.nim`, in cinque parti, ognuna costruita sulla precedente. Ogni
pezzo è mostrato qui com'è nel file; il file intero è piegato in fondo."""

nbMsg "639424", """**I pezzi.** Un testo è diviso alle sue righe vuote, tranne dentro un blocco di codice. L'id
di un titolo viene dal suo testo inglese."""

nbMsg "28688b", """**Il catalogo.** Un file PO è un elenco di voci: commenti, poi `msgid` e `msgstr`, ciascuno una
stringa tra virgolette che può continuare su più righe. lingua legge solo quello che scrive:
niente forme plurali e niente contesti. Una traduzione si cerca con il suo intero testo
inglese, che è quello che fa gettext."""

nbMsg "013ec6", """**Disegnare.** `useLingua` legge i cataloghi e mette una sua funzione dove nimib disegna un
blocco di testo (`partials["nbText"]`). Quella funzione divide il testo in pezzi e scrive ognuno
in ogni lingua, o solo in quella che si sta scrivendo quando c'è un file per lingua."""

nbMsg "026b0d", """**Una volta per lingua.** `nbEach` crea un contenitore con una parte per lingua e fa girare il
suo corpo dentro ogni parte, con `l10n.current` impostato; quando viene disegnata, ogni parte
appare nella sua lingua. Prima, la macro percorre il corpo e avvolge ogni stringa che sembra
testo in una chiamata a `tr`, tenendone il posto nel file, così nimib mostra ancora il codice
come è scritto."""

nbMsg "421053", """**Salvare.** La pagina viene disegnata una volta per incontrare ogni messaggio; poi i messaggi
vengono contati, il modello scritto, e la pagina disegnata di nuovo e scritta."""

nbMsg "dc6b2d", """**Le note di traduzione.** `notes.nim` ha i blocchi della pagina delle note: `nbMsg key, text`
dà la traduzione di un messaggio e la mostra accanto all'inglese, `nbChoice` la dà come la prima
di più opzioni, e `nbSaveNotes` controlla che ogni messaggio del modello abbia la sua traduzione
(e che non avanzino chiavi), poi scrive `it.po`. La pagina si costruisce in tre passi: la
pagina, che scrive il modello; le note, che scrivono il catalogo; di nuovo la pagina."""

nbText "### In *The files*"

nbMsg "0f7523", "## I file"

nbMsg "d0db13", "Tutto ciò che fa questa pagina, così com'è nella sua cartella."

nbText "### In *Sources*"

nbMsg "12b18a", "## Fonti"

nbMsg "56efd1", """- gettext: [il manuale di GNU gettext](https://www.gnu.org/software/gettext/manual/gettext.html),
  i file PO e `msgmerge`.
- Fluent: [projectfluent.org](https://projectfluent.org/). MessageFormat 2:
  [stabile in CLDR 47](https://blog.unicode.org/2025/03/unicode-cldr-47-release-messageformat-2.html).
- Sphinx: [Internationalization](https://www.sphinx-doc.org/en/master/usage/advanced/intl.html)
  e [sphinx-intl](https://sphinx-intl.readthedocs.io/). Jupyter Book: la discussione
  [*multi language site in one repo*](https://github.com/orgs/executablebooks/discussions/220).
- mdBook: [mdbook-i18n-helpers](https://github.com/google/mdbook-i18n-helpers) e la sua
  [guida](https://github.com/google/mdbook-i18n-helpers/blob/main/i18n-helpers/USAGE.md).
- Quarto: [babelquarto](https://docs.ropensci.org/babelquarto/) e
  [babeldown](https://docs.ropensci.org/babeldown/), di rOpenSci.
- Hugo: [Multilingual mode](https://gohugo.io/content-management/multilingual/).
- Pandoc: [language variables](https://pandoc.org/MANUAL.html#language-variables).
- QuantEcon: [action-translation](https://quantecon.github.io/action-translation).
- Nim: [nim-intl](https://github.com/iffy/nim-intl),
  [nimterlingua](https://github.com/juancarlospaco/nim-nimterlingua),
  [std/times](https://nim-lang.org/docs/times.html#DateTimeLocale) e
  [le locale di tabelline](https://pietroppeter.github.io/tabelline/)."""

nbText "### The footer"

nbMsg "27ff70", "Scritto in Nim con Claude, in una pagina [nimib](https://github.com/pietroppeter/nimib) 🐳; il codice di questa pagina è girato quando è stata costruita. [Sorgente su GitHub](https://github.com/pietroppeter/claude-artifacts/tree/main/nimib-localization/src)."


nbText """
## Check

Whether these notes and the page agree, checked when this page is built.
"""

nbNotesCheck

nbText """
## The catalog it writes

`it.po`, as building this page writes it: the messages in the order of the page, each with
its translation, its key, and `machine` until it is reviewed.
"""

nbPoFile

nbText """
## How it is built

This page is a nimib page like the one it translates, made of the blocks of `notes.nim`.
`nbMsg` gives a message's translation by its key and shows it beside the English, which it
reads from the template `messages.pot`; `nbChoice` gives several, the first used;
`nbSaveNotes` writes `it.po` and the page. Both files are folded below.
"""

nbFoldCode "notes.nim"
nbFoldCode "it.nim"

nbSaveNotes
