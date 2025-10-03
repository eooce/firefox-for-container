// 设置中文语言
user_pref("intl.accept_languages", "zh-CN, zh, en-US, en");
user_pref("intl.locale.requested", "zh-CN");
user_pref("general.useragent.locale", "zh-CN");

// 设置主页
user_pref("browser.startup.homepage", "https://nav.eooce.com");
user_pref("browser.startup.page", 1); // 启动时显示主页

// 会话恢复设置 - 浏览器崩溃后自动恢复之前的页面
user_pref("browser.sessionstore.resume_from_crash", true);
user_pref("browser.sessionstore.restore_on_demand", false);
user_pref("browser.sessionstore.restore_tabs_lazily", false);
user_pref("browser.sessionstore.resume_session_once", true);
user_pref("browser.sessionstore.max_resumed_crashes", -1);
user_pref("browser.sessionstore.max_tabs_undo", 10);
user_pref("browser.sessionstore.interval", 300000); // 每5分钟保存一次会话

// 崩溃恢复设置
user_pref("browser.crashReports.unsubmittedCheck.autoSubmit2", true);
user_pref("browser.tabs.crashReporting.sendReport", true);

// 禁用安全警告
user_pref("browser.aboutConfig.showWarning", false);
user_pref("browser.shell.checkDefaultBrowser", false);

// 禁用更新
user_pref("app.update.auto", false);
user_pref("app.update.enabled", false);
user_pref("app.update.silent", false);

// 优化性能
user_pref("gfx.webrender.all", true);
user_pref("layers.acceleration.force-enabled", true);

// 禁用各种提示
user_pref("browser.tabs.warnOnClose", false);
user_pref("browser.tabs.warnOnOpen", false);
user_pref("browser.privatebrowsing.autostart", true);

// 自动恢复上次会话
user_pref("browser.startup.page", 3); // 0=空白页, 1=主页, 2=恢复上次会话, 3=恢复上次会话(如果崩溃)
user_pref("browser.sessionstore.restore_pinned_tabs_on_demand", false);
