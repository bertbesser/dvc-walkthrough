# Eine Einführung in DVC

In diesem Artikel beschäftigen wir uns mit der systematischen Modellentwicklung im Machine Learning (ML).
Wir können die Vorhersagekraft eines Modells verbessern, wenn wir z.B. seine Parameter anpassen oder wenn mehr Trainingsdaten verfügbar sind.
Um Verbesserungen verlässlich zu messen, benötigen wir für jede neue Version des Modells Kenntnis über die Modelldefinition und -konfiguration (Hyperparameter usw.) sowie die verwendeten Trainingsdaten.
Insbesondere sollten wir diese Daten *gemeinsam* mit dem Modell und den erzielten Performance-Metriken versionieren.

Bei dieser Aufgabe, und darüber hinaus, hilft uns [DVC](https://dvc.org/) (Data Version Control).

![pipeline](images/logo-owl-readme.png)

Eine DVC-*Pipeline* macht das Laden und Vorverarbeiten aller Daten, das Training, die Erstellung von Metriken, usw. vollständig reproduzierbar (und unterstützt somit auch bei der Automatisierung des Trainings).
Trainingsdaten, Modellkonfiguration, das fertig trainierte Modell und Metriken sind so versioniert, dass wir bequem zu jeder beliebigen Version zurückspringen und alle zugehörigen Daten einsehen können.
Zudem erstellt DVC eine Übersicht der Metriken aller Pipeline-Versionen und hilft so, das stärkste Modell zu identifizieren.
Trainingsdaten, trainierte Modelle, Metriken usw. werden mit Teammitgliedern geteilt (über ein gemeinsames Reporitory), um die effiziente Zusammenarbeit zu verbessern.

## Unser Spielzeugprojekt
Wir führen durch ein Beispielprojekt (verfügbar in diesem [GitHub-Repository](https://github.com/bbesser/dvc-walkthrough)), in dem ein neuronales Netzwerk trainiert wird, welches Bilder von handschriftlichen Ziffern aus dem [MNIST-Datensatz](http://yann.lecun.com/exdb/mnist/) klassifiziert.
Wann immer die verfügbare Menge an Trainingsbildern wächst trainieren wir das Modell neu, um seine Genauigkeit zu verbessern.
(Für die Intuition reicht in der folgenden Abbildung eine vereinfachte Darstellung der Netzwerkarchitektur.)

![model](https://blog.codecentric.de/files/2019/03/model.jpg)

Um die Arbeitsumgebung vorzubereiten, klonen wir das genannte Git-Repository, wechseln in das geklonte Verzeichnis und führen `./start_environment.sh bash` aus (vgl. folgender Codeblock).
Das Skript erstellt ein Docker-Image und startet einen zugehörigen Container, der `bash`-Parameter sorgt dafür, dass wir als Benutzer `dvc` im Arbeitsordner `/home/dvc/walkthrough` im Container angemeldet werden.
Alle im Artikel angegebenen Befehle finden sich im Skript `/home/dvc/scripts/walkthrough.sh` im Container wieder.
(Der Aufruf von `./start_environment.sh` mit dem Parameter `walkthrough` führt das `walkthrough.sh`-Skript aus.)

<pre>
# $ ist der Hostprompt im geklonten Verzeichnis
# $$ ist der Containerprompt im Verzeichnis /home/dvc/walkthrough

$ git clone https://github.com/bbesser/dvc-walkthrough
$ cd dvc-walkthrough
$ ./start_environment.sh bash
$$ cat /home/dvc/scripts/walkthrough.sh
</pre>

## Vorbereitung des Repositorys
Der Arbeitsordner `/home/dvc/walkthrough` enthält bereits den Unterordner `code` mit allem notwendigen Code, den wir natürlich nur unter Git-Versionskontrolle weiterentwickeln möchten.
Machen wir `/home/dvc/walkthrough` zu einem "DVC-fähigen" Git-Repository!
DVC baut auf Git auf.
Die gesamte DVC-Konfiguration wird im gleichen Git-Repository wie der Quellcode versioniert, und zwar im Unterordner `.dvc` (vgl. folgender Codeblock).
Beachte, dass ein Git-Tag für das frisch initialisierte Repository kein Muss ist - wir erstellen das Tag jedoch für spätere Teile dieses Walkthroughs.

<pre>
# Code is verkürzt vollständiger Code
# in /home/dvc/scripts/walkthrough.sh.

$$ git init
$$ git add code
$$ git commit -m "initial import"
$$ dvc init
$$ git status
        new file: .dvc/.gitignore
        new file: .dvc/config
$$ git add .dvc
$$ git commit -m "init dvc"
$$ git tag -a 0.0 -m "freshly initialized with no pipeline defined, yet"
</pre>

## Pipeline erstellen
Unsere Pipeline wird aus drei sogenannten *Stages* bestehen, nämlich
1. Daten laden/vorverarbeiten,
2. Training und
3. Metriken erstellen.

Hier ist eine schematische :

![pipeline](https://blog.codecentric.de/files/2019/03/pipeline-3.jpg)

In der *load*-stage implementieren wir eine Dummy-Vorverarbeitung, die lediglich vorgegebene Rohbilddaten in das Repository kopiert.
Da unser Ziel ist, das Modell neu zu trainieren wann immer neue Trainingsbilder verfügbar sind, kann die zu kopierende Datenmenge konfiguriert werden.
Diese Konfiguration befindet sich in der Datei `config/load.json`.
Die Konfiguration der Trainings-Stage befindet sich in `config/train.json` (die Architektur unseres neuronalen Netzwerks erlaubt eine variable Anzahl von Faltungsfiltern).
Wir sollten auch unsere Konfiguration unter Versionskontrolle stellen!

<pre>
$$ mkdir config
$$ echo '{ "num_images" : 1000 }' > config/load.json
$$ echo '{ "num_conv_filters" : 32 }' > config/train.json
$$ git add config/load.json config/train.json
$$ git commit -m "add config"
</pre>

Die Stages einer DVC-Pipeline werden durch Abhängigkeiten und Ausgaben miteinander verbunden (im DVC-Terminus heißen sie *Dependencies* bzw. *Outputs*).
Dependencies und Outputs sind einfache Dateien.
Z.B. hängt unsere *load*-Stage von der Konfigurationsdatei `config/load.json` ab.
Die *load*-Stage gibt einen Ordner voll Trainingsbilder als Output aus.
Wenn sich bei Ausführung unserer *load*-Stage die Menge von Trainingsbildern ändert, dann erkennt die *train*-Stage diese Änderungen, da die Bildermenge eine Dependency von *train* ist.
Anschließend werden in der *evaluate*-Stage Metriken für das neu trainierte Modell erstellt.
Mit Hilfe der Pipeline-Definition kümmert sich DVC darum, nur die Stages mit geänderten Dependencies neu auszuführen, wie wir im Abschnitt [Reproduzieren der Pipeline](#reproduce-the-pipeline) detailliert besprechen. 

Der folgende `dvc run`-Befehl erstellt unsere *load*-Stage, wobei die Definition dieser Stage in der durch den Parameter `-f` angegebenen Datei gespeichert wird.
Dependencys werden mit dem Parameter `-d` angegeben, in den im Output-Parameter `-o` angegebenen Order schreibt das Skript `code/load.py` die kopierten Daten.
DVC führt die Stage sofort aus und erzeugt damit bereits die gewünschten Trainingsdaten.

<pre>
$$ dvc run -f load.dvc -d config/load.json -o data python code/load.py
Running command:
        python code/load.py
Computing md5 for a large directory data/2. This is only done once.
...
$$ git status
        .gitignore
        load.dvc
$$ cat .gitignore
data
$$ git add .gitignore load.dvc
git commit -m "init load stage"
</pre>

Unsere *load*-Stage schreibt Bilddaten in den Ordner `data`.
DVC hat diesen Ordner zur Ignorierliste von Git hinzugefügt, denn Git-Repositories eignen sich nicht, große Binärdateien zu versionieren.
DVC übernimmt die Verwaltung solcher Daten selbst.
Im Abschnitt [DVC-Cache](#dvc-cached-files) sprechen wir über Verwendung und Implementierung dieser Verwaltung.

Nachdem wir `.gitignore` und `load.dvc` unter Versionskontrolle gestellt haben, definieren wir die beiden anderen Stages unserer Pipeline analog (vgl. folgender Codeblock).
Dabei hängt unsere *train*-Stage von der Trainingskonfigurationsdatei ab.
Anders als in unserem Spielzeugprojekt dauert das Training in realen Projekten typischerweise lange.
Deshalb schreiben wir das fertig trainierte Modell in eine Output-Datei (`model/model.h5`), die ebenfalls von DVC verwaltet wird.
So haben wir in Zukunft einfachen Zugriff auf diese Version unseres Modells.

<pre>
$$ dvc run -f train.dvc -d data -d config/train.json -o model/model.h5 python code/train.py
...
$$ dvc run -f evaluate.dvc -d model/model.h5 -M model/metrics.json python code/evaluate.py
...
</pre>

Für die *evaluate*-Stage definieren wir den Output `model/metrics.json` als *Metrik* (`-M`-Parameter).
Metriken können mit dem Befehl `dvc metrics` überprüft werden, wie wir im Abschnitt [Performancegewinn](#compare-versions) erläutern.
Um unsere erste Version der Pipeline zu sichern, stellen wir alle Stage-Definitionen (`.dvc`-Dateien) unter Versionskontrolle und erstellen einen Git-Tag.

<pre>
$$ git add ...
$$ git commit ...
$$ git tag -a 0.1 -m "initial pipeline version 0.1"
</pre>

*Anmerkung*:
DVC unterstützt nicht nur Git-Tags für die Organisation Pipeline-Versionen, sondern auch Branches.

Werfen wir noch einen kurzen Blick darauf, wie DVC unsere Pipeline darstellt.

<pre>
$$ dvc pipeline show --ascii evaluate.dvc
</pre>

![pipeline rendered by dvc](https://blog.codecentric.de/files/2019/03/pipeline-dvc-1.jpg)

*Anmerkung*:
Stage-Definitionen rufen *beliebige* Befehle auf, d.h. DVC ist sprachunabhängig und nicht an Python gebunden.
Niemand hindert uns, Stages in Bash, C oder einer anderen Sprache oder Framework wie R, Spark, PyTorch usw. zu implementieren.

## <a name="dvc-cached-files"></a>DVC-Cache
Um eine Vorstellung davon zu bekommen, wie DVC und Git zusammenarbeiten, lasst uns zum ersten Tag unseres Git-Repositorys zurückkehren.
Da noch keine Pipeline definiert ist, existieren keine unserer Trainingsdaten, -modelle oder -metriken.

Wir erinnern uns, dass DVC Git verwendet, um zu verwalten, welche Outputs zur ausgecheckten Version gehören.
Daher müssen wir -- zusätzlich zur Auswahl der Version mit Hilfe des `git`-Befehls -- DVC mit dem Befehl `dvc checkout` anweisen, Outputs zu synchronisieren.

<pre>
$$ git checkout 0.0
$$ dvc checkout
$$ ls data
ls: cannot access 'data': No such file or directory
# das ist gewollt :-)
</pre>

Zurück zur neuesten Version stellen wir fest, dass DVC alle Trainingsdaten wiederhergestellt hat.

<pre>
$$ git checkout 0.1
$$ dvc checkout
$$ ls data
0  1  2  3  4  5  6  7  8  9
# ein Ordner für jede Ziffer
</pre>

Auf gleiche Weise können wir zu jeder Version unserer Pipeline springen und deren Konfiguration, Trainingsdaten, Modelle, Metriken usw. einsehen.

*Anmerkung*:
DVC konfiguriert Git so, dass Git Outputs ignoriert.
Wie wird die Versionierung solcher ignorierten Daten implementiert?
DVC hält alle Binärdaten von Outputs ausschließlich im Unterordner `.dvc/cache` des Repositorys (der auch von Git ignoriert wird, wie in `.dvc/.gitignore` zu sehen).
Von DVC gecachte Dateien werden uns als Hardlinks bereitgestellt (von Outputdatei in den Cacheordner), wobei DVC sich um die Verwaltung der Hardlinks kümmert.
(Für spezielle Anforderungen kann DVC die Verwaltung von Outputs auch uns überlassen.
Typischerweise versionieren wir sie dann ebenfalls im Git-Repository.)

![dvc cache](https://blog.codecentric.de/files/2019/03/dvc_cache.jpg)

## <a name="reproduce-the-pipeline"></a>Reproduzieren der Pipeline
Wir können uns auf die Schulter klopfen.
Der schwierigste Teil, das Erstellen der Pipeline, haben wir bereits gemeistert.
Die Reproduktion (von Teilen) einer Pipeline, d.h. die erneute Ausführung von Stages mit geänderten Dependencies, ist denkbar einfach.
Zuerst beobachten wir, dass es ohne geänderte Dependencies nichts zu reproduzieren gibt.

<pre>
$$ dvc repro evaluate.dvc
...
Stage 'load.dvc' didnt change.
Stage 'train.dvc' didnt change.
Stage 'evaluate.dvc' didnt change.
Pipeline is up to date. Nothing to reproduce.
</pre>

Was geschieht beim Ändern der Trainingsdatenmenge (siehe Stiftsymbol in der folgenden Abbildung) und beim Aufruf des `dvc repro`-Befehls mit dem Parameter `evaluate.dvc` für die letzte Stage (rotes Play-Symbol)?
Da sich unter geänderten Trainingsdaten eine andere Metrik ergibt, wird die gesamte Pipeline reproduziert (rote Pfeile).

![reproduce-all](https://blog.codecentric.de/files/2019/03/pipeline-repro-all-1.jpg)

<pre>
$$ echo '{ "num_images" : 2000 }' > config/load.json
$$ dvc repro evaluate.dvc
...
Warning: Dependency 'config/load.json' of 'load.dvc' changed.
Stage 'load.dvc' changed.
Reproducing 'load.dvc'
...
Warning: Dependency 'data' of 'train.dvc' changed.
Stage 'train.dvc' changed.
Reproducing 'train.dvc'
...
Warning: Dependency 'model/model.h5' of 'evaluate.dvc' changed.
Stage 'evaluate.dvc' changed.
Reproducing 'evaluate.dvc'
</pre>

DVC verfolgt Änderungen an Dependencies und Outputs durch md5-Summen, die in den `.dvc`-Dateien der entsprechenden Stages gespeichert sind.
Im folgenden Beispiel zeigen wir nach Reproduktion der Pipeline, dass in `load.dvc` sowohl eine geänderte Dependency (`config/load.json`) als auch ein geänderter Output (die Trainingsbilder im Ordner `data`) vermerkt sind.

<pre>
$$ git status
        modified:   config/load.json
        modified:   evaluate.dvc
        modified:   model/metrics.json
        modified:   load.dvc
        modified:   train.dvc
$$ git diff load.dvc
...
deps:
-- md5: 44260f0cf26e82df91b23ab9a75bf4ae
+- md5: 2e13ea50a381a9be4809026b71210d5a
...
outs:
-  md5: b5136af809e828b0c51735f40c5d6db6.dir
+  md5: 8265c35e6eb17e79de9705cbbbd9a515.dir
</pre>

Speichern wir diese Version unserer Pipeline und taggen sie.

<pre>
$$ git add load.dvc train.dvc evaluate.dvc config/load.json model/metrics.json
$$ git commit -m "0.2 more training data"
$$ git tag -a 0.2 -m "0.2 more training data"
</pre>

## Teilweise Reproduktion
Was geschieht, wenn sich nur die Trainingskonfiguration ändert, die Konfiguration der *load*-Stage aber gleich bleibt?
(Wir erhöhen die Anzahl der Faltungsfilter im Netz.)
Alle Stages außer `load.dvc` sollten reproduziert werden!
Wir haben die Kontrolle darüber, welche Stages der Pipeline reproduziert werden.
In einem ersten Schritt reproduzieren wir nur die *train*-Stage, indem wir den Befehl `dvc repro` mit dem Parameter `train.dvc` aufrufen.

![reproduce-all](https://blog.codecentric.de/files/2019/03/pipeline-repro-train-1.jpg)

<pre>
$$ echo '{ "num_conv_filters" : 64 }' > config/train.json
$$ dvc repro train.dvc
...
Stage 'load.dvc' didnt change.
Warning: Dependency 'config/train.json' of 'train.dvc' changed.
Stage 'train.dvc' changed.
Reproducing 'train.dvc'...
</pre>

Wir können nun die gesamte Pipeline reproduzieren.
Da wir bereits neu trainiert haben, wird nur die *evaluate*-Stage ausgeführt.
(Der blasse Stift markiert das durch die Reproduktion der *train*-Stage geänderte Modell.)

![reproduce-all](https://blog.codecentric.de/files/2019/03/pipeline-repro-evaluate-1.jpg)

<pre>
$$ dvc repro evaluate.dvc
...
Stage 'load.dvc' didnt change.
Stage 'train.dvc' didnt change.
Warning: Dependency 'model/model.h5' of 'evaluate.dvc' changed.
Stage 'evaluate.dvc' changed.
Reproducing 'evaluate.dvc'...
</pre>

Weil es so schön ist, erhöhen wir abschließend nocheinmal die Menge der verfügbaren Trainingsdaten und triggern die gesamte Pipeline durch die Reproduktion der `evaluate.dvc`-Stage.

<pre>
$$ echo '{ "num_images" : 3000 }' > config/load.json
$$ dvc repro evaluate.dvc
...
Warning: Dependency 'config/load.json' of 'load.dvc' changed.
Stage 'load.dvc' changed.
Reproducing 'load.dvc'
...
Warning: Dependency 'data' of 'train.dvc' changed.
Stage 'train.dvc' changed.
Reproducing 'train.dvc'
...
Warning: Dependency 'model/model.h5' of 'evaluate.dvc' changed.
Stage 'evaluate.dvc' changed.
Reproducing 'evaluate.dvc'...
</pre>

Wiederum speichern wir die neue Version unserer Pipeline und taggen sie, damit wir später direkt auf alle zugehörigen Trainingsdaten, Konfigurationen, Modelle und Metriken zugreifen können.

<pre>
$$ git add config/load.json config/train.json evaluate.dvc load.dvc train.dvc model/metrics.json
$$ git commit -m "0.3 more training data, more convolutions"
$$ git tag -a 0.3 -m "0.3 more training data, more convolutions"
</pre>

## <a name="compare-versions"></a>Performancegewinn
Wir erinnern uns, dass wir in der Datei `model/metrics.json` eine Metrik für die *evaluate*-Stage definiert haben.
DVC kann Metrikdateien für alle Tags im gesamten Git-Repository auflisten, was es uns ermöglicht, die Performance unseres Modells für verschiedene Versionen der Pipeline zu vergleichen.
Die Erhöhung der Trainingsdatenmenge und das Hinzufügen von Faltungsfiltern zum neuronalen Netz verbessert die Accuracy des Modells deutlich.

<pre>
$$ dvc metrics show -T # -T für alle Tags
...
0.1:
        model/metrics.json: [0.896969696969697]
0.2:
        model/metrics.json: [0.9196969693357294]
0.3:
        model/metrics.json: [0.9565656557227626]
</pre>

Tatsächlich speichert unsere Implementierung der *evaluate*-Stage in der Datei `model/metrics.json` nicht nur die Accuracy des Modells, sondern auch den Trainingsloss.
Um nur die Accuracy anzuzeigen, haben wir DVC mit einem XPath-Ausdruck wie folgt konfiguriert.
Dieser Ausdruck wird in der `.dvc`-Datei der entsprechenden Stage gespeichert.

<pre>
$$ dvc metrics modify model/metrics.json --type json --xpath acc
$$ cat evaluate.dvc
...
metric:
 type: json
 xpath: acc
...
</pre>

So erlaubt DVC, dass wir in der Übersicht des Repositorys nur die relevanten Metriken vergleichen.

*Anmerkung 1*: 
DVC unterstützt auch Metriken, die in CSV-Dateien oder einfachen Textdateien gespeichert sind.
Dabei interpretiert DVC die Metriken *nicht* und behandelt sie stattdessen als reinen Text.

*Anmerkung 2*:
Um eine konsistente Metrikanzeige über alle Pipeline-Versionen hinweg zu gewährleisten, sollten Metriken gleich zu Beginn eines Projekts konfiguriert werden.
Dann ist die Konfiguration in .`dvc`-Dateien für alle Versionen gleich.

## Daten teilen
Bei der Entwicklung von Modellen im Team ist der Austausch von Trainingsdaten, fertig trainierten Modellen und Metriken entscheidend für eine effiziente Zusammenarbeit - wenn jedes Teammitglied das gleiche Modell trainiert, dann verschwenden wir wertvolle Zeit.
Wie erwähnt werden Outputs einer Stage nicht im Git-Repository gespeichert.
Stattdessen verwaltet DVC diese Dateien in seinem `.dvc/cache`-Ordner.
DVC ermöglicht es uns, Cache-Dateien in Remote-Speicher zu kopieren (SSH, NAS, FTP, Amazon S3, etc.).
Von dort aus kann jedes Teammitglied diese Daten in den DVC-Cache seines individuellen Arbeitsbereichs ziehen und dann wie gewohnt damit arbeiten.

![dvc remote](https://blog.codecentric.de/files/2019/03/dvc_remote.jpg)

Für den Zweck dieses Walkthroughs simulieren wir Remote-Speicher mit einem lokalen Ordner namens `/remote/dvc-cache`.
Wie jede andere DVC-Konfiguration wird ein DVC-Remote in einem Git-Commit gesichert.
Mit `dvc push` kopieren wir dann Inhalte des lokalen DVC-Caches in das Remote.

<pre>
$$ mkdir /remote/dvc-cache
$$ dvc remote add -d fake_remote /remote/dvc-cache # -d macht diesen Remote zum Default
$$ git add .dvc/config # speichert die Remote-Konfiguration
$$ git commit -m "configure remote"
$$ dvc push -T
</pre>

Der `-T`-Parameter kopiert Cache-Dateien für alle Tags.
Beachte, dass `dvc push` intelligent nur neue oder geänderte Daten kopiert und Daten überspringt, die seit dem letzten Push unverändert geblieben sind.
(Ohne `-T`-Parameter kopiert DVC nur Daten der aktuell ausgecheckten Version unserer Pipeline.)

Wie würde ein Teammitglied auf unsere Daten zugreifen?
(Wenn Du in der Shell mitgearbeitet hast, dann verlasse den Container und erstelle ihn neu, indem Du `./start_environment.sh bash` aufrufst.
Die folgenden Schritte sind in `/home/dvc/scripts/clone.sh` dokumentiert und sollten im Ordner `/home/dvc` angewendet werden.)
Das Klonen des Git-Repositorys lädt keine Trainingsdaten, Modelle, usw., da diese Dateien nicht von Git sondern von DVC verwaltet werden.
Wir müssen DVC anweisen, diese Daten aus dem Remote-Speicher zu holen.
Danach können wir wie bisher auf die Daten zugreifen.

<pre>
$$ cd /home/dvc
$$ git clone /remote/git-repo walkthrough-cloned # der Einfachheit halber arbeiten wir mit einem lokalen Git-Repository
$$ cd walkthrough-cloned
$$ ls data
ls: cannot access 'data': No such file or directory # keine Trainingdaten weit und breit :(
$$ dvc pull -T # -T um Daten für alle Tags zu ziehen
$$ ls data
0  1  2  3  4  5  6  7  8  9 # daaaaa sind die Trainingsdaten :)
</pre>

## Fazit
Mit DVC können wir (sprachunabhängige) reproduzierbare ML-Pipelines erstellen und zusammen mit den zugehörigen Trainingsdaten, Konfigurationen, Modellen, Metriken usw. versionieren.
Metriken können für alle Versionen einer Pipeline ausgewertet werden.
Trainingsdaten, trainierte Modelle und andere zugehörige Binärdaten können mit Teammitgliedern über die Cloud geteilt werden, um eine effiziente Zusammenarbeit zu gewährleisten.

In einem [Folgebeitrag](https://blog.codecentric.de/en/2019/08/dvc-dependency-management/) zeigen wir, wie man DVC-Outputs als Dependencies in andere Projekte einbinden kann.
