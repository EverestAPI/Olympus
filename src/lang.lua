local config = require("config")
local en = {
    -- super common keys
    ok = [[OK]],
    cancel = [[Cancel]],
    yes = [[Yes]],
    no = [[No]],
    loading = [[Loading]],
    close = [[Close]],

    -- dragndrop.lua
    olympus_is_currently_busy_with_something = [[Olympus is currently busy with something else.]],
    olympus_can_t_handle_that_file_does_it_e = [[Olympus can't handle that file - does it exist?]],
    everest_successfully_installed = [[Everest successfully installed]],
    launch = [[Launch]],
    olympus_can_t_handle_that_file = [[Olympus can't handle that file.]],
    your_celeste_installation_list_is_still_ = [[Your Celeste installation list is still empty.
Do you want to go to the Celeste installation manager?]],

    -- main.lua
    olympus_sharp_startup_error = [[Olympus.Sharp Startup Error]],
    failed_loading_olympus_sharp = [[Failed loading Olympus.Sharp: ]],
    open_everest_website = [[Open Everest Website]],
    do_you_want_to_close_olympus = [[Do you want to close Olympus?]],
    the_olympus_app_is_out_of_date_sometimes = [[The Olympus app is out of date.
Sometimes, new features and huge fixes require updates
under the hood of Olympus, which it can't apply itself.
Most notably, the one-click installer buttons found on GameBanana
were broken on macOS. To fix this, you will need to reinstall Olympus.
Please go to the Everest website for further instructions.
Keeping Olympus outdated can cause crashes in the future.]],

    -- modinstaller.lua
    preparing_installation_of_s = [[Preparing installation of %s]],

    -- modupdater.lua
    updating_enabled_mods = [[Updating enabled mods]],
    updating_all_mods = [[Updating all mods]],
    please_wait = [[Please wait...]],
    skip = [[Skip]],
    retry = [[Retry]],
    open_logs_folder = [[Open logs folder]],
    run_anyway = [[Run anyway]],
    an_error_occurred_while_updating_your_mo = [[An error occurred while updating your mods.
Make sure you are connected to the Internet and that Lönn is not running!]],

    -- updater.lua
    cannot_determine_currently_running_versi = [[Cannot determine currently running version of Olympus!]],
    checking_for_updates = [[Checking for updates...]],
    error_downloading_builds_list = [[Error downloading builds list: ]],
    error_downloading_builds_list_invalid_ol = [[Error downloading builds list: Invalid olympus builds json (missing value property)]],
    currently_installed_n = [[Currently installed:
]],
    newest_available_n = [[Newest available:
]],
    changelog_n = [[Changelog:
]],
    downloading = [[Downloading...]],
    failed_to_download_n = [[Failed to download:
]],
    no_updates_found = [[No updates found.]],
    preparing_update_of_olympus = [[Preparing update of Olympus]],
    olympus_successfully_updated = [[Olympus successfully updated]],
    restart_olympus = [[Restart Olympus]],
    there_is_a_new_version_available_update = [[There's a new version of Olympus available.
Do you want to update to %s now?]],
    there_is_a_new_version_available = [[There's a new version of Olympus available: %s]],

    -- utils.lua
    check_the_task_manager = [[ - check the Task Manager]],
    check_the_activity_monitor = [[ - check the Activity Monitor]],
    check_htop = [[ - check htop]],
    celeste_is_already_starting_up_please_wa = [[Celeste is already starting up. Please wait.
You can close this window.]],
    celeste_is_now_starting_in_the_backgroun = [[Celeste is now starting in the background.
You can close this window.]],
    everest_is_now_starting_in_the_backgroun = [[Everest is now starting in the background.
You can close this window.]],
    olympus_couldn_t_find_the_celeste_launch = [[Olympus couldn't find the Celeste launch binary.
Please check if the installed version of Celeste matches your OS.
If you are using Lutris or similar, you are on your own.]],
    celeste_or_something_looking_like_celest = [[Celeste (or something looking like Celeste) is already running.
If you can't see it, it's probably still launching]],
    do_you_want_to_launch_another_instance_a = [[.
Do you want to launch another instance anyway?]],
    opening = [[Opening ]],

    -- scenes/everest.lua
    everest_installer = [[Everest Installer]],
    versions = [[Versions]],
    reload_versions_list = [[Reload versions list]],
    or_ = [[ or ]],
    install = [[Install]],
    detecting_the_celeste_version_failed_n_s = [[Detecting the Celeste version failed:
%s

Check the path of your install by selecting "Manage" in the main menu.]],
    attempt_installation_anyway = [[Attempt Installation Anyway]],
    remove_residual_files = [[Remove Residual Files]],
    install_xna = [[Install XNA]],
    install_runtime = [[Install Runtime]],
    update = [[Update]],
    uninstall = [[Uninstall]],
    uninstall_dialog = [[Uninstalling Everest will keep all your mods intact,
unless you manually delete them, fully reinstall Celeste,
or load into a modded save file in vanilla Celeste.

Holding right on the title screen lets you turn off Everest
until you start up the game again, which is "speedrun-legal" too.

If even uninstalling Everest doesn't bring the expected result,
please go to your game manager's library and let it verify the game's files.
Steam, EGS and the itch.io app let you do that without a full reinstall.]],
    uninstall_anyway = [[Uninstall anyway]],
    keep_everest = [[Keep Everest]],
    select_your_everest_zip_file = [[Select your Everest .zip file]],
    installation_canceled = [[Installation canceled]],
    preparing_installation_of_everest_s = [[Preparing installation of Everest %s]],
    everest_s_successfully_installed = [[Everest %s successfully installed]],
    preparing_uninstallation_of_everest = [[Preparing uninstallation of Everest]],
    everest_successfully_uninstalled = [[Everest successfully uninstalled]],
    select_zip_from_disk = [[Select .zip from disk]],
    newest = [[Newest]],
    pinned = [[Pinned]],
    use_the_newest_version_for_more_features = [[Use the newest version for more features and bugfixes.
Use the latest ]],
    version_if_you_hate_updating = [[ version if you hate updating.]],
    your_current_version_of_celeste_is_outda = [[Your current version of Celeste is outdated.
Please update to the latest version before installing Everest.]],
    residual_files_from_a_net_core_build_hav = [[Residual files from a .NET Core build have been detected.
These files could cause the installation of older Everest versions to fail.
They should be removed before attempting to install Everest.
]],

    -- scenes/gamebanana.lua
    gamebanana = [[GameBanana]],
    most_recent = [[Most Recent]],
    most_downloaded = [[Most Downloaded]],
    most_viewed = [[Most Viewed]],
    most_liked = [[Most Liked]],
    all = [[All]],
    go_to_gamebanana_com = [[Go to gamebanana.com]],
    search = [[Search]],
    featured = [[Featured]],
    page = [[Page #]],
    error_downloading_mod_list = [[Error downloading mod list: ]],
    error_downloading_subcategories_list = [[Error downloading subcategories list: ]],
    error_downloading_categories_list = [[Error downloading categories list: ]],
    y_m_d_h_m_s = [[%Y-%m-%d %H:%M:%S]],
    d_view = [[%d view]],
    d_views = [[%d views]],
    d_like = [[%d like]],
    d_likes = [[%d likes]],
    d_download = [[%d download]],
    d_downloads = [[%d downloads]],
    open_in_browser = [[Open in browser]],

    -- scenes/gfwtest.lua
    connectivity_test = [[Connectivity Test]],
    ko = [[KO]],
    maddie_s_random_stuff = [[Maddie's Random Stuff]],
    github = [[GitHub]],
    azure_pipelines = [[Azure Pipelines]],
    everest_website = [[Everest Website]],
    gamebanana_files = [[GameBanana Files]],
    nif_lua_is_ko_but_sharp_is_ok_deleting = [[If Lua is KO but Sharp is OK, deleting ]],
    libcurl_dll_might_help = [[\\libcurl.dll might help.]],
    service = [[Service]],
    lua = [[Lua]],
    sharp = [[Sharp]],
    reload = [[Reload]],
    maddie480_ovh_nprovides_the_everest_vers = [[ (maddie480.ovh)
Provides most online services Olympus uses, enable the "API Mirror" in case of trouble]],
    github_com_nhosts_stable_versions_of_eve = [[ (github.com)
Hosts stable versions of Everest]],
    dev_azure_com_nhosts_olympus_updates_and = [[ (dev.azure.com)
Hosts Olympus updates, and non-stable versions of Everest]],
    everestapi_github_io_nprovides_olympus_n = [[ (everestapi.github.io)
Provides Olympus News, displayed on the right side of the main menu]],
    files_gamebanana_com_nhosts_all_celeste_ = [[ (files.gamebanana.com)
Hosts all Celeste mods, select a mirror in Options & Updates in case of trouble]],
    you_can_use_this_page_to_check_your_conn = [[You can use this page to check your connectivity to the various web services Olympus uses.
If one of the tests fail, the corresponding features in Olympus will probably be unavailable.
Some of the possible reasons why this might be happening:
- Your antivirus / firewall is blocking Olympus from accessing the Internet.
- The service is down or there is a networking issue, try again later.
- Network filtering is blocking the website, try again on another connection or toggle your VPN.]],

    -- scenes/installer.lua
    installer = [[Installer]],
    autoclosing_in_d = [[Autoclosing in %d...]],
    open_log = [[Open log]],
    open_log_folder = [[Open log folder]],
    you_can_ask_for_help_in_the_celeste_disc = [[You can ask for help in the Celeste Discord server.
An invite can be found on the Everest website.
Please drag and drop your log files into the #modding_help channel.
Before uploading, check your logs for sensitive info (f.e. your username).]],

    -- scenes/installmanager.lua
    install_manager = [[Install Manager]],
    scanning = [[Scanning...]],
    remove = [[Remove]],
    add = [[Add]],
    i_know_what_i_m_doing = [[I know what I'm doing.]],
    verify = [[Verify]],
    browse = [[Browse]],
    your_installations = [[Your Installations]],
    manually_select_celeste_exe = [[Manually select Celeste.exe]],
    found = [[Found]],
    the_uwp_xbox_microsoft_store_version_of_ = [[The UWP (Xbox/Microsoft Store) version of Celeste is currently unsupported.
All game data is encrypted, even dialog text files are uneditable.
The game code itself is AOT-compiled - no existing code mods would work.
Even Lönn and Ahorn currently can't load the necessary game data either.
Unless Everest gets rewritten or someone starts working on
a mod loader just for this special version, don't expect
anything to work in the near future, if at all.]],
    verifying_the_file_integrity_will_tell_s = [[Verifying the file integrity will tell Steam to redownload
any modified files, uninstalling Everest in the process.
Don't use Olympus while Steam is downloading game files.
You will need to check the download progress yourself.
Do you want to continue?]],
    olympus_needs_to_know_which_celeste_inst1 = [[Olympus needs to know which Celeste installations you want to manage.
Automatically found installations will be listed below and can be added to this list.
Manually select Celeste.exe if no installations have been found automatically.]],
    olympus_needs_to_know_which_celeste_inst2 = [[Olympus needs to know which Celeste installations you want to manage.
You can add automatically found installations from the list below to this one.
]],
    olympus_needs_to_know_which_celeste_inst3 = [[Olympus needs to know which Celeste installations you want to manage.
No installations were found automatically. Manually select Celeste.exe to add it to Olympus.
]],

    -- scenes/mainmenu.lua
    main_menu = [[Main Menu]],
    installations = [[Installations]],
    manage = [[Manage]],
    d_new_install_found = [[%d new install found.]],
    d_new_installs_found = [[%d new installs found.]],
    nscanning = [[Scanning...]],
    l_nn_map_editor = [[Lönn (Map Editor)]],
    l_nn_is_currently_not_installed = [[Lönn is currently not installed.]],
    currently_installed_version = [[Currently installed version: ]],
    s_nlatest_version_s_ninstall_folder_s = [[%s
Latest version: %s
Install folder: %s]],
    install_l_nn = [[Install Lönn]],
    update_l_nn = [[Update Lönn]],
    preparing_installation_of_l_nn = [[Preparing installation of Lönn ]],
    l_nn = [[Lönn ]],
    successfully_installed = [[ successfully installed]],
    launch_l_nn = [[Launch Lönn]],
    uninstall_l_nn = [[Uninstall Lönn]],
    this_will_delete_directory = [[This will delete directory ]],
    nare_you_sure = [[.
Are you sure?]],
    preparing_uninstallation_of_l_nn = [[Preparing uninstallation of Lönn]],
    l_nn_successfully_uninstalled = [[Lönn successfully uninstalled]],
    ncheck_the_readme_for_usage_instructions = [[Check the README for usage instructions, keybinds, help and more:]],
    open_l_nn_readme = [[Open Lönn README]],
    download_mods = [[Download Mods]],
    manage_installed_mods = [[Manage Installed Mods]],
    options_updates = [[Options & Updates]],
    options = [[Options]],
    news = [[News]],
    everest = [[Everest]],
    celeste = [[Celeste]],
    install_everest = [[Install Everest]],
    olympus_failed_fetching_the_news_feed = [[Olympus failed fetching the news feed.]],
    olympus_failed_fetching_a_news_entry = [[Olympus failed fetching a news entry.]],
    a_news_entry_was_in_an_unexpected_format = [[A news entry was in an unexpected format.]],
    a_news_entry_contained_invalid_metadata = [[A news entry contained invalid metadata.]],
    ahorn = [[Ahorn]],
    your_celeste_installation_list_is_empty_ = [[Your Celeste installation list is empty.
Do you want to go to the Celeste installation manager?]],
    your_celeste_installs_list_is_empty_pres = [[Your Celeste installs list is empty.
Press the manage button below.]],

    -- scenes/modlist.lua
    mod_manager = [[Mod Manager]],
    no1 = [[No]],
    s_enabled_s = [[%s enabled %s]],
    mod = [[mod]],
    mods = [[mods]],
    no_mod_info_available = [[(No mod info available)]],
    this_mod_depends_on_s_other_disabled_s_n = [[This mod depends on %s other disabled %s.
Do you want to enable %s as well?]],
    mod1 = [[mod]],
    mods1 = [[mods]],
    it = [[it]],
    them = [[them]],
    s_other_s_no_longer_required_for_any_ena = [[%s other %s no longer required for any enabled mod.
Do you want to disable %s as well?]],
    mod_is = [[mod is]],
    mods_are = [[mods are]],
    s_other_s_on_this_mod_ndo_you_want_to_di = [[%s other %s on this mod.
Do you want to disable %s as well?]],
    mod_depends = [[mod depends]],
    mods_depend = [[mods depend]],
    delete = [[Delete]],
    keep = [[Keep]],
    some_mods_couldn_t_be_loaded_make_sure_t = [[Some mods couldn't be loaded, make sure they are installed:
]],
    something_went_wrong_deleted_preset_s_na = [[Something went wrong, deleted preset's name is empty!]],
    something_went_wrong_name_is_nil = [[Something went wrong, name is empty!]],
    preset_name_can_t_be_empty = [[Preset name can't be empty!]],
    this_preset_already_exists_do_you_wish_t = [[This preset already exists! Do you wish to override it?]],
    new_preset_name = [[New preset name]],
    replace = [[Replace]],
    edit_modpresets_txt = [[Edit modpresets.txt]],
    add_preset = [[Add preset]],
    mod_presets = [[Mod presets]],
    enabled = [[Enabled]],
    this_menu_allows_you_to_enable_disable_o = [[This menu allows you to enable, disable or delete the mods you currently have installed.]],
    update_all = [[Update All]],
    open_mods_folder = [[Open mods folder]],
    edit_blacklist_txt = [[Edit blacklist.txt]],
    only_show_enabled = [[Only show enabled]],
    only_show_favorites = [[Only show favorites]],
    enable_all = [[Enable All]],
    disable_all = [[Disable All]],
    search_by_file_name_mod_title_or_everest = [[Search by file name, mod title or everest.yaml ID]],
    an_error_occurred_while_loading_the_mod_ = [[An error occurred while loading the mod list.]],
    are_you_sure_that_you_want_to_delete = [[Are you sure that you want to delete ]],
    you_will_need_to_redownload_the_mod_to_u = [[?
You will need to redownload the mod to use it again.
Tip: Disabling the mod prevents Everest from loading it, and is as efficient as deleting it to reduce lag.]],
    questionmark = [[?]],

    -- scenes/options.lua
    random_default = [[Random (Default)]],
    background = [[Background #]],
    high_default = [[High (Default)]],
    medium = [[Medium]],
    low = [[Low]],
    minimal = [[Minimal]],
    stable_default = [[Stable (Default)]],
    development = [[Development]],
    all_mods = [[All Mods]],
    enabled_mods_only = [[Enabled Mods Only]],
    disabled_default = [[Disabled (Default)]],
    germany_0x0a_de = [[Germany (0x0a.de)]],
    china_weg_fan = [[China (weg.fan)]],
    n_america_celestemods_com = [[N. America (celestemods.com)]],
    _x0a_de_default = [[0x0a.de (Default)]],
    celestemods_com = [[celestemods.com]],
    disabled = [[Disabled]],
    noto_sans_cjk_50_mb = [[Noto Sans CJK (~50 MB)]],
    chinese_japanese_korean_font_files = [[Chinese, Japanese, Korean font files.]],
    theme = [[Theme]],
    select_your_theme = [[Select your theme]],
    background_image = [[Background image]],
    select_your_background = [[Select your background]],
    quality = [[Quality]],
    gradient = [[Gradient]],
    enabled_default = [[Enabled (Default)]],
    parallax = [[Parallax]],
    vertical_sync = [[Vertical Sync]],
    updates = [[Updates]],
    update_mods_on_startup = [[Update Mods on Startup]],
    use_opengl = [[Use OpenGL]],
    close_after_one_click_install = [[Close after One-Click Install]],
    open_installation_folder = [[Open installation folder]],
    open_log_and_config_folder = [[Open log and config folder]],
    download_extra_data = [[Download extra data]],
    extra_data_s_successfully_installed = [[Extra data %s successfully installed]],
    mirrors = [[Mirrors]],
    download_mirror = [[Download Mirror]],
    api_mirror = [[API Mirror]],
    image_mirror = [[Image Mirror]],
    this_is_your_current_theme_the_quick_bro = [[This is your current theme.
The quick brown fox jumps]],
    this_is_the_new_theme_over_the_lazy_dog = [[This is the new theme.
over the lazy dog.]],
    if_you_have_difficulty_downloading_mods_ = [[If you have difficulty downloading mods or getting some sections of Olympus to load, you can try these.
- ]],
    can_help_if_mod_downloads_are_slow_or_ga = [[ can help if mod downloads are slow, or GameBanana is having issues.
- ]],
    can_help_if_the_install_everest_or_downl = [[ can help if the "Install Everest" or "Download Mods" pages won't load. The mod browser will be slower, though!
- ]],
    changes_where_the_mod_images_in_the_mod_ = [[ changes where the mod images in the mod browser come from. You can choose to use no mirror, but older mods won't have images.]],
    language = [[Language]],
    restart_to_apply_changes_in_languages = [[You must restart Olympus for the language change to completely take effect.]],
}

local fr = {
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

    -- modinstaller.lua
    preparing_installation_of_s = [[Préparation de l'installation de %s]],

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
    update = [[Mettre à jour]],
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
    page = [[Page ]],
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
    ko = [[KO]],
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
Pense bien à joindre tes fichiers de log dans le canal #modding_help.
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
    nscanning = [[Recherche...]],
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
    new_preset_name = [[Nom du nouveau groupe]],
    replace = [[Remplacer]],
    edit_modpresets_txt = [[Modifier modpresets.txt]],
    add_preset = [[Ajouter un groupe]],
    mod_presets = [[Groupes de mods]],
    enabled = [[Activé]],
    this_menu_allows_you_to_enable_disable_o = [[Ce menu te permet d'activer, désactiver ou supprimer les mods que tu as installés.]],
    update_all = [[Tout mettre à jour]],
    open_mods_folder = [[Ouvrir le dossier Mods]],
    edit_blacklist_txt = [[Modifier blacklist.txt]],
    only_show_enabled = [[Activés]],
    only_show_favorites = [[Favoris]],
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
    noto_sans_cjk_50_mb = [[Noto Sans CJK (~50 Mo)]],
    chinese_japanese_korean_font_files = [[Polices pour le chinois, le japonais et le coréen.]],
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
    download_extra_data = [[Téléchargements supp.]],
    extra_data_s_successfully_installed = [[%s installé avec succès]],
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
}

local langs = {
    en = en,
    fr = fr
}

local function get(key)
    local lang = config.language
    -- "ne" is "en" backwards. It's a joke language, and also a way to check that everything is backwards but everything still works.
    if lang == "ne" then
        local value = en[key]:gsub("ö", "oe") -- ö in Lönn turns into soup backwards
        value = value:reverse()
        value, _ = value:gsub("s%%", "%%s") -- %s works, s% not that much
        value, _ = value:gsub("Y%%", "%%Y") -- same for date formats
        value, _ = value:gsub("m%%", "%%m")
        value, _ = value:gsub("d%%", "%%d")
        value, _ = value:gsub("H%%", "%%H")
        value, _ = value:gsub("M%%", "%%M")
        value, _ = value:gsub("S%%", "%%S")
        return value
    end
    return langs[lang][key] or langs["en"][key]
end

return { get = get }
