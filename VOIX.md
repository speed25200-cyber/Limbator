# Les voix de Limbator

Une application de dictée dépend entièrement de sa voix. Si la synthèse avale
une liaison, escamote un pluriel ou déplace un accent tonique, l'apprenant écrit
ce qu'il a entendu — et se voit corrigé pour une faute qui n'est pas la sienne.
Le choix des moteurs a donc été fait sur ce critère, pas sur le naturel perçu.

## La cascade

Quatre moteurs, essayés dans cet ordre. Le premier qui répond gagne.

| Rang | Moteur | Réseau | Rôle |
|---|---|---|---|
| 1 | **Azure neural fr-FR** — Vivienne / Rémy multilingues | oui | Prosodie expressive sur les phrases longues. **Facultatif.** |
| 2 | **VITS Piper fr_FR** — siwis (féminine), tom (masculine) | non | Le moteur de référence, embarqué dans l'app. |
| 3 | **Apple Premium / Enhanced fr-FR** | non | Pour le français, un très bon palier — pas un pis-aller. |
| 4 | **Apple compacte fr-FR** | non | Toujours présente, toujours intelligible. |

Le rang 3 mérite une note. Pour une langue peu dotée, retomber sur la synthèse
du système donnerait une voix robotique et une app inutilisable. Le français
n'est pas dans ce cas : Apple y consacre des voix neurales de bonne facture,
que l'utilisateur peut télécharger depuis *Réglages › Accessibilité › Contenu
énoncé › Voix*. Limbator affiche d'ailleurs dans son profil quel moteur est
réellement actif, et invite à ce téléchargement quand il est retombé au rang 4.

## Ce que la dictée exige en plus

Quatre modes de lecture, tous appuyés sur la même voix :

- **naturel** — le débit de référence ;
- **ralenti** — sans déformer la hauteur (la vitesse est appliquée à la
  synthèse, pas à la lecture du fichier) ;
- **mot à mot** — chaque mot synthétisé seul, ce qui supprime les liaisons et
  laisse entendre les finales muettes. C'est ainsi qu'un apprenant découvre que
  la liaison lui cachait un pluriel ;
- **épelé** — lettre par lettre, accents nommés : « e accent aigu, l, e accent
  grave, v, e ». Les consonnes doubles sont annoncées comme telles — « deux p »
  — parce que c'est ainsi qu'on les retient, et parce que c'est la faute
  numéro un d'un locuteur roumain.

Toutes les sorties sont mises en cache sur disque. La latence en profite, mais
ce n'est pas la raison principale : en dictée, l'apprenant réécoute la même
phrase cinq ou six fois, et elle doit sonner **exactement** pareil à chaque
fois. Une variation de synthèse se confondrait avec une différence de contenu.

## Installation des modèles embarqués

```bash
./scripts/download_voice.sh
```

Le script récupère les archives prêtes à l'emploi publiées par sherpa-onnx et
installe dans `Limbator/Resources/Voice/` :

```
fr_female.onnx          fr_female_tokens.txt      (siwis)
fr_male.onnx            fr_male_tokens.txt        (tom)
espeak-ng-data/                                   (phonémiseur, partagé)
```

`espeak-ng-data` n'est pas optionnel : Piper phonémise le texte avant de le
synthétiser. Sans ce dossier le moteur se charge sans erreur et ne prononce
rien d'intelligible — un mode de panne silencieux, donc le pire. Le script
vérifie sa présence, et la CI vérifie que les trois éléments sont bien dans
l'IPA avant toute distribution.

Ces fichiers ne sont **pas** versionnés : environ 150 Mo, et reproductibles par
une commande.

## Licences

| Élément | Licence | Obligation |
|---|---|---|
| Piper `fr_FR-siwis-medium` | CC BY 4.0 | Attribution |
| Piper `fr_FR-tom-medium` | CC BY 4.0 | Attribution |
| espeak-ng | GPL v3 | Voir ci-dessous |
| Azure Speech | commercial | Compte Azure de l'utilisateur |

espeak-ng est distribué sous GPL v3. Il est ici **exécuté** comme phonémiseur
via sherpa-onnx, et ses données sont copiées telles quelles dans le paquet.
Avant toute publication commerciale, faites confirmer par un juriste que ce
mode d'usage convient à votre distribution — ou remplacez la cascade embarquée
par un modèle sans espeak (MMS-TTS français, à base de caractères), au prix
d'une qualité inférieure.

## La clé Azure

**Aucune clé n'est inscrite dans ce dépôt.** Une clé versionnée est une clé
compromise, quelles que soient les précautions annoncées autour.

Deux façons de l'apporter, au choix :

1. **Depuis l'app** — Profil › Voix Azure. La clé reste sur l'appareil.
2. **À la construction** — définir `AZURE_SPEECH_KEY` et `AZURE_SPEECH_REGION`
   comme variables secrètes dans Codemagic. Elles sont injectées dans
   `Info.plist` au moment de l'archivage et n'apparaissent jamais dans git.

Sans clé, Limbator fonctionne intégralement avec la voix neurale embarquée.
Azure est un supplément, jamais un prérequis.
