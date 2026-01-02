<div align="center">

# 🎮 Baccalauréat - Le Petit Bac

### Le jeu de lettres et de culture générale – en version mobile

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%26%20Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

<br/>

[🎮 Jeu](#-présentation-du-jeu) • [📱 Aperçu](#-aperçu-de-lapplication) • [⚙️ Fonctionnalités](#️-fonctionnalités) • [🛠 Stack](#-stack-technique) • [🚀 Installation](#-installation) • [👨‍💻 Auteur](#-auteur)

<br/>

> 🎬 **Vidéo démo** : [Regarder sur YouTube](#) | 📱 **Télécharger l'APK** : [Releases](#)

</div>

---

## 📋 À propos

**Baccalauréat** est une application mobile inspirée du célèbre jeu du *Petit Bac*.  
Le projet a été développé avec **Flutter** et **Firebase**, **pour le fun** et dans un **objectif pédagogique**, afin de pratiquer le développement mobile et d'appliquer les acquis précédemment appris.

> ⚠️ **Projet en cours de développement** - Le mode solo est fonctionnel, le mode multijoueur arrive bientôt !

---

## 🎮 Présentation du jeu

- 🎲 Génération d'une **lettre aléatoire**
- 📝 **7 catégories** : Prénom, Pays, Ville, Animal, Fruit/Légume, Objet, Métier
- ⏱️ **Timer configurable** (30s à 180s)
- 🧮 **Calcul automatique des scores**
- 🏆 **Classement global** en temps réel

---

## 📱 Aperçu de l'application

### 🔐 Authentification

| Connexion | Inscription |
|:---:|:---:|
| <img src="screen_shots/cnx.jpeg" width="220"/> | <img src="screen_shots/signin.jpeg" width="220"/> |

---

### 🏠 Tableau de bord

| Dashboard Light | Dashboard Dark |
|:---:|:---:|
| <img src="screen_shots/dashboard2.jpeg" width="220"/> | <img src="screen_shots/dashboard3.jpeg" width="220"/> |

| Dashboard (scroll) |
|:---:|
| <img src="screen_shots/dashboard1.jpeg" width="220"/> |

---

### 🎮 Jeu – Mode Solo

| Configuration partie | Lettres bannies |
|:---:|:---:|
| <img src="screen_shots/newGameSolo1.jpeg" width="220"/> | <img src="screen_shots/newGameSolo2.jpeg" width="220"/> |

| Jeu en cours 1 | Jeu en cours 2 |
|:---:|:---:|
| <img src="screen_shots/gameSolo1.jpeg" width="220"/> | <img src="screen_shots/gameSolo2.jpeg" width="220"/> |

---

### 👥 Mode Multijoueur (🚧 En cours)

| Rejoindre une partie |
|:---:|
| <img src="screen_shots/jointGame.jpeg" width="250"/> |

---

### 🏆 Classement & Historique

| Classement Global | Historique |
|:---:|:---:|
| <img src="screen_shots/classement.jpeg" width="220"/> | <img src="screen_shots/histo.jpeg" width="220"/> |

---

### ⚙️ Paramètres

| Paramètres |
|:---:|
| <img src="screen_shots/params.jpeg" width="250"/> |

---

## ⚙️ Fonctionnalités

### ✅ Implémentées

| Fonctionnalité | Description |
|----------------|-------------|
| 🔐 **Authentification** | Email/Password, Google Sign-In, Mode Invité |
| 🎮 **Mode Solo** | Joue seul pour t'entraîner |
| ⏱️ **Timer Configurable** | 30s à 180s par round |
| 📝 **7 Catégories** | Prénom, Pays, Ville, Animal, Fruit/Légume, Objet, Métier |
| ➕ **Catégories Custom** | Ajoute tes propres catégories |
| 🚫 **Lettres Bannies** | Exclus les lettres difficiles (X, Y, Z...) |
| 😊 **Mode Facile** | Ignore accents, majuscules, tirets |
| 🌙 **Dark/Light Mode** | Thème sombre et clair |
| 🔊 **Audio** | Effets sonores et musique |
| 📊 **Classement Global** | Leaderboard Firestore en temps réel |
| 📜 **Historique** | Consulte tes parties passées |

### 🚧 En cours de développement

| Fonctionnalité | Statut |
|----------------|--------|
| 👥 **Mode Multijoueur** | 🔄 En cours |
| 🗳️ **Système de Vote** | 🔄 En cours |
| ✅ **Validation Réponses** | 🔄 En cours |
| 💬 **Chat en jeu** | 📋 Planifié |

---

## 🛠 Stack technique

| Technologie | Rôle |
|------------|------|
| **Flutter 3.x** | Framework UI cross-platform |
| **Dart** | Langage principal |
| **Firebase Auth** | Authentification (Email, Google, Anonyme) |
| **Cloud Firestore** | Base de données temps réel |
| **Provider** | State Management |

---

## 🏗 Architecture

```
lib/
├── main.dart
├── models/          # Modèles de données
├── screens/         # Écrans de l'app
├── services/        # Services Firebase
├── widgets/         # Composants réutilisables
└── utils/           # Utilitaires et constantes
```

---

## 🚀 Installation

### Prérequis
- Flutter SDK 3.x
- Dart SDK
- Un projet Firebase configuré

### Étapes

```bash
# Cloner le repo
git clone https://github.com/faceoff2003/baccalaureat-flutter.git
cd baccalaureat-flutter

# Installer les dépendances
flutter pub get

# Configurer Firebase (ajouter vos fichiers)
# - android/app/google-services.json
# - ios/Runner/GoogleService-Info.plist

# Lancer l'app
flutter run
```

---

## 🎯 Règles du jeu

1. Une **lettre aléatoire** est tirée
2. Tu as **X secondes** pour trouver un mot commençant par cette lettre pour chaque catégorie
3. **Points** :
    - ✅ Bonne réponse unique = **10 pts**
    - 🤝 Même réponse qu'un autre joueur = **5 pts** (multi)
    - ❌ Pas de réponse / Réponse invalide = **0 pts**
4. Le joueur avec le plus de points gagne ! 🏆

---

## 🎯 Objectif

Projet personnel réalisé pour :
- 🎓 Pratiquer Flutter & Firebase
- 💪 Consolider les acquis en développement mobile
- 📁 Enrichir mon portfolio

---

## 👨‍💻 Auteur

<div align="center">

**William Soulayman**

[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/faceoff2003)
[![Portfolio](https://img.shields.io/badge/Portfolio-FF5722?style=for-the-badge&logo=google-chrome&logoColor=white)](https://soulayman.be)

*Développeur Full Stack - Diplômé en Informatique de Gestion (EAFC Colfontaine, 2025)*

</div>

---

<div align="center">

### ⭐ Si ce projet vous a plu, n'hésitez pas à lui donner une étoile !

<br/>

Made with ❤️ and ☕ in Belgium 🇧🇪

</div>
