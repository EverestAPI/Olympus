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
    olympus_is_not_completely_up_to_date_you = [[Olympus is not completely up-to-date.
You might run into issues when trying to run Celeste or Lönn from Olympus.

This is because the integrated updater cannot update all the files.
To fix this, reinstall Olympus following the instructions on the Everest website.]],

    -- modinstaller.lua
    preparing_installation_of_s = [[Preparing installation of %s]],
    olympus_isn_t_fully_installed_please_run = [[Olympus isn't fully installed.
Please run install.sh to install the one-click installer handler.
install.sh can be found in your Olympus installation folder.]],

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
    it_is_required_to_install_xna_before_ins = [[It is required to install XNA before installing Everest.
If this copy of Celeste comes from Steam, run Celeste normally to install XNA.
Otherwise, manually install XNA using the button below.]],
    it_is_required_to_install_the_net_7_0_ru = [[It is required to install the .NET 7.0 Runtime before installing .NET Core versions of Everest.
Click the button below to download the installer.
Alternatively, you can manually install the runtime, then attempt the installation again.]],
    install_latest_version = [[Install Everest]],
    update_to_latest_version = [[Update Everest]],
    reinstall_latest_version = [[Reinstall Everest]],
    install_selected_version = [[Install selected version]],
    loading__ = [[Loading...]],

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
    page = [[Page #%d]],
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
    test_ok = [[OK]],
    test_ko = [[KO]],
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
Please drag and drop log.txt and log-sharp.txt into the #modding_help channel.
Before uploading, check your logs for sensitive info (like your username).]],

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
    nscanning = [[

Scanning...]],
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
    tooltip_favorite = [[Favorite]],
    tooltip_dependency_of_favorite = [[Dependency of one of your favorites]],
    tooltip_dependency = [[Dependency of one of your enabled mods]],
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
    preset_already_exists = [[Preset "%s" already exists!]],
    preset_not_found = [[Preset "%s" was not found.]],
    new_preset_name = [[New preset name]],
    preset = [[Preset]],
    preset_none = [[None]],
    preset_custom = [[Custom]],
    preset_modified = [[%s + changes]],
    preset_editing = [[Custom (editing %s)]],
    preset_selected = [[Selected]],
    selected_preset = [[Selected preset]],
    selected_preset_required = [[Select a preset first.]],
    preset_select = [[Select]],
    preset_merge = [[Merge]],
    preset_update = [[Update]],
    preset_rename = [[Rename]],
    preset_created = [[Created %s]],
    preset_updated = [[Updated %s]],
    preset_renamed = [[Renamed %s to %s]],
    preset_mod_count = [[%s mod(s)]],
    preset_missing_count = [[%s missing]],
    preset_remove_missing = [[Clean missing]],
    preset_missing_removed = [[Removed %s missing entries from %s]],
    no_missing_entries = [[No missing entries in %s]],
    no_presets = [[No presets yet.]],
    no_presets_to_update = [[No presets to update.]],
    create_preset_from_enabled = [[Create from enabled mods]],
    preset_actions = [[Preset actions]],
    add_to_selected_preset = [[Add to selected]],
    remove_from_selected_preset = [[Remove from selected]],
    add_to_all_presets = [[Add to all presets]],
    remove_from_all_presets = [[Remove from all presets]],
    mod_added_to_preset = [[Added %s to %s]],
    mod_removed_from_preset = [[Removed %s from %s]],
    mod_added_to_s_presets = [[Added %s to %s preset(s)]],
    mod_removed_from_s_presets = [[Removed %s from %s preset(s)]],
    mod_already_in_preset = [[%s is already in %s]],
    mod_not_in_preset = [[%s is not in %s]],
    confirm_remove_mod_from_all_presets = [[Remove %s from %s preset(s)?]],
    this_mod_depends_on_s_other_s_add_to_preset = [[This mod depends on %s other %s.
Do you want to add %s to the preset as well?]],
    add_dependencies = [[Add dependencies]],
    only_this_mod = [[Only this mod]],
    mod_and_deps_added_to_preset = [[Added %s and dependencies to %s]],
    mod_and_deps_added_to_s_presets = [[Added %s and dependencies to %s preset(s)]],
    replace = [[Replace]],
    edit_modpresets_txt = [[Edit modpresets.txt]],
    add_preset = [[Add preset]],
    mod_presets = [[Mod presets]],
    enabled = [[Enabled]],
    update_all = [[Update All]],
    open_mods_folder = [[Open mods folder]],
    install_mod_file = [[Install mod file]],
    edit_blacklist_txt = [[Edit blacklist.txt]],
    filter_list = [[Filters:]],
    all_categories = [[All categories]],
    no_category = [[No category]],
    only_show_enabled = [[Enabled only]],
    only_show_favorites = [[Favorites only]],
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
    note_this_only_covers_olympus_1 = [[NOTE: ]],
    note_this_only_covers_olympus_2 = [[This section only covers Olympus updates. To update Everest and Lönn, use the]],
    note_this_only_covers_olympus_3 = [[buttons in the main menu.]],
    theme_dark = [[Dark (Default)]],
    theme_light = [[Light]],

    -- C# stuff (Cmds.Download / CmdUpdateAllMods)
    csharp_downloadinglist = [[Downloading mod versions list]],
    csharp_downloadingfile = [[Downloading]],
    csharp_downloadingprogress = [[Downloading:]],
    csharp_checking = [[Checking for outdated mods]],
    csharp_updating = [[Updating]],
    csharp_installing = [[installing update]],
    csharp_finished_noop = [[Update check finished.
No updates were found.]],
    csharp_finished = [[Update successful!
The following mods were updated:]],
    csharp_checksum = [[verifying checksum]],
    csharp_unzipping = [[Unzipping]],
    csharp_unzipping_files = [[Unzipping {0} file(s)]],
    csharp_unzipped_files = [[Unzipped {0} file(s)]],
    csharp_downloaded = [[Downloaded {0} bytes in {1} second(s).]],
}

return {
    cjk_priority = cjk_priority,
    keys = keys
}
