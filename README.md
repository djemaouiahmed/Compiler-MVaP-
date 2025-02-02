# Compilateur Complexe - Projet Compilation

## Description
Ce projet implémente un compilateur pour un langage manipulant des nombres complexes et des booléens. Le compilateur traduit le code source en instructions MVaP.

## Fonctionnalités
- Déclaration de variables `complexe` et `bool`
- Affectations et ré-affectations
- Expressions complexes avec addition, soustraction, multiplication, division et puissance `**`
- Comparaisons booléennes `==`, `!=`, `<`, `>`, `<=`, `>=`
- Instructions conditionnelles (`lorsque ... faire ... autrement`)
- Boucles (`repeter ... jusque ... sinon`)
- Entrée / sortie (`lire()` et `afficher()`)

## Installation et Exécution
### Prérequis :
- **ANTLR4** installé
- **Java** installé

### Compilation :
```sh
antlr4 Complexe.g4 && javac Complexe*.java
```
Compiler le fichier :
```sh
antlr4 Complexe.g4 && javac Complexe*.java
```
Exécuter un test :
```sh
grun Complexe start -gui
```
## Tests
Utiliser test.txt pour vérifier le bon fonctionnement du compilateur :
```txt
complexe z;
z = 3 + i4;
afficher(z);
z = z ** 2;
afficher(z);
```
## resultat:
```terminal
3.0 + 4.0i
-7.0 + 24.0i
```
## Remarques
Assurez-vous que votre fichier Complexe.g4 est bien formatté.
En cas d'erreur, vérifiez les messages d'erreur et corrigez la grammaire si nécessaire.

## Auteur
Nom : Djemaoui Ahmed
Projet : Compilateur ANTLR4 pour le langage Complexe
Année : 2024-2025
