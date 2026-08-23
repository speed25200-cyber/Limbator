#!/usr/bin/env python3
"""Génère Limbator/Utilities/Localizer.swift à partir d'une table unique.

Trois langues d'interface, une seule source : impossible qu'une clé existe en
roumain et manque en français. Relancer après toute modification :

    python3 scripts/gen_localizer.py
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# clé -> (roumain, français, anglais)
STRINGS = {
    # ---- Navigation --------------------------------------------------------
    "tab.home":      ("Acasă", "Accueil", "Home"),
    "tab.lessons":   ("Lecții", "Leçons", "Lessons"),
    "tab.ortho":     ("Ortografie", "Orthographe", "Spelling"),
    "tab.games":     ("Jocuri", "Jeux", "Games"),
    "tab.profile":   ("Profil", "Profil", "Profile"),

    # ---- Moteur Gemma ------------------------------------------------------
    "gemma.status.starting":  ("Pornim motorul…", "Démarrage du moteur…", "Starting the engine…"),
    "gemma.status.ready":     ("Gata", "Prêt", "Ready"),
    "gemma.status.offline":   ("Mod offline · conținut local", "Mode hors ligne · contenu local", "Offline mode · local content"),
    "gemma.status.preparing": ("Pregătim modelul…", "Préparation du modèle…", "Preparing the model…"),
    "gemma.status.loading":   ("Încărcăm modelul în memorie…", "Chargement du modèle en mémoire…", "Loading the model into memory…"),
    "gemma.status.downloading":         ("Descărcăm %@…", "Téléchargement de %@…", "Downloading %@…"),
    "gemma.status.downloading_percent": ("Descărcăm %@ · %d %%", "Téléchargement de %@ · %d %%", "Downloading %@ · %d%%"),
    "gemma.error.not_ready":        ("Gemma nu este încă pregătit.", "Gemma n'est pas encore prêt.", "Gemma is not ready yet."),
    "gemma.error.bad_json":         ("Răspuns JSON invalid: %@…", "Réponse JSON invalide : %@…", "Invalid JSON reply: %@…"),
    "gemma.error.download":         ("Descărcarea modelului a eșuat: %@", "Le téléchargement du modèle a échoué : %@", "Model download failed: %@"),
    "gemma.error.incomplete":       ("descărcare incompletă", "téléchargement incomplet", "incomplete download"),
    "gemma.error.repeated_failure": ("Gemma nu s-a putut încărca de mai multe ori — modul offline este activ. Reîncearcă din setări.", "Gemma n'a pas pu se charger à plusieurs reprises — le mode hors ligne est actif. Réessaie depuis les réglages.", "Gemma failed to load several times — offline mode is on. Retry from settings."),
    "gemma.retry":         ("Reîncearcă", "Réessayer", "Retry"),
    "gemma.failed_title":  ("Gemma indisponibil", "Gemma indisponible", "Gemma unavailable"),
    "gemma.first_launch":  ("Prima pornire · o singură descărcare", "Premier lancement · téléchargement unique", "First launch · one-time download"),

    # ---- Téléchargement ----------------------------------------------------
    "download.error.empty":    ("Depozitul nu conține niciun fișier.", "Le dépôt ne contient aucun fichier.", "The repository contains no files."),
    "download.error.url":      ("Adresă invalidă.", "Adresse invalide.", "Invalid address."),
    "download.error.http":     ("Eroare HTTP %d. Verifică conexiunea.", "Erreur HTTP %d. Vérifie ta connexion.", "HTTP error %d. Check your connection."),
    "download.error.checksum": ("Verificarea integrității a eșuat pentru %@.", "La vérification d'intégrité a échoué pour %@.", "Integrity check failed for %@."),

    # ---- Voix --------------------------------------------------------------
    "tts.diag.azure":          ("Voce neurală Azure fr-FR · online", "Voix neurale Azure fr-FR · en ligne", "Azure neural fr-FR voice · online"),
    "tts.diag.neural":         ("Voce neurală franceză pe dispozitiv", "Voix neurale française sur l'appareil", "On-device French neural voice"),
    "tts.diag.apple_premium":  ("Voce Apple Premium fr-FR", "Voix Apple Premium fr-FR", "Apple Premium fr-FR voice"),
    "tts.diag.apple_compact":  ("Voce iOS compactă fr-FR — descarcă vocea Premium din Setări iOS pentru o calitate mai bună", "Voix iOS compacte fr-FR — télécharge la voix Premium dans les Réglages iOS pour une meilleure qualité", "Compact iOS fr-FR voice — download the Premium voice in iOS Settings for better quality"),

    # ---- Onboarding --------------------------------------------------------
    "onboarding.tagline":       ("Învață franceza din română,\ncu o IA care scrie corect", "Apprends le français depuis le roumain,\navec une IA qui écrit juste", "Learn French from Romanian,\nwith an AI that spells correctly"),
    "onboarding.badge_gemma":       ("Gemma 4 · 4B", "Gemma 4 · 4B", "Gemma 4 · 4B"),
    "onboarding.badge_offline":     ("100% offline", "100 % hors ligne", "100% offline"),
    "onboarding.badge_voice":       ("Voce neurală", "Voix neurale", "Neural voice"),
    "onboarding.badge_voice_sub":   ("franceză nativă", "français natif", "native French"),
    "onboarding.badge_ortho":       ("Ortografie", "Orthographe", "Spelling"),
    "onboarding.badge_ortho_sub":   ("dictare și acorduri", "dictée et accords", "dictation and agreement"),
    "onboarding.ask_name":          ("Cum să îți spun?", "Comment dois-je t'appeler ?", "What should I call you?"),
    "onboarding.name_placeholder":  ("Prenumele tău", "Ton prénom", "Your first name"),
    "onboarding.native_language_title":    ("Limba ta maternă", "Ta langue maternelle", "Your native language"),
    "onboarding.native_language_subtitle": ("Totul îți va fi explicat în această limbă.", "Tout te sera expliqué dans cette langue.", "Everything will be explained in this language."),
    "onboarding.level_title":       ("Ce nivel ai la franceză?", "Quel est ton niveau en français ?", "What is your level in French?"),
    "onboarding.level_subtitle":    ("Nicio grijă — ne ajustăm din mers.", "Aucune inquiétude — on s'ajuste en route.", "No worries — we adjust as we go."),
    "onboarding.goal_title":        ("Obiectivul tău zilnic", "Ton objectif quotidien", "Your daily goal"),
    "onboarding.goal_subtitle":     ("Regularitatea bate intensitatea.", "La régularité bat l'intensité.", "Consistency beats intensity."),
    "onboarding.minutes_per_day":   ("minute pe zi", "minutes par jour", "minutes per day"),
    "onboarding.back":              ("Înapoi", "Retour", "Back"),
    "onboarding.continue":          ("Continuă", "Continuer", "Continue"),
    "onboarding.start":             ("Începem", "C'est parti", "Let's go"),

    # ---- Accueil -----------------------------------------------------------
    "home.default_name":       ("Prietene", "Ami", "Friend"),
    "home.greeting_morning":   ("Bonjour", "Bonjour", "Bonjour"),
    "home.greeting_afternoon": ("Bon après-midi", "Bon après-midi", "Bon après-midi"),
    "home.greeting_evening":   ("Bonsoir", "Bonsoir", "Bonsoir"),
    "home.stat_days":     ("zile", "jours", "days"),
    "home.stat_xp":       ("XP", "XP", "XP"),
    "home.stat_level":    ("nivel", "niveau", "level"),
    "home.stat_average":  ("medie", "moyenne", "average"),
    "home.dictation_title":    ("Dictarea zilei", "La dictée du jour", "Today's dictation"),
    "home.dictation_badge":    ("+120 XP fără greșeli", "+120 XP sans faute", "+120 XP if flawless"),
    "home.dictation_cta":      ("Ascultă și scrie", "Écoute et écris", "Listen and write"),
    "home.quick_title":        ("Continuă rapid", "Reprends vite", "Pick up quickly"),
    "home.tile_dictation":     ("Dictare", "Dictée", "Dictation"),
    "home.tile_dictation_sub": ("Scrie ce auzi", "Écris ce que tu entends", "Write what you hear"),
    "home.tile_homophone":     ("Duel de homofone", "Duel d'homophones", "Homophone duel"),
    "home.tile_homophone_sub": ("a sau à ?", "a ou à ?", "a or à?"),
    "home.tile_tutor":         ("Tutorul IA", "Le tuteur IA", "AI tutor"),
    "home.tile_tutor_sub":     ("Întreabă orice", "Demande ce que tu veux", "Ask anything"),
    "home.tile_story":         ("Povești", "Histoires", "Stories"),
    "home.tile_story_sub":     ("Franceza în context", "Le français en contexte", "French in context"),
    "home.word_of_day_title":  ("Cuvântul zilei", "Le mot du jour", "Word of the day"),
    "home.review_title":       ("De revăzut azi", "À revoir aujourd'hui", "Due for review today"),
    "home.review_subtitle":    ("%d reguli te așteaptă", "%d règles t'attendent", "%d rules are waiting"),
    "home.review_empty":       ("Nimic de revăzut azi. Ai fost la zi.", "Rien à revoir aujourd'hui. Tu es à jour.", "Nothing to review today. You're up to date."),
    "home.weakness_title":     ("Punctul tău slab", "Ton point faible", "Your weak spot"),
    "home.weakness_none":      ("Încă nu ai făcut destule greșeli ca să spun.", "Tu n'as pas encore fait assez de fautes pour que je me prononce.", "You haven't made enough mistakes for me to say yet."),
    "home.stories_title":      ("Povești", "Histoires", "Stories"),
    "home.stories_all":        ("Toate poveștile", "Toutes les histoires", "All stories"),
    "home.start":              ("Începe", "Commencer", "Start"),

    # ---- Leçons ------------------------------------------------------------
    "lessons.title":      ("Parcurs", "Parcours", "Path"),
    "lessons.subtitle":   ("14 lecții, fiecare cu punctul ei de ortografie", "14 leçons, chacune avec son point d'orthographe", "14 lessons, each with its spelling focus"),
    "lessons.filter_all": ("Toate", "Toutes", "All"),
    "lessons.minutes":    ("%d min", "%d min", "%d min"),
    "lesson.intro":          ("Introducere", "Introduction", "Introduction"),
    "lesson.vocabulary":     ("Vocabular", "Vocabulaire", "Vocabulary"),
    "lesson.phrases":        ("Expresii utile", "Expressions utiles", "Useful phrases"),
    "lesson.grammar_tip":    ("Sfat de gramatică", "Astuce de grammaire", "Grammar tip"),
    "lesson.cultural_note":  ("Notă culturală", "Note culturelle", "Cultural note"),
    "lesson.ortho_spotlight": ("Punctul de ortografie", "Le point d'orthographe", "Spelling focus"),
    "lesson.mark_complete":  ("Marchează ca terminată · +50 XP", "Marquer comme terminée · +50 XP", "Mark as done · +50 XP"),
    "lesson.completed":      ("Terminată", "Terminée", "Done"),
    "lesson.loading":        ("Gemma pregătește lecția…", "Gemma prépare la leçon…", "Gemma is preparing the lesson…"),
    "lesson.flip":           ("Întoarce", "Retourner", "Flip"),
    "lesson.translation":    ("Traducere", "Traduction", "Translation"),
    "lesson.example":        ("Exemplu", "Exemple", "Example"),
    "lesson.spelling_note":  ("Capcana de scriere", "Le piège d'écriture", "Spelling trap"),
    "lesson.card_index":     ("%d / %d", "%d / %d", "%d / %d"),
    "lesson.right":          ("Corect", "Juste", "Right"),
    "lesson.wrong":          ("Greșit", "Faux", "Wrong"),

    # ---- Orthographe -------------------------------------------------------
    "ortho.title":        ("Ortografie", "Orthographe", "Spelling"),
    "ortho.subtitle":     ("Opt șantiere. Fiecare greșeală devine o lecție.", "Huit chantiers. Chaque faute devient une leçon.", "Eight areas. Every mistake becomes a lesson."),
    "ortho.mastery":      ("Stăpânire", "Maîtrise", "Mastery"),
    "ortho.modules":      ("Module", "Modules", "Modules"),
    "ortho.dictation":    ("Dictare", "Dictée", "Dictation"),
    "ortho.dictation_sub": ("Ascultă, scrie, primește corectura", "Écoute, écris, reçois la correction", "Listen, write, get corrected"),
    "ortho.train":        ("Antrenează-te", "S'entraîner", "Practise"),
    "ortho.rules":        ("Reguli", "Règles", "Rules"),
    "ortho.drills":       ("Exerciții", "Exercices", "Exercises"),
    "ortho.rule_examples":   ("Exemple", "Exemples", "Examples"),
    "ortho.rule_exceptions": ("Excepții", "Exceptions", "Exceptions"),
    "ortho.mnemonic":     ("De reținut", "À retenir", "Remember"),
    "ortho.check":        ("Verifică", "Vérifier", "Check"),
    "ortho.next":         ("Următorul", "Suivant", "Next"),
    "ortho.correct":      ("Corect", "Juste", "Correct"),
    "ortho.incorrect":    ("Nu chiar", "Pas tout à fait", "Not quite"),
    "ortho.explanation":  ("De ce", "Pourquoi", "Why"),
    "ortho.your_answer":  ("Ce ai scris", "Ce que tu as écrit", "What you wrote"),
    "ortho.expected":     ("Forma corectă", "La forme correcte", "The correct form"),
    "ortho.score":        ("Nota", "Note", "Score"),
    "ortho.out_of_20":    ("%@ / 20", "%@ / 20", "%@ / 20"),
    "ortho.replay":       ("Ascultă din nou", "Réécouter", "Play again"),
    "ortho.slower":       ("Mai rar", "Plus lentement", "Slower"),
    "ortho.word_by_word": ("Cuvânt cu cuvânt", "Mot à mot", "Word by word"),
    "ortho.spell_it":     ("Litera cu literă", "Lettre par lettre", "Letter by letter"),
    "ortho.hint":         ("Indiciu", "Indice", "Hint"),
    "ortho.show_translation": ("Arată traducerea", "Voir la traduction", "Show translation"),
    "ortho.submit":       ("Corectează-mă", "Corrige-moi", "Correct me"),
    "ortho.finish":       ("Termină", "Terminer", "Finish"),
    "ortho.mistakes_title": ("Greșelile tale", "Tes fautes", "Your mistakes"),
    "ortho.perfect":      ("Nicio greșeală. Impecabil.", "Aucune faute. Impeccable.", "Not one mistake. Flawless."),
    "ortho.review_rule":  ("Revezi regula", "Revoir la règle", "Review the rule"),
    "ortho.type_here":    ("Scrie aici ce auzi…", "Écris ici ce que tu entends…", "Type what you hear…"),
    "ortho.mastered":     ("Stăpânit", "Maîtrisé", "Mastered"),
    "ortho.not_started":  ("Neînceput", "Pas commencé", "Not started"),
    "ortho.due_now":      ("De revăzut", "À revoir", "Due"),
    "ortho.rules_count":  ("%d reguli", "%d règles", "%d rules"),
    "ortho.drills_count": ("%d exerciții", "%d exercices", "%d exercises"),
    "ortho.session_done": ("Sesiune terminată", "Séance terminée", "Session complete"),
    "ortho.accuracy":     ("Acuratețe", "Précision", "Accuracy"),
    "ortho.again":        ("Încă o serie", "Encore une série", "Another round"),
    "ortho.choose_level": ("Alege dificultatea", "Choisis la difficulté", "Choose difficulty"),
    "ortho.no_drills":    ("Niciun exercițiu pentru acest modul deocamdată.", "Aucun exercice pour ce module pour l'instant.", "No exercises for this module yet."),

    # ---- Jeux --------------------------------------------------------------
    "games.title":     ("Jocuri", "Jeux", "Games"),
    "games.subtitle":  ("Zece moduri de a exersa fără să pară temă", "Dix façons de réviser sans que ça ressemble à un devoir", "Ten ways to practise without it feeling like homework"),
    "game.score":      ("Scor", "Score", "Score"),
    "game.streak":     ("Serie", "Série", "Streak"),
    "game.round":      ("Runda %d / %d", "Manche %d / %d", "Round %d / %d"),
    "game.finish":     ("Gata", "Terminer", "Finish"),
    "game.replay":     ("Din nou", "Rejouer", "Play again"),
    "game.correct":    ("Corect", "Juste", "Correct"),
    "game.wrong":      ("Greșit", "Faux", "Wrong"),
    "game.tap_start":  ("Atinge ca să începi", "Touche pour commencer", "Tap to start"),
    "game.loading":    ("Pregătim runda…", "Préparation de la manche…", "Preparing the round…"),
    "game.result":     ("%d din %d", "%d sur %d", "%d out of %d"),
    "game.perfect":    ("Fără nicio greșeală.", "Sans la moindre faute.", "Not a single mistake."),
    "game.xp_earned":  ("+%d XP", "+%d XP", "+%d XP"),
    "game.hold_record": ("Ține apăsat ca să înregistrezi", "Maintiens pour enregistrer", "Hold to record"),
    "game.listening":  ("Te ascult…", "Je t'écoute…", "Listening…"),
    "game.mic_denied": ("Microfonul nu este permis. Activează-l din Setări.", "Le micro n'est pas autorisé. Active-le dans les Réglages.", "Microphone not allowed. Enable it in Settings."),
    "game.spin":       ("Învârte roata", "Tourner la roue", "Spin the wheel"),
    "game.build_sentence": ("Construiește fraza", "Construis la phrase", "Build the sentence"),
    "game.reset":      ("Reia", "Recommencer", "Reset"),

    # ---- Histoires ---------------------------------------------------------
    "stories.title":     ("Povești", "Histoires", "Stories"),
    "stories.subtitle":  ("Patru povestiri franceze — două dintre ele, românești la origine.", "Quatre récits français — deux d'entre eux venus de Roumanie.", "Four French stories — two of them Romanian at heart."),
    "stories.featured":  ("ÎN PRIM-PLAN", "À LA UNE", "FEATURED"),
    "stories.all":       ("Toate poveștile", "Toutes les histoires", "All stories"),
    "stories.chapters":  ("%d capitole", "%d chapitres", "%d chapters"),
    "stories.minutes":   ("%d min", "%d min", "%d min"),
    "story.chapter":     ("Capitolul %d", "Chapitre %d", "Chapter %d"),
    "story.scene_index": ("Scena %d / %d", "Scène %d / %d", "Scene %d / %d"),
    "story.loading":     ("Gemma scrie scena…", "Gemma écrit la scène…", "Gemma is writing the scene…"),
    "story.previous":    ("Înapoi", "Précédent", "Previous"),
    "story.next":        ("Mai departe", "Suivant", "Next"),
    "story.finish":      ("Termină capitolul", "Terminer le chapitre", "Finish the chapter"),
    "story.vocab":       ("Cuvinte cheie", "Mots clés", "Key words"),
    "story.ortho_note":  ("Oprire pe cuvânt", "Arrêt sur mot", "Word close-up"),
    "story.translation": ("Traducere", "Traduction", "Translation"),

    # ---- Profil ------------------------------------------------------------
    "profile.default_name":  ("Prietene", "Ami", "Friend"),
    "profile.level_label":   ("Nivel %d", "Niveau %d", "Level %d"),
    "profile.xp_label":      ("%d XP", "%d XP", "%d XP"),
    "profile.xp_to_next":    ("%d până la nivelul %d", "%d avant le niveau %d", "%d to level %d"),
    "profile.stat_streak":   ("Zile la rând", "Jours d'affilée", "Day streak"),
    "profile.stat_lessons":  ("Lecții", "Leçons", "Lessons"),
    "profile.stat_badges":   ("Insigne", "Badges", "Badges"),
    "profile.stat_dictations": ("Dictări", "Dictées", "Dictations"),
    "profile.rewards_title": ("Recompense", "Récompenses", "Rewards"),
    "profile.mistakes_title": ("Profilul greșelilor tale", "Le profil de tes fautes", "Your mistake profile"),
    "profile.mistakes_empty": ("Nicio greșeală înregistrată. Începe o dictare.", "Aucune faute enregistrée. Commence une dictée.", "No mistakes recorded. Start a dictation."),
    "profile.mistakes_count": ("%d greșeli", "%d fautes", "%d mistakes"),
    "profile.voice_title":   ("Vocea", "La voix", "Voice"),
    "profile.voice_speed":   ("Viteză", "Vitesse", "Speed"),
    "profile.voice_gender":  ("Timbru", "Timbre", "Timbre"),
    "profile.voice_ondevice": ("Doar pe dispozitiv", "Sur l'appareil uniquement", "On-device only"),
    "profile.voice_ondevice_sub": ("Nicio cerere spre internet pentru voce.", "Aucune requête réseau pour la voix.", "No network request for the voice."),
    "profile.azure_title":   ("Voce Azure (opțional)", "Voix Azure (facultatif)", "Azure voice (optional)"),
    "profile.azure_hint":    ("Adaugă o cheie Azure Speech pentru vocea neurală expresivă. Fără ea, Limbator folosește vocea neurală de pe dispozitiv.", "Ajoute une clé Azure Speech pour la voix neurale expressive. Sans elle, Limbator utilise la voix neurale de l'appareil.", "Add an Azure Speech key for the expressive neural voice. Without it, Limbator uses the on-device neural voice."),
    "profile.azure_key":     ("Cheie Azure Speech", "Clé Azure Speech", "Azure Speech key"),
    "profile.azure_region":  ("Regiune (ex. westeurope)", "Région (ex. westeurope)", "Region (e.g. westeurope)"),
    "profile.azure_save":    ("Salvează și testează", "Enregistrer et tester", "Save and test"),
    "profile.azure_clear":   ("Șterge cheia", "Effacer la clé", "Clear the key"),
    "profile.native_language_title": ("Limba maternă", "Langue maternelle", "Native language"),
    "profile.level_title":   ("Nivelul tău", "Ton niveau", "Your level"),
    "profile.gemma_title":   ("Modelul Gemma 4", "Le modèle Gemma 4", "The Gemma 4 model"),
    "profile.gemma_ready":   ("Pregătit · 100% offline", "Prêt · 100 % hors ligne", "Ready · 100% offline"),
    "profile.gemma_loading": ("Se descarcă / se încarcă…", "Téléchargement / chargement…", "Downloading / loading…"),
    "profile.gemma_failed":  ("Eșuat — atinge pentru a reîncerca", "Échec — touche pour réessayer", "Failed — tap to retry"),
    "profile.tutor_title":   ("Tutorul IA", "Le tuteur IA", "AI tutor"),
    "profile.tutor_subtitle": ("Discută, întreabă, cere exemple", "Discute, demande, réclame des exemples", "Chat, ask, request examples"),
    "profile.cache_title":   ("Cache audio", "Cache audio", "Audio cache"),
    "profile.cache_clear":   ("Golește (%@)", "Vider (%@)", "Clear (%@)"),
    "profile.reset_title":   ("Resetează profilul", "Réinitialiser le profil", "Reset profile"),
    "profile.reset_subtitle": ("Șterge tot și ia-o de la capăt", "Tout effacer et recommencer", "Erase everything and start over"),
    "profile.reset_confirm": ("Resetezi tot?", "Tout réinitialiser ?", "Reset everything?"),
    "profile.reset_action":  ("Resetează", "Réinitialiser", "Reset"),
    "profile.cancel":        ("Anulează", "Annuler", "Cancel"),
    "profile.mastery_title": ("Stăpânirea modulelor", "Maîtrise des modules", "Module mastery"),
    "profile.words_tracked": ("%d cuvinte urmărite", "%d mots suivis", "%d words tracked"),

    # ---- Tuteur ------------------------------------------------------------
    "tutor.title":       ("Tutor", "Tuteur", "Tutor"),
    "tutor.badge":       ("Gemma 4 · pe dispozitiv", "Gemma 4 · sur l'appareil", "Gemma 4 · on-device"),
    "tutor.placeholder": ("Întreabă orice despre franceză…", "Demande ce que tu veux sur le français…", "Ask anything about French…"),
    "tutor.greeting":    ("Bonjour ! Te ajut în %@.\n\nPot să îți explic:\n• de ce se scrie « à » și nu « a »\n• acordul participiului trecut\n• un cuvânt, o expresie, o regulă\n• de ce franceza dublează consoanele", "Bonjour ! Je t'aide en %@.\n\nJe peux t'expliquer :\n• pourquoi « à » et pas « a »\n• l'accord du participe passé\n• un mot, une expression, une règle\n• pourquoi le français double ses consonnes", "Bonjour! I'll help you in %@.\n\nI can explain:\n• why “à” and not “a”\n• past participle agreement\n• a word, a phrase, a rule\n• why French doubles its consonants"),
    "tutor.unavailable": ("\n\n[Gemma indisponibil: %@]\n\nModelul se descarcă la prima pornire. Conținutul local rămâne disponibil.", "\n\n[Gemma indisponible : %@]\n\nLe modèle se télécharge au premier lancement. Le contenu local reste disponible.", "\n\n[Gemma unavailable: %@]\n\nThe model downloads on first launch. Local content stays available."),
    "tutor.downloading": ("\n\nModelul Gemma se descarcă… %d %%\nÎncearcă din nou într-un moment.", "\n\nLe modèle Gemma se télécharge… %d %%\nRéessaie dans un instant.", "\n\nThe Gemma model is downloading… %d%%\nTry again in a moment."),
    "tutor.warming":     ("\n\nGemma pornește…\nÎncearcă din nou într-un moment.", "\n\nGemma démarre…\nRéessaie dans un instant.", "\n\nGemma is starting…\nTry again in a moment."),
    "tutor.send":        ("Trimite", "Envoyer", "Send"),
    "tutor.stop":        ("Oprește", "Arrêter", "Stop"),

    # ---- Composants --------------------------------------------------------
    "component.listen":   ("Ascultă", "Écouter", "Listen"),
    "component.spell":    ("Litera cu literă", "Lettre par lettre", "Letter by letter"),
    "component.slow":     ("Mai rar", "Plus lentement", "Slower"),
    "component.close":    ("Închide", "Fermer", "Close"),
    "component.continue": ("Continuă", "Continuer", "Continue"),
    "component.new_badge": ("Insignă nouă", "Nouveau badge", "New badge"),
}

SWIFT_HEADER = '''import Foundation

/// Les chaînes de l'interface, dans les trois langues d'affichage de Limbator.
///
/// La langue suit le **profil**, pas la locale du téléphone : un Roumain
/// installé à Lyon a son iPhone en français et veut malgré tout que la
/// pédagogie lui parle roumain. Le repli se fait sur l'anglais, puis sur la clé
/// elle-même — une clé oubliée s'affiche donc telle quelle, ce qui la rend
/// visible au lieu de la faire disparaître silencieusement.
///
/// FICHIER GÉNÉRÉ — ne pas modifier à la main.
/// Source : scripts/gen_localizer.py  ·  Régénérer : python3 scripts/gen_localizer.py
enum L {

    /// Code de la langue courante ("ro", "fr", "en"). Mis à jour depuis le profil.
    static var lang: String = "ro"

    static func t(_ key: String) -> String {
        table(for: lang)[key] ?? tableEN[key] ?? key
    }

    /// Variante interpolée (%@ / %d).
    static func t(_ key: String, _ args: CVarArg...) -> String {
        String(format: t(key), arguments: args)
    }

    /// Les langues romanes proches retombent sur le français plutôt que sur
    /// l'anglais : un italophone lit bien mieux « Orthographe » que « Spelling ».
    private static func table(for code: String) -> [String: String] {
        switch code {
        case "ro": return tableRO
        case "fr": return tableFR
        case "en": return tableEN
        case "it", "es", "pt": return tableFR
        default:   return tableEN
        }
    }

    /// Les clés déclarées — utilisé par les tests pour vérifier que les trois
    /// tables restent alignées.
    static var allKeys: [String] { Array(tableRO.keys).sorted() }
'''


def escape(value: str) -> str:
    return (value.replace("\\", "\\\\")
                 .replace('"', '\\"')
                 .replace("\n", "\\n"))


def emit_table(name: str, index: int) -> str:
    lines = [f"\n    private static let {name}: [String: String] = ["]
    for key, values in STRINGS.items():
        lines.append(f'        "{key}": "{escape(values[index])}",')
    lines.append("    ]")
    return "\n".join(lines)


def main():
    parts = [SWIFT_HEADER,
             emit_table("tableRO", 0),
             emit_table("tableFR", 1),
             emit_table("tableEN", 2),
             "}\n"]
    out = ROOT / "Limbator/Utilities/Localizer.swift"
    out.write_text("\n".join(parts))
    print(f"{out.relative_to(ROOT)} — {len(STRINGS)} clés x 3 langues")


if __name__ == "__main__":
    main()
