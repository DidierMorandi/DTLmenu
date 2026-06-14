# DTLmenu

**Lanceur graphique de compilation pour la suite NetDTL - application Windows HTA**

v 1.0.0 - 11 juin 2026 - Didier DTL Morandi - https://didiermorandi.com/netdtl/

DTLmenu est une application Windows HTML Application (`.hta`) qui remplace un menu VBScript classique par une interface graphique sombre de style terminal. Elle permet de lancer les builds PyInstaller de chaque outil Python de la suite NetDTL en un clic, d'ouvrir les dossiers de sortie dans l'Explorateur et de vérifier l'environnement Python sans passer manuellement par la ligne de commande.

---

## Présentation

La suite NetDTL comprend six outils :

| Outil | Stack | Méthode de build |
|------|-------|------------------|
| DTLknowsWhy | Python (+ CLI + Agent) | Fichiers `.spec` PyInstaller |
| DTLsaysWhat | Python | PyInstaller `--onefile` |
| GitDTL | Python / Tkinter | Fichier `.spec` PyInstaller |
| GitHubMenu | Python / Tkinter | Fichier `.spec` PyInstaller |
| DTLaudit | Python | PyInstaller `--onefile` |
| NetDTL | PHP / MySQL | Pas de build requis |

DTLmenu les couvre depuis une fenêtre unique.

---

## Prérequis

- Windows avec `mshta.exe` ;
- Python accessible via `python` dans le `PATH` ;
- PyInstaller installé (`pip install pyinstaller`) ;
- arborescence source de la suite NetDTL présente sur le disque.

Aucune autre dépendance : `DTLmenu.hta` est autonome.

---

## Installation

Copier `DTLmenu.hta` où vous voulez, idéalement près du dossier racine de la suite. Pas d'installateur, pas de registre, pas d'environnement virtuel obligatoire.

---

## Utilisation

Double-cliquer sur `DTLmenu.hta`. Windows l'ouvre avec `mshta.exe`.

Sur certains systèmes, Windows peut afficher un avertissement de sécurité au premier lancement. Dans ce cas, clic droit sur le fichier, Propriétés, puis **Débloquer**.

### Définir le dossier racine

En haut de la fenêtre, définir `ROOT_DIR` sur le dossier qui contient les sous-dossiers des outils (`DTLknowsWhy`, `DTLsaysWhat`, `NetDTL`, `GitDTL`, `GitHubMenu`, `DTLaudit`). Cliquer sur **apply** pour propager le chemin.

### Options du menu

| Touche | Action |
|-------|--------|
| 1 | Build DTLknowsWhy : exécutable principal, variante CLI et Agent |
| 2 | Build DTLsaysWhat |
| 3 | NetDTL : informations de chemin, pas de build |
| 4 | Build GitDTL |
| 5 | Build GitHubMenu |
| 6 | Build DTLaudit |
| 7 | Build de tous les outils Python |
| 8 | Ouvrir un dossier `dist\` |
| 9 | Vérifier Python et PyInstaller |
| 0 | Quitter |

### Exécution des builds

Quand vous cliquez sur **exécuter**, DTLmenu génère un script `.cmd` temporaire puis le lance. Les builds utilisent PyInstaller et placent les exécutables dans les dossiers `dist`.

---

## Notes de conception

DTLmenu est une application `.hta` plutôt qu'une page `.html`, car les HTML Applications s'exécutent avec les droits nécessaires pour utiliser `WScript.Shell` et `Scripting.FileSystemObject`. Ces objets COM permettent d'écrire et lancer des scripts `.cmd` et d'ouvrir l'Explorateur Windows.

L'interface utilise un CSS compatible avec le moteur d'Internet Explorer intégré à `mshta.exe`. L'esthétique terminal sombre, vert phosphore et police monospace suit l'identité visuelle de la suite NetDTL.

---

## Licence

MIT - voir le dépôt principal NetDTL pour le texte complet.

Partie de la **suite NetDTL** - [didiermorandi.com/netdtl](https://didiermorandi.com/netdtl)

## Mise à jour - 14 juin 2026

`DTLmenu.hta` est devenu un lanceur HTA complet pour la suite NetDTL.

Nouveautés confirmées :

- Le dossier racine de la suite est enregistré dans `DTLmenu.root`.
- Le sélecteur de dossier permet de corriger le chemin racine sans modifier le fichier HTA.
- Le menu vérifie Python et PyInstaller avant de lancer un build.
- Si PyInstaller manque, l'outil propose `python -m pip install --upgrade pyinstaller`.
- Les builds couverts sont `DTLknowsWhy`, `DTLsaysWhat`, `GitDTL`, `GitHubMenu` et `DTLaudit`.
- Les builds DTLknowsWhy produisent les variantes GUI, CLI et Agent.
- `DTLversion.py` est appelé avant les builds pour gérer la version, avec rollback dans le script temporaire généré.
- `DTLGitMorning.ps1` fournit aussi un résumé Git matinal pour les dépôts de la suite.
