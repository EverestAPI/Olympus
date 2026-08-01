function cjk_priority()
    return {
        "data/fonts/NotoSansJP-Regular.otf",
        "data/fonts/NotoSansKR-Regular.otf",
        "data/fonts/NotoSansSC-Regular.otf",
        "data/fonts/NotoSansTC-Regular.otf"
    }
end

local keys = {
    -- super common keys
    ok = [[OK]],
    cancel = [[Annuler]],
    yes = [[Oui]],
    no = [[Non]],
    loading = [[Chargement]],
    close = [[Fermer]],

    -- dragndrop.lua
    olympus_is_currently_busy_with_something = [[Olympus est actuellement occupé avec autre chose.]],
    olympus_can_t_handle_that_file_does_it_e = [[Olympus ne sait pas gérer ce fichier - est-ce qu'il existe ?]],
    everest_successfully_installed = [[Everest installé avec succès]],
    launch = [[Lancer]],
    olympus_can_t_handle_that_file = [[Olympus ne sait pas gérer ce fichier.]],
    your_celeste_installation_list_is_still_ = [[Ta liste d'installations de Celeste est toujours vide.
Veux-tu aller au gestionnaire d'installations ?]],

    -- main.lua
    olympus_sharp_startup_error = [[Erreur de démarrage de Olympus.Sharp]],
    failed_loading_olympus_sharp = [[Échec de chargement de Olympus.Sharp : ]],
    open_everest_website = [[Ouvrir le site d'Everest]],
    do_you_want_to_close_olympus = [[Veux-tu fermer Olympus ?]],
    the_olympus_app_is_out_of_date_sometimes = [[L'application Olympus n'est pas à jour.
Parfois, de nouvelles fonctionnalités et d'importants correctifs
demandent une mise à jour en profondeur d'Olympus, et Olympus
ne peut pas installer ces mises à jour lui-même.
Notamment, les boutons d'installation 1-Click sur GameBanana étaient
non fonctionnels sur macOS. Pour corriger ça, tu dois réinstaller Olympus.
Merci d'aller sur le site d'Everest pour plus d'informations.
Ne pas mettre à jour Olympus pourrait causer des plantages à l'avenir.]],
    olympus_is_not_completely_up_to_date_you = [[Olympus n'est pas complètement à jour.
Tu risques de rencontrer des erreurs en essayant de lancer Celeste ou Lönn depuis Olympus.

Les mises à jour intégrées dans Olympus ne mettent pas à jour tous les fichiers.
Pour corriger le problème, suis les instructions sur le site d'Everest pour réinstaller Olympus.]],

    -- modinstaller.lua
    preparing_installation_of_s = [[Préparation de l'installation de %s]],
    olympus_isn_t_fully_installed_please_run = [[Olympus n'est pas complètement installé.
Lance install.sh pour installer le gestionnaire d'installation 1-Click.
install.sh se trouve dans le dossier d'installation d'Olympus.]],

    -- modupdater.lua
    updating_enabled_mods = [[Mise à jour des mods activés]],
    updating_all_mods = [[Mise à jour de tous les mods]],
    please_wait = [[Chargement en cours...]],
    skip = [[Passer]],
    retry = [[Réessayer]],
    open_logs_folder = [[Ouvrir le dossier des logs]],
    run_anyway = [[Lancer quand même]],
    an_error_occurred_while_updating_your_mo = [[Une erreur est survenue lors de la mise à jour de tes mods.
Assure-toi d'être connecté à Internet et que Lönn n'est pas ouvert !]],

    -- updater.lua
    cannot_determine_currently_running_versi = [[Impossible de déterminer la version actuelle d'Olympus !]],
    checking_for_updates = [[Vérification des mises à jour...]],
    error_downloading_builds_list = [[Impossible de téléchargement la liste des versions : ]],
    error_downloading_builds_list_invalid_ol = [[Impossible de téléchargement la liste des versions : propriété manquante]],
    currently_installed_n = [[Version actuelle :
]],
    newest_available_n = [[Dernière version :
]],
    changelog_n = [[Description des changements :
]],
    downloading = [[Téléchargement...]],
    failed_to_download_n = [[Le téléchargement a échoué :
]],
    no_updates_found = [[Olympus est à jour.]],
    preparing_update_of_olympus = [[Préparation de la mise à jour d'Olympus]],
    olympus_successfully_updated = [[Olympus mis à jour avec succès]],
    restart_olympus = [[Redémarrer Olympus]],
    there_is_a_new_version_available_update = [[Une nouvelle version d'Olympus est disponible.
Veux-tu installer la version %s maintenant ?]],
    there_is_a_new_version_available = [[Une nouvelle version d'Olympus est disponible : %s]],

    -- utils.lua
    check_the_task_manager = [[ - vérifie le Gestionnaire des tâches]],
    check_the_activity_monitor = [[ - vérifie le Moniteur d'activité]],
    check_htop = [[ - vérifie htop]],
    celeste_is_already_starting_up_please_wa = [[Celeste est déjà en train de démarrer.
Tu peux fermer cette fenêtre.]],
    celeste_is_now_starting_in_the_backgroun = [[Celeste est en train de démarrer en arrière-plan.
Tu peux fermer cette fenêtre.]],
    everest_is_now_starting_in_the_backgroun = [[Everest est en train de démarrer en arrière-plan.
Tu peux fermer cette fenêtre.]],
    olympus_couldn_t_find_the_celeste_launch = [[Olympus n'a pas pu trouver l'exécutable de Celeste.
Vérifie que la version que tu as installée correspond à ton système d'exploitation.
Si tu utilises Lutris ou un outil similaire, on ne peut pas t'aider.]],
    celeste_or_something_looking_like_celest = [[Celeste (ou quelque chose qui y ressemble) est déjà en cours d'exécution.
Si tu ne vois pas le jeu, il est peut-être encore en train de se lancer]],
    do_you_want_to_launch_another_instance_a = [[.
Veux-tu ouvrir un autre exemplaire quand même ?]],
    opening = [[Ouverture de ]],

    -- scenes/everest.lua
    everest_installer = [[Installation d'Everest]],
    versions = [[Versions]],
    reload_versions_list = [[Recharger la liste des versions]],
    or_ = [[ ou ]],
    install = [[Installer]],
    detecting_the_celeste_version_failed_n_s = [[La détection de la version de Celeste a échoué :
%s

Vérifie le chemin de ton installation en sélectionnant "Gérer" dans le menu principal.]],
    attempt_installation_anyway = [[Tenter l'installation quand même]],
    remove_residual_files = [[Supprimer les fichiers résiduels]],
    install_xna = [[Installer XNA]],
    install_runtime = [[Installer le runtime]],
    uninstall = [[Désinstaller]],
    uninstall_dialog = [[La désinstallation d'Everest conservera tous tes mods,
sauf si tu les supprimes manuellement, que tu réinstalles complètement
Celeste, ou que tu ouvres un fichier de sauvegarde dans le jeu de base.

Maintiens Droite sur l'écran titre pour désactiver Everest jusqu'au
prochain lancement, c'est aussi valide pour les speedruns.

Si tu cherches à corriger un problème et que désinstaller Everest ne suffit pas,
ouvre l'application de ton magasin de jeux et fais-lui vérifier les fichiers de ton jeu.
Steam, EGS et l'app itch.io proposent cette option, et c'est plus rapide
qu'une réinstallation complète.]],
    uninstall_anyway = [[Désinstaller quand même]],
    keep_everest = [[Garder Everest]],
    select_your_everest_zip_file = [[Choisis le fichier .zip d'Everest à installer]],
    installation_canceled = [[Installation annulée]],
    preparing_installation_of_everest_s = [[Préparation de l'installation d'Everest %s]],
    everest_s_successfully_installed = [[Everest %s installé avec succès]],
    preparing_uninstallation_of_everest = [[Préparation de la désinstallation d'Everest]],
    everest_successfully_uninstalled = [[Everest désinstallé avec succès]],
    select_zip_from_disk = [[Choisir un .zip depuis le disque dur]],
    newest = [[Dernières versions]],
    pinned = [[Épinglé]],
    use_the_newest_version_for_more_features = [[Utilise les dernières versions pour plus de fonctionnalités et de corrections de bugs.
Utilise la dernière version ]],
    version_if_you_hate_updating = [[ si tu préfères mettre à jour moins souvent.]],
    your_current_version_of_celeste_is_outda = [[Ta version de Celeste n'est pas à jour.
Installe la dernière version du jeu avant d'installer Everest.]],
    residual_files_from_a_net_core_build_hav = [[Des fichiers résiduels d'une version .NET Core ont été détectés.
Ces fichiers pourraient faire échouer l'installation de vieilles versions d'Everest.
Il faudrait les supprimer avant d'installer Everest.
]],
    it_is_required_to_install_xna_before_ins = [[Il est nécessaire d'installer XNA avant d'installer Everest.
Si ta copie de Celeste vient de Steam, lance le jeu pour installer XNA.
Sinon, installe XNA manuellement avec le bouton ci-dessous.]],
    it_is_required_to_install_the_net_7_0_ru = [[Il est nécessaire d'installer le runtime .NET 7.0 avant d'installer les versions "Core" d'Everest.
Clique sur le bouton ci-dessous pour télécharger le programme d'installation.
Tu peux aussi installer le runtime manuellement, puis réessayer d'installer Everest.]],
    install_latest_version = [[Installer Everest]],
    update_to_latest_version = [[Mettre à jour Everest]],
    reinstall_latest_version = [[Réinstaller Everest]],
    install_selected_version = [[Installer la version sélectionnée]],
    loading__ = [[Chargement en cours...]],

    -- scenes/gamebanana.lua
    gamebanana = [[GameBanana]],
    most_recent = [[Trier par date]],
    most_downloaded = [[Trier par téléchargements]],
    most_viewed = [[Trier par vues]],
    most_liked = [[Trier par likes]],
    all = [[Tous]],
    go_to_gamebanana_com = [[Aller sur gamebanana.com]],
    search = [[Rechercher]],
    featured = [[A la une]],
    page = [[Page %d]],
    error_downloading_mod_list = [[Erreur lors du chargement de la liste des mods : ]],
    error_downloading_subcategories_list = [[Erreur lors du chargement de la liste des sous-catégories : ]],
    error_downloading_categories_list = [[Erreur lors du chargement de la liste des catégories : ]],
    y_m_d_h_m_s = [[%d/%m/%Y %H:%M:%S]],
    d_view = [[%d vue]],
    d_views = [[%d vues]],
    d_like = [[%d like]],
    d_likes = [[%d likes]],
    d_download = [[%d téléchargement]],
    d_downloads = [[%d téléchargements]],
    open_in_browser = [[Ouvrir dans le navigateur]],

    -- scenes/gfwtest.lua
    connectivity_test = [[Test de connectivité]],
    test_ok = [[OK]],
    test_ko = [[KO]],
    maddie_s_random_stuff = [[Maddie's Random Stuff]],
    github = [[GitHub]],
    azure_pipelines = [[Azure Pipelines]],
    everest_website = [[Site Web Everest]],
    gamebanana_files = [[GameBanana Files]],
    nif_lua_is_ko_but_sharp_is_ok_deleting = [[Si Lua est KO mais Sharp is OK, supprimer ]],
    libcurl_dll_might_help = [[\\libcurl.dll pourrait aider.]],
    service = [[Service]],
    lua = [[Lua]],
    sharp = [[Sharp]],
    reload = [[Recharger]],
    maddie480_ovh_nprovides_the_everest_vers = [[ (maddie480.ovh)
Fournit la plupart des services en ligne d'Olympus, active le "Miroir API" en cas de problème]],
    github_com_nhosts_stable_versions_of_eve = [[ (github.com)
Héberge les versions stables d'Everest]],
    dev_azure_com_nhosts_olympus_updates_and = [[ (dev.azure.com)
Héberge les mises à jour d'Olympus, et les versions non-stables d'Everest]],
    everestapi_github_io_nprovides_olympus_n = [[ (everestapi.github.io)
Fournit les actualités Olympus, affichées à droite du menu principal]],
    files_gamebanana_com_nhosts_all_celeste_ = [[ (files.gamebanana.com)
Héberge tous les mods Celeste, sélectionne un miroir dans les options en cas de problème]],
    you_can_use_this_page_to_check_your_conn = [[Cet écran te permet si tu peux te connecter aux différents sites qu'Olympus utilise.
Si l'un d'eux est KO, les fonctionnalités correspondantes ne seront probablement pas disponibles.
Quelques exemples de situations où des problèmes réseau peuvent se produire :
- Ton antivirus / pare-feu empêche Olympus d'accéder à Internet.
- Le site web est hors-service ou il y a un problème de réseau, réessaye plus tard.
- Un filtrage réseau bloque le site, essaie sur un autre réseau ou utilise un VPN.]],

    -- scenes/installer.lua
    installer = [[Installation]],
    autoclosing_in_d = [[Fermeture automatique dans %d...]],
    open_log = [[Ouvrir le log]],
    open_log_folder = [[Ouvrir le dossier des logs]],
    you_can_ask_for_help_in_the_celeste_disc = [[Tu peux demander de l'aide sur le serveur Discord Celeste (en anglais).
Le lien d'invitation est sur le site d'Everest.
Pense bien à joindre log.txt et log-sharp.txt dans le canal #modding_help.
Avant de les envoyer, vérifie qu'ils ne contiennent pas d'info sensible,
comme ton nom d'utilisateur.]],

    -- scenes/installmanager.lua
    install_manager = [[Gestionnaire d'installations]],
    scanning = [[Recherche en cours...]],
    remove = [[Supprimer]],
    add = [[Ajouter]],
    i_know_what_i_m_doing = [[Je sais ce que je fais.]],
    verify = [[Vérifier]],
    browse = [[Parcourir]],
    your_installations = [[Tes installations]],
    manually_select_celeste_exe = [[Sélectionner Celeste.exe manuellement]],
    found = [[Installations trouvées]],
    the_uwp_xbox_microsoft_store_version_of_ = [[La version UWP (Xbox/Microsoft Store) de Celeste n'est pas supportée actuellement.
Toutes les données du jeu sont chiffrées, même les fichiers dialogue (qui sont des
fichiers texte dans les autres versions) ne peuvent pas être modifiés.
Le jeu est compilé d'une autre façon, donc les mods actuels ne fonctionneraient pas.
Lönn et Ahorn ne peuvent pas s'en servir non plus pour charger ce dont ils ont besoin.
Sauf si Everest est réécrit ou que quelqu'un commence un autre mod loader juste pour
cette version du jeu, il ne faut pas s'attendre à quoi que ce soit...]],
    verifying_the_file_integrity_will_tell_s = [[La vérification des fichiers du jeu va demander à Steam de re-télécharger
tous les fichiers modifiés, ce qui désinstalle Everest.
N'utilise pas Olympus pendant que Steam modifie les fichiers du jeu.
Tu devras aller vérifier la progression de l'opération dans Steam.
Veux-tu continuer ?]],
    olympus_needs_to_know_which_celeste_inst1 = [[Olympus a besoin de savoir quelles installations de Celeste il doit gérer.
Les installations trouvées automatiquement seront listées ci-dessous.
Sélectionne Celeste.exe manuellement si aucune installation n'a été trouvée.]],
    olympus_needs_to_know_which_celeste_inst2 = [[Olympus a besoin de savoir quelles installations de Celeste il doit gérer.
Tu peux ajouter les installations trouvées automatiquement à cette liste, en cliquant sur "Ajouter".
]],
    olympus_needs_to_know_which_celeste_inst3 = [[Olympus a besoin de savoir quelles installations de Celeste il doit gérer.
Aucune installation n'a été trouvée automatiquement. Sélectionne Celeste.exe manuellement.
]],

    -- scenes/mainmenu.lua
    main_menu = [[Menu principal]],
    installations = [[Installations]],
    manage = [[Gérer]],
    d_new_install_found = [[%d install. trouvée]],
    d_new_installs_found = [[%d install. trouvées]],
    nscanning = [[

Recherche...]],
    l_nn_map_editor = [[Lönn (Éditeur de map)]],
    l_nn_is_currently_not_installed = [[Lönn n'est pas actuellement installé.]],
    currently_installed_version = [[Version installée : ]],
    s_nlatest_version_s_ninstall_folder_s = [[%s
Dernière version : %s
Dossier d'installation : %s]],
    install_l_nn = [[Installer Lönn]],
    update_l_nn = [[Mettre à jour Lönn]],
    preparing_installation_of_l_nn = [[Préparation de l'installation de Lönn ]],
    l_nn = [[Lönn ]],
    successfully_installed = [[ installé avec succès]],
    launch_l_nn = [[Lancer Lönn]],
    uninstall_l_nn = [[Désinstaller Lönn]],
    this_will_delete_directory = [[Cela va supprimer le dossier ]],
    nare_you_sure = [[.
Es-tu sûr(e) ?]],
    preparing_uninstallation_of_l_nn = [[Préparation de la désinstallation de Lönn]],
    l_nn_successfully_uninstalled = [[Lönn désinstallé avec succès]],
    ncheck_the_readme_for_usage_instructions = [[Lis le README pour des instructions, les raccourcis clavier, etc :]],
    open_l_nn_readme = [[Ouvrir le README de Lönn]],
    download_mods = [[Télécharger des mods]],
    manage_installed_mods = [[Gérer les mods installés]],
    options_updates = [[Options & Mises à jour]],
    options = [[Options]],
    news = [[Actualités]],
    everest = [[Everest]],
    celeste = [[Celeste]],
    install_everest = [[Installer Everest]],
    olympus_failed_fetching_the_news_feed = [[Olympus n'a pas pu charger le fil d'actualités.]],
    olympus_failed_fetching_a_news_entry = [[Olympus n'a pas pu charger l'une des actualités.]],
    a_news_entry_was_in_an_unexpected_format = [[L'une des actualités a un format invalide.]],
    a_news_entry_contained_invalid_metadata = [[L'une des actualités contient des données invalides.]],
    ahorn = [[Ahorn]],
    your_celeste_installation_list_is_empty_ = [[Ta liste d'installations de Celeste est vide.
Veux-tu ouvrir le gestionnaire d'installations ?]],
    your_celeste_installs_list_is_empty_pres = [[Ta liste d'installations de Celeste est vide.
Appuie sur le bouton "Gérer" ci-dessous.]],

    -- scenes/modlist.lua
    mod_manager = [[Gestionnaire de mods]],
    s_enabled_s = [[%s %s]],
    no1 = [[0]],
    mod = [[mod activé]],
    mods = [[mods activés]],
    no_mod_info_available = [[(Information non disponible)]],
    this_mod_depends_on_s_other_disabled_s_n = [[Ce mod dépend de %s %s.
Veux-tu aussi activer %s ?]],
    mod1 = [[mod non activé]],
    mods1 = [[mods non activés]],
    tooltip_favorite = [[Favori]],
    tooltip_dependency_of_favorite = [[Requis par l'un de tes mods favoris]],
    tooltip_dependency = [[Requis par l'un des mods que tu as activés]],
    it = [[celui-ci]],
    them = [[ceux-ci]],
    s_other_s_no_longer_required_for_any_ena = [[%s %s pour aucun mod activé.
Veux-tu aussi désactiver %s ?]],
    mod_is = [[autre mod n'est plus nécessaire]],
    mods_are = [[autres mods ne sont plus nécessaires]],
    s_other_s_on_this_mod_ndo_you_want_to_di = [[%s %s de ce mod.
Veux-tu aussi désactiver %s ?]],
    mod_depends = [[autre mod activé dépend]],
    mods_depend = [[autres mods activés dépendent]],
    delete = [[Supprimer]],
    keep = [[Garder]],
    some_mods_couldn_t_be_loaded_make_sure_t = [[Certains mods n'ont pas pu être chargés, assure-toi qu'ils sont installés :
]],
    something_went_wrong_deleted_preset_s_na = [[Quelque chose a mal tourné, le nom du groupe de mods à supprimer est vide !]],
    something_went_wrong_name_is_nil = [[Quelque chose a mal tourné, le nom est vide !]],
    preset_name_can_t_be_empty = [[Le nom du groupe ne peut pas être vide !]],
    this_preset_already_exists_do_you_wish_t = [[Ce groupe existe déjà ! Veux-tu le remplacer ?]],
    preset_already_exists = [[Le groupe "%s" existe déjà !]],
    preset_not_found = [[Le groupe "%s" est introuvable.]],
    new_preset_name = [[Nom du nouveau groupe]],
    preset = [[Groupe]],
    preset_none = [[Aucun]],
    preset_custom = [[Personnalisé]],
    preset_modified = [[%s + changements]],
    preset_editing = [[Personnalisé (édition de %s)]],
    preset_selected = [[Sélectionné]],
    selected_preset = [[Groupe sélectionné]],
    selected_preset_required = [[Sélectionne d'abord un groupe.]],
    preset_select = [[Sélectionner]],
    preset_merge = [[Fusionner]],
    preset_update = [[Mettre à jour]],
    preset_rename = [[Renommer]],
    preset_created = [[Groupe %s créé]],
    preset_updated = [[Groupe %s mis à jour]],
    preset_renamed = [[%s renommé en %s]],
    preset_mod_count = [[%s mod(s)]],
    preset_missing_count = [[%s manquant(s)]],
    preset_remove_missing = [[Nettoyer les manquants]],
    preset_missing_removed = [[%s entrées manquantes supprimées de %s]],
    no_missing_entries = [[Aucune entrée manquante dans %s]],
    no_presets = [[Aucun groupe pour le moment.]],
    no_presets_to_update = [[Aucun groupe à mettre à jour.]],
    create_preset_from_enabled = [[Créer depuis les mods activés]],
    preset_actions = [[Actions du groupe]],
    add_to_selected_preset = [[Ajouter au groupe sélectionné]],
    remove_from_selected_preset = [[Retirer du groupe sélectionné]],
    add_to_all_presets = [[Ajouter à tous les groupes]],
    remove_from_all_presets = [[Retirer de tous les groupes]],
    mod_added_to_preset = [[%s ajouté à %s]],
    mod_removed_from_preset = [[%s retiré de %s]],
    mod_added_to_s_presets = [[%s ajouté à %s groupe(s)]],
    mod_removed_from_s_presets = [[%s retiré de %s groupe(s)]],
    mod_already_in_preset = [[%s est déjà dans %s]],
    mod_not_in_preset = [[%s n'est pas dans %s]],
    confirm_remove_mod_from_all_presets = [[Retirer %s de %s groupe(s) ?]],
    this_mod_depends_on_s_other_s_add_to_preset = [[Ce mod dépend de %s autre(s) %s.
Veux-tu aussi %s ajouter au groupe ?]],
    add_dependencies = [[Ajouter les dépendances]],
    only_this_mod = [[Seulement ce mod]],
    mod_and_deps_added_to_preset = [[%s et ses dépendances ajoutés à %s]],
    mod_and_deps_added_to_s_presets = [[%s et ses dépendances ajoutés à %s groupe(s)]],
    replace = [[Remplacer]],
    edit_modpresets_txt = [[Modifier modpresets.txt]],
    add_preset = [[Ajouter un groupe]],
    mod_presets = [[Groupes de mods]],
    enabled = [[Activé]],
    update_all = [[Tout mettre à jour]],
    open_mods_folder = [[Ouvrir le dossier Mods]],
    install_mod_file = [[Installer depuis un fichier]],
    edit_blacklist_txt = [[Modifier blacklist.txt]],
    filter_list = [[Filtres :]],
    all_categories = [[Toutes les catégories]],
    no_category = [[Sans catégorie]],
    only_show_enabled = [[Activés uniquement]],
    only_show_favorites = [[Favoris uniquement]],
    enable_all = [[Tout activer]],
    disable_all = [[Tout désactiver]],
    search_by_file_name_mod_title_or_everest = [[Rechercher par nom du fichier, titre du mod ou ID everest.yaml]],
    an_error_occurred_while_loading_the_mod_ = [[Une erreur est survenue lors du chargement de la liste des mods.]],
    are_you_sure_that_you_want_to_delete = [[Es-tu sûr(e) de vouloir supprimer ]],
    you_will_need_to_redownload_the_mod_to_u = [[ ?
Il faudra re-télécharger le mod si tu veux t'en resservir.
Astuce : Si tu désactives le mod, Everest ne le chargera pas, ce qui est tout aussi efficace pour le lag.]],
    questionmark = [[ ?]],

    -- scenes/options.lua
    random_default = [[Aléatoire (défaut)]],
    background = [[Arrière-plan n°]],
    high_default = [[Haute (défaut)]],
    medium = [[Moyenne]],
    low = [[Basse]],
    minimal = [[Minimale]],
    stable_default = [[Stable (défaut)]],
    development = [[Développement]],
    all_mods = [[Tous les mods]],
    enabled_mods_only = [[Mods activés]],
    disabled_default = [[Désactivé (défaut)]],
    germany_0x0a_de = [[Allemagne (0x0a.de)]],
    china_weg_fan = [[Chine (weg.fan)]],
    n_america_celestemods_com = [[Am. du Nord (celestemods.com)]],
    _x0a_de_default = [[0x0a.de (défaut)]],
    celestemods_com = [[celestemods.com]],
    disabled = [[Désactivé]],
    theme = [[Thème]],
    select_your_theme = [[Choisis ton thème]],
    background_image = [[Fond d'écran]],
    select_your_background = [[Choisis ton fond d'écran]],
    quality = [[Qualité]],
    gradient = [[Gradient]],
    enabled_default = [[Activé (défaut)]],
    parallax = [[Parallaxe]],
    vertical_sync = [[Sync. verticale]],
    updates = [[Mises à jour]],
    update_mods_on_startup = [[MàJ des mods au lancement]],
    use_opengl = [[Utiliser OpenGL]],
    close_after_one_click_install = [[Fermer après install. 1-click]],
    open_installation_folder = [[Ouvrir le dossier d'installation]],
    open_log_and_config_folder = [[Ouvrir dossier des logs et config.]],
    mirrors = [[Miroirs]],
    download_mirror = [[Miroir de téléchargement]],
    api_mirror = [[Miroir API]],
    image_mirror = [[Miroir des images]],
    this_is_your_current_theme_the_quick_bro = [[Ceci est ton thème actuel.
The quick brown fox jumps]],
    this_is_the_new_theme_over_the_lazy_dog = [[Ceci est ton nouveau thème.
over the lazy dog.]],
    if_you_have_difficulty_downloading_mods_ = [[Si tu as des difficultés pour télécharger des mods ou accéder à certaines sections d'Olympus, change ces options.
- ]],
    can_help_if_mod_downloads_are_slow_or_ga = [[ peut aider si les téléchargements sont lents ou que GameBanana est en panne.
- ]],
    can_help_if_the_install_everest_or_downl = [[ peut aider si les sections "Installation d'Everest" et "Télécharger des mods" n'arrivent pas à charger.
- ]],
    changes_where_the_mod_images_in_the_mod_ = [[ détermine d'où viennent les images dans la section "Télécharger des mods".]],
    language = [[Langue]],
    restart_to_apply_changes_in_languages = [[Tu dois redémarrer Olympus pour que le changement de langue s'applique complètement.]],
    note_this_only_covers_olympus_1 = [[NOTE : ]],
    note_this_only_covers_olympus_2 = [[Cette section ne concerne que les mises à jour d'Olympus. Pour Everest et Lönn, utilise les boutons]],
    note_this_only_covers_olympus_3 = [[dans le menu principal.]],
    theme_dark = [[Sombre (défaut)]],
    theme_light = [[Clair]],

    -- C# stuff (Cmds.Download / CmdUpdateAllMods)
    csharp_downloadinglist = [[Téléchargement de la liste des mods]],
    csharp_downloadingfile = [[Téléchargement de]],
    csharp_downloadingprogress = [[Téléchargement -]],
    csharp_checking = [[Vérification des mises à jour]],
    csharp_updating = [[Mise à jour]],
    csharp_installing = [[installation en cours]],
    csharp_finished_noop = [[La vérification est terminée.
Aucune mise à jour n'a été trouvée.]],
    csharp_finished = [[Mise à jour terminée !
Les mods suivants ont été mis à jour :]],
    csharp_checksum = [[vérification de la somme de contrôle]],
    csharp_unzipping = [[Extraction]],
    csharp_unzipping_files = [[Extraction de {0} fichiers(s)]],
    csharp_unzipped_files = [[{0} fichier(s) extrait(s)]],
    csharp_downloaded = [[{0} octets téléchargés en {1} seconde(s).]],
}

return {
    cjk_priority = cjk_priority,
    keys = keys
}
