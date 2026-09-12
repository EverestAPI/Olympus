function cjk_priority()
    return {
        "data/fonts/NotoSansKR-Regular.otf",
        "data/fonts/NotoSansJP-Regular.otf",
        "data/fonts/NotoSansSC-Regular.otf",
        "data/fonts/NotoSansTC-Regular.otf"
    }
end

local keys = {
    -- super common keys
    ok = [[확인]],
    cancel = [[취소]],
    yes = [[예]],
    no = [[아니요]],
    loading = [[불러오는 중]],
    close = [[닫기]],

    -- dragndrop.lua
    olympus_is_currently_busy_with_something = [[Olympus가 현재 다른 작업을 처리 중입니다.]],
    olympus_can_t_handle_that_file_does_it_e = [[Olympus에서 해당 파일을 처리할 수 없습니다. 파일이 존재하는지 확인해 주세요.]],
    everest_successfully_installed = [[Everest를 성공적으로 설치했습니다]],
    launch = [[실행]],
    olympus_can_t_handle_that_file = [[Olympus에서 해당 파일을 처리할 수 없습니다.]],
    your_celeste_installation_list_is_still_ = [[Celeste 설치 목록이 아직 비어 있습니다.
Celeste 설치 관리자로 이동하시겠습니까?]],

    -- main.lua
    olympus_sharp_startup_error = [[Olympus.Sharp 시작 오류]],
    failed_loading_olympus_sharp = [[Olympus.Sharp를 불러오지 못했습니다: ]],
    open_everest_website = [[Everest 웹사이트 열기]],
    do_you_want_to_close_olympus = [[Olympus를 종료하시겠습니까?]],
    the_olympus_app_is_out_of_date_sometimes = [[Olympus 앱이 오래된 버전입니다.
새로운 기능이나 대규모 수정 사항은 때때로 Olympus 내부 구성 요소의 업데이트가 필요하며,
이 업데이트는 Olympus 자체에서 적용할 수 없습니다.
특히 GameBanana의 원클릭 설치 버튼이 macOS에서 작동하지 않는 문제가 있었습니다.
이 문제를 해결하려면 Olympus를 다시 설치해야 합니다.
자세한 내용은 Everest 웹사이트의 안내를 확인해 주세요.
오래된 Olympus를 계속 사용하면 이후 충돌이 발생할 수 있습니다.]],
    olympus_is_not_completely_up_to_date_you = [[Olympus가 완전히 최신 상태가 아닙니다.
Olympus에서 Celeste 또는 Lönn을 실행할 때 문제가 발생할 수 있습니다.

내장 업데이터가 모든 파일을 업데이트할 수 없기 때문입니다.
문제를 해결하려면 Everest 웹사이트의 안내에 따라 Olympus를 다시 설치해 주세요.]],

    -- modinstaller.lua
    preparing_installation_of_s = [[%s 설치 준비 중]],
    olympus_isn_t_fully_installed_please_run = [[Olympus가 완전히 설치되지 않았습니다.
원클릭 설치 처리기를 설치하려면 install.sh를 실행해 주세요.
install.sh는 Olympus 설치 폴더에서 찾을 수 있습니다.]],

    -- modupdater.lua
    updating_enabled_mods = [[활성화된 모드 업데이트 중]],
    updating_all_mods = [[모든 모드 업데이트 중]],
    please_wait = [[잠시만 기다려 주세요...]],
    skip = [[건너뛰기]],
    retry = [[다시 시도]],
    open_logs_folder = [[로그 폴더 열기]],
    run_anyway = [[그래도 실행]],
    an_error_occurred_while_updating_your_mo = [[모드를 업데이트하는 중 오류가 발생했습니다.
인터넷에 연결되어 있고 Lönn이 실행 중이 아닌지 확인해 주세요!]],

    -- updater.lua
    cannot_determine_currently_running_versi = [[현재 실행 중인 Olympus 버전을 확인할 수 없습니다!]],
    checking_for_updates = [[업데이트 확인 중...]],
    error_downloading_builds_list = [[빌드 목록 다운로드 오류: ]],
    error_downloading_builds_list_invalid_ol = [[빌드 목록 다운로드 오류: 잘못된 Olympus 빌드 JSON입니다(value 속성 없음)]],
    currently_installed_n = [[현재 설치됨:
]],
    newest_available_n = [[사용 가능한 최신 버전:
]],
    changelog_n = [[변경 사항:
]],
    downloading = [[다운로드 중...]],
    failed_to_download_n = [[다운로드 실패:
]],
    no_updates_found = [[업데이트를 찾지 못했습니다.]],
    preparing_update_of_olympus = [[Olympus 업데이트 준비 중]],
    olympus_successfully_updated = [[Olympus를 성공적으로 업데이트했습니다]],
    restart_olympus = [[Olympus 다시 시작]],
    there_is_a_new_version_available_update = [[새로운 Olympus 버전을 사용할 수 있습니다.
지금 %s 버전으로 업데이트하시겠습니까?]],
    there_is_a_new_version_available = [[새로운 Olympus 버전을 사용할 수 있습니다: %s]],

    -- utils.lua
    check_the_task_manager = [[ - 작업 관리자 확인]],
    check_the_activity_monitor = [[ - 활성 상태 보기 확인]],
    check_htop = [[ - htop 확인]],
    celeste_is_already_starting_up_please_wa = [[Celeste가 이미 시작 중입니다. 잠시만 기다려 주세요.
이 창은 닫아도 됩니다.]],
    celeste_is_now_starting_in_the_backgroun = [[Celeste가 백그라운드에서 시작되고 있습니다.
이 창은 닫아도 됩니다.]],
    everest_is_now_starting_in_the_backgroun = [[Everest가 백그라운드에서 시작되고 있습니다.
이 창은 닫아도 됩니다.]],
    olympus_couldn_t_find_the_celeste_launch = [[Olympus에서 Celeste 실행 파일을 찾지 못했습니다.
설치된 Celeste 버전이 사용 중인 운영체제와 일치하는지 확인해 주세요.
Lutris 또는 유사한 도구를 사용 중이라면 별도로 해결해야 합니다.]],
    celeste_or_something_looking_like_celest = [[Celeste(또는 Celeste처럼 보이는 프로그램)가 이미 실행 중입니다.
보이지 않는다면 아직 시작 중일 수 있습니다]],
    do_you_want_to_launch_another_instance_a = [[.
그래도 다른 인스턴스를 실행하시겠습니까?]],
    opening = [[여는 중]],

    -- scenes/everest.lua
    everest_installer = [[Everest 설치 관리자]],
    versions = [[버전]],
    reload_versions_list = [[버전 목록 새로고침]],
    or_ = [[ 또는 ]],
    install = [[설치]],
    detecting_the_celeste_version_failed_n_s = [[Celeste 버전 감지에 실패했습니다:
%s

메인 메뉴에서 "관리"를 선택하여 설치 경로를 확인해 주세요.]],
    attempt_installation_anyway = [[그래도 설치 시도]],
    remove_residual_files = [[잔여 파일 제거]],
    install_xna = [[XNA 설치]],
    install_runtime = [[런타임 설치]],
    uninstall = [[제거]],
    uninstall_dialog = [[Everest를 제거해도 모든 모드는 그대로 유지됩니다.
단, 모드를 직접 삭제하거나 Celeste를 완전히 다시 설치하거나,
Everest가 없는 Celeste에서 모드가 적용된 저장 파일을 불러오는 경우는 예외입니다.

타이틀 화면에서 오른쪽을 길게 누르면 게임을 다시 시작할 때까지 Everest를 끌 수 있으며,
이 방법은 스피드런 규정에서도 허용됩니다.

Everest를 제거해도 원하는 결과가 나오지 않는다면,
게임 관리자의 라이브러리에서 게임 파일 무결성 검사를 실행해 주세요.
Steam, EGS, itch.io 앱에서는 전체 재설치 없이 이 작업을 수행할 수 있습니다.]],
    uninstall_anyway = [[그래도 제거]],
    keep_everest = [[Everest 유지]],
    select_your_everest_zip_file = [[Everest .zip 파일 선택]],
    installation_canceled = [[설치가 취소되었습니다]],
    preparing_installation_of_everest_s = [[Everest %s 설치 준비 중]],
    everest_s_successfully_installed = [[Everest %s를 성공적으로 설치했습니다]],
    preparing_uninstallation_of_everest = [[Everest 제거 준비 중]],
    everest_successfully_uninstalled = [[Everest를 성공적으로 제거했습니다]],
    select_zip_from_disk = [[디스크에서 .zip 선택]],
    newest = [[최신]],
    pinned = [[고정]],
    use_the_newest_version_for_more_features = [[더 많은 기능과 버그 수정을 위해 가장 최신 버전을 사용하세요.
업데이트가 번거롭다면 최신 ]],
    version_if_you_hate_updating = [[ 버전을 사용하세요.]],
    your_current_version_of_celeste_is_outda = [[현재 Celeste 버전이 오래되었습니다.
Everest를 설치하기 전에 최신 버전으로 업데이트해 주세요.]],
    residual_files_from_a_net_core_build_hav = [[.NET Core 빌드의 잔여 파일이 감지되었습니다.
이 파일들은 이전 Everest 버전 설치를 실패하게 만들 수 있습니다.
Everest 설치를 시도하기 전에 제거하는 것이 좋습니다.
]],
    it_is_required_to_install_xna_before_ins = [[Everest를 설치하기 전에 XNA를 설치해야 합니다.
이 Celeste가 Steam 버전이라면 Celeste를 정상 실행하여 XNA를 설치하세요.
그 외의 경우 아래 버튼을 사용해 XNA를 직접 설치해 주세요.]],
    it_is_required_to_install_the_net_7_0_ru = [[.NET Core 버전의 Everest를 설치하려면 .NET 7.0 Runtime이 필요합니다.
아래 버튼을 클릭하여 설치 프로그램을 다운로드하세요.
또는 런타임을 직접 설치한 뒤 다시 설치를 시도할 수 있습니다.]],
    install_latest_version = [[Everest 설치]],
    update_to_latest_version = [[Everest 업데이트]],
    reinstall_latest_version = [[Everest 재설치]],
    install_selected_version = [[선택한 버전 설치]],
    loading__ = [[불러오는 중...]],

    -- scenes/gamebanana.lua
    gamebanana = [[GameBanana]],
    most_recent = [[최신순]],
    last_updated = [[최근 업데이트순]],
    most_downloaded = [[다운로드순]],
    most_viewed = [[조회순]],
    most_liked = [[좋아요순]],
    all = [[전체]],
    go_to_gamebanana_com = [[gamebanana.com으로 이동]],
    search = [[검색]],
    featured = [[추천]],
    page = [[페이지 #%d]],
    error_downloading_mod_list = [[모드 목록 다운로드 오류: ]],
    error_downloading_subcategories_list = [[하위 카테고리 목록 다운로드 오류: ]],
    error_downloading_categories_list = [[카테고리 목록 다운로드 오류: ]],
    y_m_d_h_m_s = [[%Y-%m-%d %H:%M:%S]],
    d_view = [[조회 %d회]],
    d_views = [[조회 %d회]],
    d_like = [[좋아요 %d개]],
    d_likes = [[좋아요 %d개]],
    d_download = [[다운로드 %d회]],
    d_downloads = [[다운로드 %d회]],
    open_in_browser = [[브라우저에서 열기]],

    -- scenes/gfwtest.lua
    connectivity_test = [[연결 테스트]],
    test_ok = [[OK]],
    test_ko = [[KO]],
    maddie_s_random_stuff = [[Maddie의 기타 서비스]],
    github = [[GitHub]],
    azure_pipelines = [[Azure Pipelines]],
    everest_website = [[Everest 웹사이트]],
    gamebanana_files = [[GameBanana 파일]],
    nif_lua_is_ko_but_sharp_is_ok_deleting = [[Lua는 KO이고 Sharp는 OK라면, 다음 파일을 삭제하면 도움이 될 수 있습니다: ]],
    libcurl_dll_might_help = [[\\libcurl.dll]],
    service = [[서비스]],
    lua = [[Lua]],
    sharp = [[Sharp]],
    reload = [[새로고침]],
    maddie480_ovh_nprovides_the_everest_vers = [[ (maddie480.ovh)
Olympus가 사용하는 대부분의 온라인 서비스를 제공합니다. 문제가 있다면 "API 미러"를 활성화해 보세요.]],
    github_com_nhosts_stable_versions_of_eve = [[ (github.com)
Everest의 안정 버전을 제공합니다.]],
    dev_azure_com_nhosts_olympus_updates_and = [[ (dev.azure.com)
Olympus 업데이트와 Everest의 비안정 버전을 제공합니다.]],
    everestapi_github_io_nprovides_olympus_n = [[ (everestapi.github.io)
Olympus 뉴스가 제공되며 메인 메뉴 오른쪽에 표시됩니다.]],
    files_gamebanana_com_nhosts_all_celeste_ = [[ (files.gamebanana.com)
모든 Celeste 모드를 제공합니다. 문제가 있다면 옵션 및 업데이트에서 미러를 선택해 보세요.]],
    you_can_use_this_page_to_check_your_conn = [[이 페이지에서 Olympus가 사용하는 여러 웹 서비스와의 연결 상태를 확인할 수 있습니다.
테스트 중 하나가 실패하면 Olympus의 해당 기능을 사용할 수 없을 가능성이 높습니다.
가능한 원인은 다음과 같습니다:
- 백신 또는 방화벽이 Olympus의 인터넷 연결을 차단하고 있습니다.
- 서비스가 중단되었거나 네트워크 문제가 있습니다. 나중에 다시 시도해 보세요.
- 네트워크 필터링이 웹사이트를 차단하고 있습니다. 다른 연결을 사용하거나 VPN을 켜거나 꺼 보세요.]],

    -- scenes/installer.lua
    installer = [[설치 프로그램]],
    autoclosing_in_d = [[%d초 후 자동으로 닫힙니다...]],
    open_log = [[로그 열기]],
    open_log_folder = [[로그 폴더 열기]],
    you_can_ask_for_help_in_the_celeste_disc = [[Celeste Discord 서버에서 도움을 요청할 수 있습니다.
초대 링크는 Everest 웹사이트에서 찾을 수 있습니다.
log.txt와 log-sharp.txt를 #modding_help 채널에 드래그 앤 드롭해 주세요.
업로드하기 전에 로그에 사용자 이름과 같은 민감한 정보가 포함되어 있지 않은지 확인하세요.]],

    -- scenes/installmanager.lua
    install_manager = [[설치 관리]],
    scanning = [[검색 중...]],
    remove = [[제거]],
    add = [[추가]],
    i_know_what_i_m_doing = [[무엇을 하는지 알고 있습니다.]],
    verify = [[검증]],
    browse = [[찾아보기]],
    your_installations = [[내 설치 목록]],
    manually_select_celeste_exe = [[Celeste.exe 직접 선택]],
    found = [[발견됨]],
    the_uwp_xbox_microsoft_store_version_of_ = [[Celeste의 UWP(Xbox/Microsoft Store) 버전은 현재 지원되지 않습니다.
대화 텍스트 파일을 포함한 모든 게임 데이터가 암호화되어 있어 편집할 수 없습니다.
게임 코드 자체도 AOT 컴파일되어 있어 기존 코드 모드가 작동하지 않습니다.
현재 Lönn과 Ahorn 역시 필요한 게임 데이터를 불러올 수 없습니다.
Everest가 새로 작성되거나 이 특수 버전만을 위한
모드 로더 개발이 시작되지 않는 한,
가까운 시일 내에 작동할 가능성은 거의 없습니다.]],
    verifying_the_file_integrity_will_tell_s = [[파일 무결성 검사를 실행하면 Steam이 수정된 파일을 다시 다운로드하며,
그 과정에서 Everest가 제거됩니다.
Steam이 게임 파일을 다운로드하는 동안 Olympus를 사용하지 마세요.
다운로드 진행 상황은 직접 확인해야 합니다.
계속하시겠습니까?]],
    olympus_needs_to_know_which_celeste_inst1 = [[Olympus에서 관리할 Celeste 설치본을 지정해야 합니다.
자동으로 발견된 설치본은 아래에 표시되며 이 목록에 추가할 수 있습니다.
자동으로 설치본을 찾지 못했다면 Celeste.exe를 직접 선택해 주세요.]],
    olympus_needs_to_know_which_celeste_inst2 = [[Olympus에서 관리할 Celeste 설치본을 지정해야 합니다.
아래 목록에서 자동으로 발견된 설치본을 이 목록에 추가할 수 있습니다.
]],
    olympus_needs_to_know_which_celeste_inst3 = [[Olympus에서 관리할 Celeste 설치본을 지정해야 합니다.
자동으로 발견된 설치본이 없습니다. Celeste.exe를 직접 선택하여 Olympus에 추가해 주세요.
]],

    -- scenes/mainmenu.lua
    main_menu = [[메인 메뉴]],
    installations = [[설치 목록]],
    manage = [[관리]],
    d_new_install_found = [[새 설치본 %d개를 찾았습니다.]],
    d_new_installs_found = [[새 설치본 %d개를 찾았습니다.]],
    nscanning = [[

검색 중...]],
    l_nn_map_editor = [[Lönn (맵 에디터)]],
    l_nn_is_currently_not_installed = [[Lönn이 현재 설치되어 있지 않습니다.]],
    currently_installed_version = [[현재 설치된 버전: ]],
    s_nlatest_version_s_ninstall_folder_s = [[%s
최신 버전: %s
설치 폴더: %s]],
    install_l_nn = [[Lönn 설치]],
    update_l_nn = [[Lönn 업데이트]],
    preparing_installation_of_l_nn = [[Lönn 설치 준비 중 ]],
    l_nn = [[Lönn ]],
    successfully_installed = [[ 설치 완료]],
    launch_l_nn = [[Lönn 실행]],
    uninstall_l_nn = [[Lönn 제거]],
    this_will_delete_directory = [[다음 디렉터리를 삭제합니다: ]],
    nare_you_sure = [[.
계속하시겠습니까?]],
    preparing_uninstallation_of_l_nn = [[Lönn 제거 준비 중]],
    l_nn_successfully_uninstalled = [[Lönn을 성공적으로 제거했습니다]],
    ncheck_the_readme_for_usage_instructions = [[사용 방법, 단축키, 도움말 등은 README를 확인해 주세요:]],
    open_l_nn_readme = [[Lönn README 열기]],
    download_mods = [[모드 다운로드]],
    manage_installed_mods = [[설치된 모드 관리]],
    options_updates = [[옵션 및 업데이트]],
    options = [[옵션]],
    news = [[뉴스]],
    everest = [[Everest]],
    celeste = [[Celeste]],
    install_everest = [[Everest 설치]],
    olympus_failed_fetching_the_news_feed = [[Olympus에서 뉴스 피드를 가져오지 못했습니다.]],
    olympus_failed_fetching_a_news_entry = [[Olympus에서 뉴스 항목을 가져오지 못했습니다.]],
    a_news_entry_was_in_an_unexpected_format = [[뉴스 항목의 형식이 올바르지 않습니다.]],
    a_news_entry_contained_invalid_metadata = [[뉴스 항목에 잘못된 메타데이터가 포함되어 있습니다.]],
    ahorn = [[Ahorn]],
    your_celeste_installation_list_is_empty_ = [[Celeste 설치 목록이 비어 있습니다.
Celeste 설치 관리자로 이동하시겠습니까?]],
    your_celeste_installs_list_is_empty_pres = [[Celeste 설치 목록이 비어 있습니다.
아래의 관리 버튼을 눌러 주세요.]],

    -- scenes/modlist.lua
    mod_manager = [[모드 관리자]],
    no1 = [[아니요]],
    s_enabled_s = [[%s %s 활성화됨]],
    mod = [[모드]],
    mods = [[모드]],
    no_mod_info_available = [[(모드 정보 없음)]],
    this_mod_depends_on_s_other_disabled_s_n = [[이 모드는 비활성화된 다른 %s개의 %s에 의존합니다.
%s도 함께 활성화하시겠습니까?]],
    mod1 = [[모드]],
    mods1 = [[모드]],
    tooltip_favorite = [[즐겨찾기]],
    tooltip_dependency_of_favorite = [[즐겨찾기한 모드의 종속성]],
    tooltip_dependency = [[활성화된 모드의 종속성]],
    it = [[해당 모드]],
    them = [[해당 모드들]],
    s_other_s_no_longer_required_for_any_ena = [[다른 %s개의 %s가 더 이상 활성화된 어떤 모드에도 필요하지 않습니다.
%s도 함께 비활성화하시겠습니까?]],
    mod_is = [[모드가]],
    mods_are = [[모드들이]],
    s_other_s_on_this_mod_ndo_you_want_to_di = [[다른 %s개의 %s가 이 모드에 의존합니다.
%s도 함께 비활성화하시겠습니까?]],
    mod_depends = [[모드가 의존]],
    mods_depend = [[모드들이 의존]],
    delete = [[삭제]],
    keep = [[유지]],
    some_mods_couldn_t_be_loaded_make_sure_t = [[일부 모드를 불러오지 못했습니다. 설치되어 있는지 확인해 주세요:
]],
    something_went_wrong_deleted_preset_s_na = [[문제가 발생했습니다. 삭제된 프리셋의 이름이 비어 있습니다!]],
    something_went_wrong_name_is_nil = [[문제가 발생했습니다. 이름이 비어 있습니다!]],
    preset_name_can_t_be_empty = [[프리셋 이름은 비워 둘 수 없습니다!]],
    this_preset_already_exists_do_you_wish_t = [[이 프리셋은 이미 존재합니다! 덮어쓰시겠습니까?]],
    new_preset_name = [[새 프리셋 이름]],
    replace = [[바꾸기]],
    edit_modpresets_txt = [[modpresets.txt 편집]],
    add_preset = [[프리셋 추가]],
    mod_presets = [[모드 프리셋]],
    enabled = [[활성화됨]],
    update_all = [[모두 업데이트]],
    open_mods_folder = [[모드 폴더 열기]],
    install_mod_file = [[모드 파일 설치]],
    edit_blacklist_txt = [[blacklist.txt 편집]],
    filter_list = [[필터:]],
    all_categories = [[모든 카테고리]],
    no_category = [[카테고리 없음]],
    only_show_enabled = [[활성화된 항목만]],
    only_show_favorites = [[즐겨찾기만]],
    enable_all = [[모두 활성화]],
    disable_all = [[모두 비활성화]],
    search_by_file_name_mod_title_or_everest = [[파일 이름, 모드 제목 또는 everest.yaml ID로 검색]],
    an_error_occurred_while_loading_the_mod_ = [[모드 목록을 불러오는 중 오류가 발생했습니다.]],
    are_you_sure_that_you_want_to_delete = [[정말 삭제하시겠습니까: ]],
    you_will_need_to_redownload_the_mod_to_u = [[?
다시 사용하려면 모드를 다시 다운로드해야 합니다.
팁: 모드를 비활성화하면 Everest가 해당 모드를 불러오지 않으며, 지연을 줄이는 효과는 삭제하는 것과 같습니다.]],
    questionmark = [[?]],

    -- scenes/options.lua
    random_default = [[랜덤 (기본값)]],
    background = [[배경 #]],
    high_default = [[높음 (기본값)]],
    medium = [[중간]],
    low = [[낮음]],
    minimal = [[최소]],
    stable_default = [[안정 (기본값)]],
    development = [[개발]],
    all_mods = [[모든 모드]],
    enabled_mods_only = [[활성화된 모드만]],
    disabled_default = [[비활성화 (기본값)]],
    germany_0x0a_de = [[독일 (0x0a.de)]],
    china_weg_fan = [[중국 (weg.fan)]],
    n_america_celestemods_com = [[북미 (celestemods.com)]],
    _x0a_de_default = [[0x0a.de (기본값)]],
    celestemods_com = [[celestemods.com]],
    disabled = [[비활성화]],
    theme = [[테마]],
    select_your_theme = [[테마 선택]],
    background_image = [[배경 이미지]],
    select_your_background = [[배경 선택]],
    quality = [[품질]],
    gradient = [[그라데이션]],
    enabled_default = [[활성화 (기본값)]],
    parallax = [[패럴랙스]],
    vertical_sync = [[수직 동기화]],
    updates = [[업데이트]],
    update_mods_on_startup = [[시작할 때 모드 업데이트]],
    use_opengl = [[OpenGL 사용]],
    close_after_one_click_install = [[원클릭 설치 후 닫기]],
    open_installation_folder = [[설치 폴더 열기]],
    open_log_and_config_folder = [[로그 및 설정 폴더 열기]],
    mirrors = [[미러]],
    download_mirror = [[다운로드 미러]],
    api_mirror = [[API 미러]],
    image_mirror = [[이미지 미러]],
    this_is_your_current_theme_the_quick_bro = [[현재 사용 중인 테마입니다.
다람쥐 헌 쳇바퀴에 타고파.]],
    this_is_the_new_theme_over_the_lazy_dog = [[새로 적용할 테마입니다.
동녘 구름 틈새로 퍼지는 햇빛.]],
    if_you_have_difficulty_downloading_mods_ = [[모드 다운로드가 어렵거나 Olympus의 일부 항목이 불러와지지 않는다면 다음 설정을 시도해 볼 수 있습니다.
- ]],
    can_help_if_mod_downloads_are_slow_or_ga = [[ 모드 다운로드가 느리거나 GameBanana에 문제가 있을 때 도움이 될 수 있습니다.
- ]],
    can_help_if_the_install_everest_or_downl = [[ "Everest 설치" 또는 "모드 다운로드" 페이지가 열리지 않을 때 도움이 될 수 있습니다. 단, 모드 브라우저가 느려질 수 있습니다!
- ]],
    changes_where_the_mod_images_in_the_mod_ = [[ 모드 브라우저에서 모드 이미지를 불러오는 위치를 변경합니다. 미러를 사용하지 않도록 선택할 수도 있지만, 오래된 모드에는 이미지가 표시되지 않을 수 있습니다.]],
    language = [[언어]],
    restart_to_apply_changes_in_languages = [[언어 변경 사항을 완전히 적용하려면 Olympus를 다시 시작해야 합니다.]],
    note_this_only_covers_olympus_1 = [[참고: ]],
    note_this_only_covers_olympus_2 = [[이 항목은 Olympus 업데이트에만 적용됩니다. Everest와 Lönn을 업데이트하려면 메인 메뉴의]],
    note_this_only_covers_olympus_3 = [[버튼을 사용하세요.]],
    theme_dark = [[어두운 테마 (기본값)]],
    theme_light = [[밝은 테마]],

    -- C# stuff (Cmds.Download / CmdUpdateAllMods)
    csharp_downloadinglist = [[모드 버전 목록 다운로드 중]],
    csharp_downloadingfile = [[다운로드 중]],
    csharp_downloadingprogress = [[다운로드 중:]],
    csharp_checking = [[오래된 모드 확인 중]],
    csharp_updating = [[업데이트 중]],
    csharp_installing = [[업데이트 설치 중]],
    csharp_finished_noop = [[업데이트 확인이 완료되었습니다.
업데이트를 찾지 못했습니다.]],
    csharp_finished = [[업데이트에 성공했습니다!
다음 모드가 업데이트되었습니다:]],
    csharp_checksum = [[체크섬 확인 중]],
    csharp_unzipping = [[압축 해제 중]],
    csharp_unzipping_files = [[파일 {0}개 압축 해제 중]],
    csharp_unzipped_files = [[파일 {0}개 압축 해제 완료]],
    csharp_downloaded = [[{1}초 동안 {0}바이트를 다운로드했습니다.]],
}

return {
    cjk_priority = cjk_priority,
    keys = keys
}
