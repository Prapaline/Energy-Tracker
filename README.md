Energy Tracker
- Objectif du projet

Energy Tracker est une application web et mobile destinée à suivre la consommation d’énergie des utilisateurs (eau, électricité, gaz). Elle permet d’ajouter des consommations manuellement, d’importer des fichiers CSV et de visualiser l’évolution de ses consommations sous forme de graphiques interactifs. L’objectif est d’aider les utilisateurs à mieux comprendre et gérer leur consommation énergétique.

- Technologies utilisées
Front-end

Flutter / Dart : pour créer une interface utilisateur moderne, responsive et cross-platform (Web et Mobile).

fl_chart : pour les graphiques interactifs de consommation.

Flutter Secure Storage : pour stocker de manière sécurisée le token JWT.

Back-end

Java / Spring Boot : pour gérer l’API REST sécurisée et le traitement des données.
Spring Security & JWT : pour l’authentification sécurisée des utilisateurs.
PostgreSQL : pour la base de données relationnelle stockant les utilisateurs et les consommations.
Maven : pour la gestion des dépendances et la compilation du projet.

Autres outils

GitHub : pour le versioning et la collaboration.

IntelliJ IDEA : pour le développement front-end et back-end.

Fonctionnalités principales

Inscription et authentification sécurisée avec JWT.
Ajout manuel de consommation (eau, électricité, gaz).
Import CSV pour ajouter des consommations par lot.
Visualisation des consommations sous forme de graphiques par jour, mois ou année.
Filtrage par type de consommation.
Stockage sécurisé des tokens sur le client.

Instructions de lancement
Prérequis

Flutter installé (pour le front-end Web et Mobile)
Java 17+ et Maven (pour le back-end)
PostgreSQL (base de données)

Lancement du back-end
Configurer PostgreSQL et créer une base energy_tracker.
Modifier application.properties ou application.yml avec les informations de connexion à la base.
Lancer le projet Spring Boot depuis IntelliJ ou avec :
mvn spring-boot:run


L’API sera disponible par défaut sur http://localhost:8080.

Lancement du front-end

Se placer dans le dossier du front-end Flutter :
cd frontend


Installer les dépendances :

flutter pub get


Lancer l’application Web :

flutter run -d chrome

Pour mobile, connecter un appareil ou utiliser un émulateur et lancer :

flutter run
