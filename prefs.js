// 设置中文语言
user_pref("intl.accept_languages", "zh-CN, zh, en-US, en");
user_pref("intl.locale.requested", "zh-CN");
user_pref("general.useragent.locale", "zh-CN");

// 设置主页
user_pref("browser.startup.homepage", "https://nav.eooce.com");
user_pref("browser.startup.page", 2); // 启动时显示用户配置的页面

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
