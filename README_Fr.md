# DTLmenu

**Lanceur graphique de compilation pour la suite d'outils DTL - application Windows HTA**

Version : v1.0-6
Site : [netdtl.com](https://netdtl.com)

DTLmenu est une application Windows HTML Application (`.hta`) utilisée pour compiler les outils Python de la suite DTL depuis une interface graphique locale. Elle prépare les commandes PyInstaller, écrit un script `.cmd` temporaire, le lance dans une fenêtre de commandes visible et permet d'ouvrir les dossiers de sortie.

## Position actuelle

`DTLmenu.hta` est le lanceur principal.

`DTLmenu.vbs` est désormais considéré comme legacy. Microsoft a annoncé la dépréciation de VBScript : les nouveaux usages et la maintenance doivent donc viser le lanceur HTA, puis à terme un remplaçant Python/Tkinter.

## Outils couverts

| Outil | Stack | Méthode de build |
| --- | --- | --- |
| DTL4u | Python / Tkinter | PyInstaller `--onefile --noconsole` |
| DTLarchive | Python | PyInstaller `--onefile --console` |
| DTLaudit | Python | PyInstaller `--onefile` |
| DTLdesktop | Python / Tkinter | Fichier `.spec` PyInstaller |
| DTLexplains | Python | PyInstaller `--onefile --console` |
| DTLi18n | Python | PyInstaller `--onefile --console` |
| DTLknowsWhy | Python, GUI, CLI, Agent | Fichiers `.spec` PyInstaller |
| DTLsaysWhat | Python | PyInstaller `--onefile` |
| GitDTL | Python / Tkinter | Fichier `.spec` PyInstaller |
| GitHubMenu | Python / Tkinter | Fichier `.spec` PyInstaller |

NetDTL n'est plus affiché dans `DTLmenu.hta`.

## Prérequis

- Windows avec `mshta.exe`
- Python disponible via `python` dans le `PATH`
- PyInstaller disponible via `python -m PyInstaller`
- un dossier racine commun contenant les projets listés ci-dessus

DTLmenu vérifie Python et PyInstaller avant de lancer un build. Si PyInstaller manque, il peut proposer :

```powershell
python -m pip install --upgrade pyinstaller
```

## Utilisation

Ouvrir :

```text
DTLmenu.hta
```

Définir `ROOT_DIR` sur le dossier parent qui contient les projets, puis cliquer sur **appliquer**.

Exemple :

```text
D:\Documents\Mes sites Web\Secours catholique\outils
```

## Menu

| Touche | Action |
| --- | --- |
| 1 | Build DTL4u |
| 2 | Build DTLarchive |
| 3 | Build DTLaudit |
| 4 | Build DTLdesktop |
| 5 | Build DTLexplains |
| 6 | Build DTLi18n |
| 7 | Build DTLknowsWhy GUI, CLI et Agent |
| 8 | Build DTLsaysWhat |
| 9 | Build GitDTL |
| 10 | Build GitHubMenu |
| A | Build de tous les outils Python |
| D | Ouvrir un dossier `dist\` |
| P | Vérifier Python et PyInstaller |
| 0 | Quitter |

## Fonctionnement d'un build

Quand un build démarre, DTLmenu :

1. appelle `DTLversion.py begin` pour le projet sélectionné ;
2. génère un script de commandes temporaire dans `%TEMP%` ;
3. écrit ce script en Unicode pour afficher correctement les messages français accentués ;
4. lance PyInstaller ;
5. restaure la version précédente si une commande Python/PyInstaller échoue ;
6. laisse la fenêtre de commandes ouverte à la fin pour permettre la lecture du résultat.

## Versioning

`DTLversion.py` met à jour la version du projet avant compilation. Il prend actuellement en charge :

- `DTL4u`
- `DTLarchive`
- `DTLaudit`
- `DTLdesktop`
- `DTLexplains`
- `DTLi18n`
- `DTLknowsWhy`
- `DTLsaysWhat`
- `GitDTL`
- `GitHubMenu`

Si un build échoue, le script temporaire appelle la commande de rollback générée par `DTLversion.py`.

## Arborescence attendue

```text
outils\
  DTLmenu\
    DTLmenu.hta
    DTLversion.py
    DTLmenu.root
  DTL4u\
  DTLarchive\
  DTLaudit\
  DTLdesktop\
  DTLexplains\
  DTLi18n\
  DTLknowsWhy\
  DTLsaysWhat\
  GitDTL\
  GitHubMenu\
```

## Notes

Le format HTA est encore utilisé parce qu'il permet d'accéder à `WScript.Shell` et `Scripting.FileSystemObject`, nécessaires pour écrire des scripts temporaires, lancer des commandes locales et ouvrir des dossiers dans l'Explorateur.

HTA reste toutefois une technologie Windows ancienne. L'évolution recommandée est de remplacer DTLmenu par un lanceur Python/Tkinter, cohérent avec les autres outils DTL.

## Licence

MIT.
