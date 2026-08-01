function cjk_priority()
    return {
        "data/fonts/NotoSansSC-Regular.otf",
        "data/fonts/NotoSansTC-Regular.otf",
        "data/fonts/NotoSansJP-Regular.otf",
        "data/fonts/NotoSansKR-Regular.otf"
    }
end

local keys = {
    -- super common keys
    ok = [[确定]],
    cancel = [[取消]],
    yes = [[是]],
    no = [[否]],
    loading = [[加载中]],
    close = [[关闭]],

    -- dragndrop.lua
    olympus_is_currently_busy_with_something = [[Olympus 当前正忙于其他任务。]],
    olympus_can_t_handle_that_file_does_it_e = [[Olympus 无法处理该文件——它存在吗？]],
    everest_successfully_installed = [[Everest 安装成功]],
    launch = [[启动]],
    olympus_can_t_handle_that_file = [[Olympus 无法处理该文件。]],
    your_celeste_installation_list_is_still_ = [[你的 Celeste 安装列表仍为空。
是否前往 Celeste 安装管理器？]],

    -- main.lua
    olympus_sharp_startup_error = [[Olympus.Sharp 启动错误]],
    failed_loading_olympus_sharp = [[加载 Olympus.Sharp 失败：]],
    open_everest_website = [[打开 Everest 官网]],
    do_you_want_to_close_olympus = [[是否要关闭 Olympus？]],
    the_olympus_app_is_out_of_date_sometimes = [[Olympus 应用程序已过时。
有时，新功能和重要修复需要更新 Olympus 底层内容，
而 Olympus 自身无法自动完成这些更新。
尤其是 GameBanana 上的一键安装按钮，在 macOS 上曾无法使用。
要修复这个问题，你需要重新安装 Olympus。
请前往 Everest 官网查看具体说明。
继续使用过时的 Olympus 未来可能会导致崩溃。]],
    olympus_is_not_completely_up_to_date_you = [[Olympus 未完全更新到最新版本。
你在通过 Olympus 运行 Celeste 或 Lönn 时可能会遇到问题。
这是因为内置更新程序无法更新所有文件。
要修复此问题，请按照 Everest 官网上的说明重新安装 Olympus。]],

    -- modinstaller.lua
    preparing_installation_of_s = [[正在准备安装 %s]],
    olympus_isn_t_fully_installed_please_run = [[Olympus 尚未完全安装。
请运行 install.sh 以安装一键安装处理程序。
install.sh 位于你的 Olympus 安装文件夹中。]],

    -- modupdater.lua
    updating_enabled_mods = [[正在更新已启用的模组]],
    updating_all_mods = [[正在更新所有模组]],
    please_wait = [[请稍候...]],
    skip = [[跳过]],
    retry = [[重试]],
    open_logs_folder = [[打开日志文件夹]],
    run_anyway = [[仍然运行]],
    an_error_occurred_while_updating_your_mo = [[更新模组时出错。
请确保你已连接到互联网，并且 Lönn 未在运行！]],

    -- updater.lua
    cannot_determine_currently_running_versi = [[无法确定当前运行的 Olympus 版本！]],
    checking_for_updates = [[正在检查更新...]],
    error_downloading_builds_list = [[下载版本列表时出错：]],
    error_downloading_builds_list_invalid_ol = [[下载版本列表时出错：Olympus 构建 JSON 无效（缺少 value 属性）]],
    currently_installed_n = [[当前已安装：
]],
    newest_available_n = [[最新可用版本：
]],
    changelog_n = [[更新日志：
]],
    downloading = [[下载中...]],
    failed_to_download_n = [[下载失败：
]],
    no_updates_found = [[未发现更新。]],
    preparing_update_of_olympus = [[正在准备更新 Olympus]],
    olympus_successfully_updated = [[Olympus 更新成功]],
    restart_olympus = [[重启 Olympus]],
    there_is_a_new_version_available_update = [[有新版本的 Olympus 可用。
是否立即更新到 %s？]],
    there_is_a_new_version_available = [[有新版本的 Olympus 可用：%s]],

    -- utils.lua
    check_the_task_manager = [[ - 请检查任务管理器]],
    check_the_activity_monitor = [[ - 请检查活动监视器]],
    check_htop = [[ - 请检查 htop]],
    celeste_is_already_starting_up_please_wa = [[Celeste 已在启动中，请稍候。
你可以关闭此窗口。]],
    celeste_is_now_starting_in_the_backgroun = [[Celeste 正在后台启动。
你可以关闭此窗口。]],
    everest_is_now_starting_in_the_backgroun = [[Everest 正在后台启动。
你可以关闭此窗口。]],
    olympus_couldn_t_find_the_celeste_launch = [[Olympus 无法找到 Celeste 的启动文件。
请检查已安装的 Celeste 版本是否与你的系统匹配。
如果你正在使用 Lutris 或类似工具，则需要自行解决。]],
    celeste_or_something_looking_like_celest = [[Celeste（或看起来像 Celeste 的程序）已在运行。
如果你看不到它，可能它仍在启动中]],
    do_you_want_to_launch_another_instance_a = [[。
是否仍要启动另一个实例？]],
    opening = [[正在打开 ]],

    -- scenes/everest.lua
    everest_installer = [[Everest 安装程序]],
    versions = [[版本]],
    reload_versions_list = [[重新加载版本列表]],
    or_ = [[ 或 ]],
    install = [[安装]],
    detecting_the_celeste_version_failed_n_s = [[检测 Celeste 版本失败：
%s
请在主菜单中选择“管理”以检查你的安装路径。]],
    attempt_installation_anyway = [[仍然尝试安装]],
    remove_residual_files = [[移除残留文件]],
    install_xna = [[安装 XNA]],
    install_runtime = [[安装运行时]],
    uninstall = [[卸载]],
    uninstall_dialog = [[卸载 Everest 不会影响你的模组，
除非你手动删除它们、完全重装 Celeste，
或在原版 Celeste 中加载了已修改的存档。
在标题画面按住方向右键可在不重启游戏的情况下
关闭 Everest，这也符合竞速规则。
如果卸载 Everest 仍无法解决问题，
请前往你的游戏管理器的库，让其验证游戏文件。
Steam、EGS 和 itch.io 客户端都支持此操作，无需完全重装。]],
    uninstall_anyway = [[仍然卸载]],
    keep_everest = [[保留 Everest]],
    select_your_everest_zip_file = [[选择你的 Everest .zip 文件]],
    installation_canceled = [[安装已取消]],
    preparing_installation_of_everest_s = [[正在准备安装 Everest %s]],
    everest_s_successfully_installed = [[Everest %s 安装成功]],
    preparing_uninstallation_of_everest = [[正在准备卸载 Everest]],
    everest_successfully_uninstalled = [[Everest 卸载成功]],
    select_zip_from_disk = [[从磁盘选择 .zip 文件]],
    newest = [[最新]],
    pinned = [[置顶]],
    use_the_newest_version_for_more_features = [[使用最新版本以获得更多功能和错误修复。
如果你不想频繁更新，请使用最新的 ]],
    version_if_you_hate_updating = [[ 版本。]],
    your_current_version_of_celeste_is_outda = [[你当前的 Celeste 版本已过时。
请在安装 Everest 前先更新到最新版本。]],
    residual_files_from_a_net_core_build_hav = [[检测到 .NET Core 版本构建的残留文件。
这些文件可能导致旧版本 Everest 安装失败。
在安装 Everest 前应先移除它们。
]],
    it_is_required_to_install_xna_before_ins = [[在安装 Everest 之前必须先安装 XNA。
如果这份 Celeste 来自 Steam，正常运行 Celeste 即可安装 XNA。
否则，请使用下方按钮手动安装 XNA。]],
    it_is_required_to_install_the_net_7_0_ru = [[在安装 .NET Core 版本的 Everest 之前必须先安装 .NET 7.0 运行时。
点击下方按钮下载安装程序。
你也可以手动安装运行时，然后重新尝试安装。]],
    install_latest_version = [[安装 Everest]],
    update_to_latest_version = [[更新 Everest]],
    reinstall_latest_version = [[重新安装 Everest]],
    install_selected_version = [[安装所选版本]],
    loading__ = [[加载中...]],

    -- scenes/gamebanana.lua
    gamebanana = [[GameBanana]],
    most_recent = [[最新发布]],
    most_downloaded = [[下载最多]],
    most_viewed = [[浏览最多]],
    most_liked = [[点赞最多]],
    all = [[全部]],
    go_to_gamebanana_com = [[前往 gamebanana.com]],
    search = [[搜索]],
    featured = [[精选]],
    page = [[第 %d 页]],
    error_downloading_mod_list = [[下载模组列表时出错：]],
    error_downloading_subcategories_list = [[下载子分类列表时出错：]],
    error_downloading_categories_list = [[下载分类列表时出错：]],
    y_m_d_h_m_s = [[%Y-%m-%d %H:%M:%S]],
    d_view = [[%d 次浏览]],
    d_views = [[%d 次浏览]],
    d_like = [[%d 个赞]],
    d_likes = [[%d 个赞]],
    d_download = [[%d 次下载]],
    d_downloads = [[%d 次下载]],
    open_in_browser = [[在浏览器中打开]],

    -- scenes/gfwtest.lua
    connectivity_test = [[连接测试]],
    test_ok = [[成功]],
    test_ko = [[失败]],
    maddie_s_random_stuff = [[Maddie's Random Stuff]],
    github = [[GitHub]],
    azure_pipelines = [[Azure Pipelines]],
    everest_website = [[Everest 官网]],
    gamebanana_files = [[GameBanana 文件]],
    nif_lua_is_ko_but_sharp_is_ok_deleting = [[如果 Lua 显示失败但 Sharp 正常，删除 ]],
    libcurl_dll_might_help = [[\\libcurl.dll 可能会有帮助。]],
    service = [[服务]],
    lua = [[Lua]],
    sharp = [[Sharp]],
    reload = [[重新加载]],
    maddie480_ovh_nprovides_the_everest_vers = [[ (maddie480.ovh)
提供 Olympus 使用的大多数在线服务，如遇到问题请启用“API 镜像”]],
    github_com_nhosts_stable_versions_of_eve = [[ (github.com)
托管 Everest 的稳定版本]],
    dev_azure_com_nhosts_olympus_updates_and = [[ (dev.azure.com)
托管 Olympus 更新以及非稳定版本的 Everest]],
    everestapi_github_io_nprovides_olympus_n = [[ (everestapi.github.io)
提供 Olympus 新闻，显示在主菜单右侧]],
    files_gamebanana_com_nhosts_all_celeste_ = [[ (files.gamebanana.com)
托管所有 Celeste 模组，如遇到问题请在选项与更新中选择镜像]],
    you_can_use_this_page_to_check_your_conn = [[你可以使用此页面检查与 Olympus 所用各个网络服务的连接情况。
如果某项测试失败，Olympus 中对应的功能可能无法使用。
以下是可能出现此情况的一些原因：
- 你的杀毒软件/防火墙阻止了 Olympus 访问互联网。
- 该服务已宕机，或存在网络问题，请稍后重试。
- 网络过滤正在屏蔽该网站，请尝试更换网络或切换 VPN。]],

    -- scenes/installer.lua
    installer = [[安装程序]],
    autoclosing_in_d = [[将在 %d 秒后自动关闭...]],
    open_log = [[打开日志]],
    open_log_folder = [[打开日志文件夹]],
    you_can_ask_for_help_in_the_celeste_disc = [[你可以在 Celeste Discord 服务器中寻求帮助。
邀请链接可在 Everest 官网找到。
请将 log.txt 和 log-sharp.txt 拖放到 #modding_help 频道中。
上传前，请检查日志中是否包含敏感信息（例如你的用户名）。]],

    -- scenes/installmanager.lua
    install_manager = [[安装管理器]],
    scanning = [[正在扫描...]],
    remove = [[移除]],
    add = [[添加]],
    i_know_what_i_m_doing = [[我知道我在做什么。]],
    verify = [[验证]],
    browse = [[浏览]],
    your_installations = [[你的安装]],
    manually_select_celeste_exe = [[手动选择 Celeste.exe]],
    found = [[已找到]],
    the_uwp_xbox_microsoft_store_version_of_ = [[目前不支持 Celeste 的 UWP（Xbox/微软商店）版本。
所有游戏数据均已加密，甚至连对话文本文件也无法编辑。
游戏代码本身经过 AOT 编译——现有的代码模组均无法使用。
甚至 Lönn 和 Ahorn 目前也无法加载所需的游戏数据。
除非 Everest 被重写，或有人专门为这一特殊版本
开发模组加载器，否则在可预见的将来
都不要指望这方面有任何进展。]],
    verifying_the_file_integrity_will_tell_s = [[验证文件完整性将使 Steam 重新下载
任何被修改过的文件，从而卸载 Everest。
在 Steam 下载游戏文件期间请不要使用 Olympus。
你需要自行查看下载进度。
是否继续？]],
    olympus_needs_to_know_which_celeste_inst1 = [[Olympus 需要知道你要管理哪些 Celeste 安装。
自动检测到的安装将列在下方，可添加到此列表中。
如果未自动检测到任何安装，请手动选择 Celeste.exe。]],
    olympus_needs_to_know_which_celeste_inst2 = [[Olympus 需要知道你要管理哪些 Celeste 安装。
你可以将下方列表中自动检测到的安装添加到此列表。
]],
    olympus_needs_to_know_which_celeste_inst3 = [[Olympus 需要知道你要管理哪些 Celeste 安装。
未自动检测到任何安装。请手动选择 Celeste.exe 以将其添加到 Olympus。
]],

    -- scenes/mainmenu.lua
    main_menu = [[主菜单]],
    installations = [[安装]],
    manage = [[管理]],
    d_new_install_found = [[发现 %d 个新安装。]],
    d_new_installs_found = [[发现 %d 个新安装。]],
    nscanning = [[
正在扫描...]],
    l_nn_map_editor = [[Lönn（地图编辑器）]],
    l_nn_is_currently_not_installed = [[当前未安装 Lönn。]],
    currently_installed_version = [[当前已安装版本：]],
    s_nlatest_version_s_ninstall_folder_s = [[%s
最新版本：%s
安装文件夹：%s]],
    install_l_nn = [[安装 Lönn]],
    update_l_nn = [[更新 Lönn]],
    preparing_installation_of_l_nn = [[正在准备安装 Lönn ]],
    l_nn = [[Lönn ]],
    successfully_installed = [[ 安装成功]],
    launch_l_nn = [[启动 Lönn]],
    uninstall_l_nn = [[卸载 Lönn]],
    this_will_delete_directory = [[这将删除目录 ]],
    nare_you_sure = [[。
你确定吗？]],
    preparing_uninstallation_of_l_nn = [[正在准备卸载 Lönn]],
    l_nn_successfully_uninstalled = [[Lönn 卸载成功]],
    ncheck_the_readme_for_usage_instructions = [[
查看 README 以获取使用说明、快捷键、帮助等内容：]],
    open_l_nn_readme = [[打开 Lönn README]],
    download_mods = [[下载模组]],
    manage_installed_mods = [[管理已安装模组]],
    options_updates = [[选项与更新]],
    options = [[选项]],
    news = [[新闻]],
    everest = [[Everest]],
    celeste = [[Celeste]],
    install_everest = [[安装 Everest]],
    olympus_failed_fetching_the_news_feed = [[Olympus 获取新闻源失败。]],
    olympus_failed_fetching_a_news_entry = [[Olympus 获取某条新闻失败。]],
    a_news_entry_was_in_an_unexpected_format = [[某条新闻的格式不符合预期。]],
    a_news_entry_contained_invalid_metadata = [[某条新闻包含无效的元数据。]],
    ahorn = [[Ahorn]],
    your_celeste_installation_list_is_empty_ = [[你的 Celeste 安装列表为空。
是否前往 Celeste 安装管理器？]],
    your_celeste_installs_list_is_empty_pres = [[你的 Celeste 安装列表为空。
请点击下方的“管理”按钮。]],

    -- scenes/modlist.lua
    mod_manager = [[模组管理器]],
    no1 = [[0]],
    s_enabled_s = [[已启用 %s 个%s]],
    mod = [[模组]],
    mods = [[模组]],
    no_mod_info_available = [[（无可用模组信息）]],
    this_mod_depends_on_s_other_disabled_s_n = [[该模组依赖于 %s 个其他已禁用的%s。
是否同时启用%s？]],
    mod1 = [[模组]],
    mods1 = [[模组]],
    tooltip_favorite = [[收藏]],
    tooltip_dependency_of_favorite = [[是你某个收藏项的依赖项]],
    tooltip_dependency = [[是你某个已启用模组的依赖项]],
    it = [[它]],
    them = [[它们]],
    s_other_s_no_longer_required_for_any_ena = [[%s 个其他%s不再被任何已启用的模组需要。
是否同时禁用%s？]],
    mod_is = [[模组]],
    mods_are = [[模组]],
    s_other_s_on_this_mod_ndo_you_want_to_di = [[%s 个其他%s依赖此模组。
是否同时禁用%s？]],
    mod_depends = [[个模组]],
    mods_depend = [[个模组]],
    delete = [[删除]],
    keep = [[保留]],
    some_mods_couldn_t_be_loaded_make_sure_t = [[部分模组无法加载，请确认它们已安装：
]],
    something_went_wrong_deleted_preset_s_na = [[出现问题，待删除预设的名称为空！]],
    something_went_wrong_name_is_nil = [[出现问题，名称为空！]],
    preset_name_can_t_be_empty = [[预设名称不能为空！]],
    this_preset_already_exists_do_you_wish_t = [[该预设已存在！是否要覆盖它？]],
    preset_already_exists = [[预设“%s”已存在！]],
    preset_not_found = [[找不到预设“%s”。]],
    new_preset_name = [[新预设名称]],
    preset = [[预设]],
    preset_none = [[无]],
    preset_custom = [[自定义]],
    preset_modified = [[%s + 更改]],
    preset_editing = [[自定义（正在编辑 %s）]],
    preset_selected = [[已选中]],
    selected_preset = [[已选预设]],
    selected_preset_required = [[请先选择一个预设。]],
    preset_select = [[选择]],
    preset_merge = [[合并]],
    preset_update = [[更新]],
    preset_rename = [[重命名]],
    preset_created = [[已创建 %s]],
    preset_updated = [[已更新 %s]],
    preset_renamed = [[已将 %s 重命名为 %s]],
    preset_mod_count = [[%s 个模组]],
    preset_missing_count = [[缺失 %s 个]],
    preset_remove_missing = [[清理缺失项]],
    preset_missing_removed = [[已移除 %s 个缺失项（%s）]],
    no_missing_entries = [[%s 中没有缺失项]],
    no_presets = [[还没有预设。]],
    no_presets_to_update = [[没有可更新的预设。]],
    create_preset_from_enabled = [[从已启用模组创建]],
    preset_actions = [[预设操作]],
    add_to_selected_preset = [[添加到已选预设]],
    remove_from_selected_preset = [[从已选预设移除]],
    add_to_all_presets = [[添加到所有预设]],
    remove_from_all_presets = [[从所有预设移除]],
    mod_added_to_preset = [[已将 %s 添加到 %s]],
    mod_removed_from_preset = [[已将 %s 从 %s 移除]],
    mod_added_to_s_presets = [[已将 %s 添加到 %s 个预设]],
    mod_removed_from_s_presets = [[已将 %s 从 %s 个预设移除]],
    mod_already_in_preset = [[%s 已在 %s 中]],
    mod_not_in_preset = [[%s 不在 %s 中]],
    confirm_remove_mod_from_all_presets = [[要移除 %s（共 %s 个预设）吗？]],
    this_mod_depends_on_s_other_s_add_to_preset = [[此模组依赖另外 %s 个%s。
是否也将%s添加到预设中？]],
    add_dependencies = [[添加依赖]],
    only_this_mod = [[仅此模组]],
    mod_and_deps_added_to_preset = [[已将 %s 及其依赖添加到 %s]],
    mod_and_deps_added_to_s_presets = [[已将 %s 及其依赖添加到 %s 个预设]],
    replace = [[替换]],
    edit_modpresets_txt = [[编辑 modpresets.txt]],
    add_preset = [[添加预设]],
    mod_presets = [[模组预设]],
    enabled = [[已启用]],
    update_all = [[全部更新]],
    open_mods_folder = [[打开模组文件夹]],
    install_mod_file = [[从文件安装模组]],
    edit_blacklist_txt = [[编辑 blacklist.txt]],
    filter_list = [[筛选：]],
    all_categories = [[所有分类]],
    no_category = [[无分类]],
    only_show_enabled = [[仅显示已启用]],
    only_show_favorites = [[仅显示收藏]],
    enable_all = [[全部启用]],
    disable_all = [[全部禁用]],
    search_by_file_name_mod_title_or_everest = [[按文件名、模组标题或 everest.yaml ID 搜索]],
    an_error_occurred_while_loading_the_mod_ = [[加载模组列表时出错。]],
    are_you_sure_that_you_want_to_delete = [[你确定要删除 ]],
    you_will_need_to_redownload_the_mod_to_u = [[吗？
你需要重新下载该模组才能再次使用它。
提示：禁用模组可以阻止 Everest 加载它，效果和删除一样能减少卡顿。]],
    questionmark = [[？]],

    -- scenes/options.lua
    random_default = [[随机（默认）]],
    background = [[背景 #]],
    high_default = [[高（默认）]],
    medium = [[中]],
    low = [[低]],
    minimal = [[最低]],
    stable_default = [[稳定版（默认）]],
    development = [[开发版]],
    all_mods = [[所有模组]],
    enabled_mods_only = [[仅已启用的模组]],
    disabled_default = [[已禁用（默认）]],
    germany_0x0a_de = [[德国 (0x0a.de)]],
    china_weg_fan = [[中国 (weg.fan)]],
    n_america_celestemods_com = [[北美 (celestemods.com)]],
    _x0a_de_default = [[0x0a.de（默认）]],
    celestemods_com = [[celestemods.com]],
    disabled = [[已禁用]],
    theme = [[主题]],
    select_your_theme = [[选择你的主题]],
    background_image = [[背景图片]],
    select_your_background = [[选择你的背景图片]],
    quality = [[画质]],
    gradient = [[渐变]],
    enabled_default = [[已启用（默认）]],
    parallax = [[视差]],
    vertical_sync = [[垂直同步]],
    updates = [[更新]],
    update_mods_on_startup = [[启动时更新模组]],
    use_opengl = [[使用 OpenGL]],
    close_after_one_click_install = [[一键安装后关闭]],
    open_installation_folder = [[打开安装文件夹]],
    open_log_and_config_folder = [[打开日志与配置文件夹]],
    mirrors = [[镜像]],
    download_mirror = [[下载镜像]],
    api_mirror = [[API 镜像]],
    image_mirror = [[图片镜像]],
    this_is_your_current_theme_the_quick_bro = [[这是你当前的主题。
龙跳天门]],
    this_is_the_new_theme_over_the_lazy_dog = [[这是新的主题。
虎卧凰阁]],
    if_you_have_difficulty_downloading_mods_ = [[如果你在下载模组或加载 Olympus 部分内容时遇到困难，可以尝试以下选项。
- ]],
    can_help_if_mod_downloads_are_slow_or_ga = [[ 可在模组下载速度慢或 GameBanana 出现问题时提供帮助。
- ]],
    can_help_if_the_install_everest_or_downl = [[ 可在“安装 Everest”或“下载模组”页面无法加载时提供帮助。不过模组浏览会变慢！
- ]],
    changes_where_the_mod_images_in_the_mod_ = [[ 用于更改模组浏览器中图片的来源。你也可以选择不使用镜像，但旧模组将没有图片。]],
    language = [[语言]],
    restart_to_apply_changes_in_languages = [[你需要重启 Olympus 才能使语言更改完全生效。]],
    note_this_only_covers_olympus_1 = [[注意：]],
    note_this_only_covers_olympus_2 = [[此部分仅涉及 Olympus 自身的更新。要更新 Everest 和 Lönn，请使用主菜单中的]],
    note_this_only_covers_olympus_3 = [[按钮。]],
    theme_dark = [[深色模式（默认）]],
    theme_light = [[浅色模式]],

    -- C# stuff (Cmds.Download / CmdUpdateAllMods)
    csharp_downloadinglist = [[正在下载模组版本列表]],
    csharp_downloadingfile = [[正在下载]],
    csharp_downloadingprogress = [[下载中：]],
    csharp_checking = [[正在检查过期模组]],
    csharp_updating = [[正在更新]],
    csharp_installing = [[正在安装更新]],
    csharp_finished_noop = [[更新检查完成。
未发现任何更新。]],
    csharp_finished = [[更新成功！
以下模组已更新：]],
    csharp_checksum = [[正在校验文件完整性]],
    csharp_unzipping = [[解压中]],
    csharp_unzipping_files = [[正在解压 {0} 项…]],
    csharp_unzipped_files = [[解压了 {0} 项。]],
    csharp_downloaded = [[{1} 秒内下载了 {0} 字节。]],
}

return {
    cjk_priority = cjk_priority,
    keys = keys
}
