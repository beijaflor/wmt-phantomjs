# Require
casper = require('casper')
fs = require('fs')

# VARIABLES path
path2bowerComponent = 'bower_components/'
path2jQuery =  path2bowerComponent + 'jquery/dist/jquery.min.js'
path2log = 'log/'

# Create Casper
casper = casper.create({
	clientScripts: [path2jQuery]
})

# Load setting
setting = require './setting'

# VARIABLES today
d = new Date()

# VARIABLES site
SITE = "https://www.google.com/webmasters/tools/"
CC   = "hl=en"
ACCOUNT = setting.account
PASSWD  = setting.passwd
DATE_BEGIN  = 'db=' + setting.date_begin
DATE_END    = 'de=' + setting.date_end
TODAY       = [d.getFullYear(), d.getMonth()+1, d.getDate()].join '-'
RENDER_MODE = setting.render_mode
UA          = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.124 Safari/537.36"

# VARIABLES from arguments
URL  = "siteUrl=" + casper.cli.get(0)
NAME = casper.cli.get(1)

# OUTPUTS
out_json = {}
out_src = ''
out_json.site = NAME

# show STATUS
console.log TODAY
console.log "get informations as "+NAME+":"+URL
console.log ACCOUNT
console.log DATE_BEGIN + ' - ' + DATE_END
console.log 'render_mode: ' + RENDER_MODE

# functions
render = (fn) ->
	path = path2log + NAME + '-' + fn
	if RENDER_MODE
		this.capture(path)
#		console.log this.evaluate () ->
#			document.getElementsByTagName('html')[0].innerHTML;
	return

casper.start()

casper.userAgent UA

casper.thenOpen "https://accounts.google.com/ServiceLogin?#{CC}", () ->
	console.log('スタート')
	render.bind(this)("before-login.png")
	this.fill('form#gaia_loginform', { Email: ACCOUNT }, false);

	this.evaluate () ->
		$("#next").click()
		return

casper.waitFor () ->
	return this.evaluate () ->
		return $("#next")

casper.then () ->
	render.bind(this)("middle-login.png")
	this.fill('form#gaia_loginform', { Passwd: PASSWD }, false);

	render.bind(this)("test.png")

	this.evaluate () ->
		document.getElementById("gaia_loginform").submit()
		return

# login
casper.waitFor () ->
	url = this.getCurrentUrl()
	return url.match(/https:\/\/www\.google\.com\/settings\/general-light/) != null || url.match(/https:\/\/myaccount\.google\.com\//) != null

casper.then () ->
	console.log('ログイン完了')
	render.bind(this)("logging.png")

# structure data
casper.thenOpen SITE + 'structured-data?' + CC + '&' + URL

casper.waitFor () ->
	return this.evaluate () ->
		return !!document.querySelector("#structured-data-summary-tablePanel table") || !!document.querySelector(".alert-widget")

casper.then () ->
	console.log('構造化データ')
	render.bind(this)("structured-data.png")

	console.log this.evaluate () ->
		if $("#structured-data-summary-tablePanel table").length < 1
			return '：構造化データ無し'
		else
			return ''
	out_src += this.getCurrentUrl()
	out_src += '\n-----\n'
	out_src += this.evaluate () ->
		return $("#structured-data-summary-tablePanel table").html()
	out_src += '\n-----\n'
	out_json.stdata_item = this.evaluate () ->
		return $(".GG2CFPACFKB .wmt-legend-count").eq(0).text()
	out_json.stdata_item_err = this.evaluate () ->
		return $(".GG2CFPACFKB .wmt-legend-sub-text").eq(1).text()
	out_json.stdata_page = this.evaluate () ->
		return $(".GG2CFPACFKB .wmt-legend-count").eq(0).text()
	out_json.stdata_page_err = this.evaluate () ->
		return $(".GG2CFPACFKB .wmt-legend-sub-text").eq(1).text()

	console.log JSON.stringify(out_json)

# query data
casper.thenOpen "#{SITE}top-search-queries?#{CC}&#{URL}&prep=WEB&regien&#{DATE_BEGIN}&#{DATE_END}&more=ture&grid.r=1&grid.s=20"

casper.waitFor () ->
	return this.evaluate () ->
		return !!document.querySelector(".showing-amount")

casper.then () ->
	console.log('検索クエリデータ取得')
	render.bind(this)("search-query.png")

	out_src += this.getCurrentUrl()
	out_src += '\n-----\n'
	out_src += this.evaluate () ->
		return $(".showing-amount table").html()
	out_src += '\n-----\n'
	out_src += this.evaluate () ->
		return $(".properties-table").html()
	out_src += '\n-----\n'
	out_json.query_num = this.evaluate () ->
		return $("table.properties-table td.property .primary").eq(0).text()
	out_json.display_num = this.evaluate () ->
		return $("table.properties-table td.property .primary").eq(1).find("span.count").text()
	out_json.click_num = this.evaluate () ->
		return $("table.properties-table td.property .primary").eq(2).find("span.count").text()

	console.log JSON.stringify(out_json)

# suggestions
casper.thenOpen "#{SITE}html-suggestions?#{CC}&#{URL}"

casper.waitFor () ->
	return this.evaluate () ->
		return !!document.querySelector(".timestamp") || !!document.querySelector(".empty-mini")

casper.then () ->
	console.log('htmlの改善取得')
	render.bind(this)("html-error.png")

	out_src += this.getCurrentUrl()
	out_src += '\n-----\n'
	out_src += this.evaluate () ->
		return $(".g-section").html()
	out_src += '\n-----\n'
	out_json.desc_multi = this.evaluate () ->
		return $("table.content-problems td.pages").eq(0).text()
	out_json.desc_long = this.evaluate () ->
		return $("table.content-problems td.pages").eq(1).text()
	out_json.desc_short = this.evaluate () ->
		return $("table.content-problems td.pages").eq(2).text()
	out_json.title_no = this.evaluate () ->
		return $("table.content-problems td.pages").eq(3).text()
	out_json.title_multi = this.evaluate () ->
		return $("table.content-problems td.pages").eq(4).text()
	out_json.title_long = this.evaluate () ->
		return $("table.content-problems td.pages").eq(5).text()
	out_json.title_short = this.evaluate () ->
		return $("table.content-problems td.pages").eq(6).text()
	out_json.title_lack = this.evaluate () ->
		return $("table.content-problems td.pages").eq(7).text()

	console.log JSON.stringify(out_json)

# external links
casper.thenOpen "#{SITE}external-links?#{CC}&#{URL}"

casper.waitFor () ->
	return this.evaluate () ->
		return !!document.querySelector("#backlinks-dashboard") || !!document.querySelector(".empty-mini")

casper.then () ->
	console.log('サイトへのリンク取得')
	render.bind(this)('sitelink.png')

	out_src += this.getCurrentUrl()
	out_src += '\n-----\n'
	out_src += this.evaluate () ->
		return $("#backlinks-dashboard").html()
	out_src += '\n-----\n'
	out_json.backlinks = this.evaluate () ->
		return $(".primary").eq(0).text()

	console.log JSON.stringify(out_json)

# crawl errors
casper.thenOpen "#{SITE}crawl-errors?#{CC}&#{URL}"

casper.waitFor () ->
	return this.evaluate () ->
		return !!document.querySelector(".wmxCardTabBar") || !!document.querySelector("#wmx_gwt_feature_CRAWL_ERRORS .gwt-InlineLabel")

casper.then () ->
	console.log('クロールエラー取得')
	render.bind(this)('crowl-error.png')

	out_src += this.getCurrentUrl()
	out_src += '\n-----\n'
	out_src += this.evaluate () ->
		return $(".gwt-TabPanel").html()
	out_src += '\n-----\n'
	out_json.err_1l = this.evaluate () ->
		return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(0).text()
	out_json.err_1d = this.evaluate () ->
		return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(1).text()
	out_json.err_2l = this.evaluate () ->
		return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(3).text()
	out_json.err_2d = this.evaluate () ->
		return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(4).text()
	out_json.err_3l = this.evaluate () ->
		return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(6).text()
	out_json.err_3d = this.evaluate () ->
		return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(7).text()
	out_json.err_4l = this.evaluate () ->
		return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(9).text()
	out_json.err_4d = this.evaluate () ->
		return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(10).text()
	out_json.err_5l = this.evaluate () ->
		return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(12).text()
	out_json.err_5d = this.evaluate () ->
		return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(13).text()
	out_json.err_6l = this.evaluate () ->
		return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(15).text()
	out_json.err_6d = this.evaluate () ->
		return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(16).text()
	out_json.err_7l = this.evaluate () ->
		return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(18).text()
	out_json.err_7d = this.evaluate () ->
		return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(19).text()
	out_json.err_8l = this.evaluate () ->
		return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(21).text()
	out_json.err_8d = this.evaluate () ->
		return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(22).text()

	console.log JSON.stringify(out_json)

# crawl errors
casper.thenOpen "#{SITE}index-status?#{CC}&#{URL}&is-view=a&is-indx=true&is-rbt=true"

casper.waitFor () ->
	return this.evaluate () ->
		return !!document.querySelector("#index-status-chart-legend")

casper.then () ->
	console.log('インデックスステータス取得')
	render.bind(this)('index-status.png')

	out_src += this.getCurrentUrl()
	out_src += '\n-----\n'
	out_src += this.evaluate () ->
		return $("#index-status-chart-legend").html()
	out_src += '\n-----\n'
	out_json.page_indexed = this.evaluate () ->
		return $("#index-status-chart-legend .primary").eq(0).text()
	out_json.page_blocked = this.evaluate () ->
		return $("#index-status-chart-legend .primary").eq(1).text()

	console.log JSON.stringify(out_json)

# crawl errors
casper.thenOpen "#{SITE}crawl-stats?#{CC}&#{URL}"

casper.waitFor () ->
	return this.evaluate () ->
		return !!document.querySelector("#crawlstats")

casper.then () ->
	console.log('クロール統計取得')
	render.bind(this)('crawlstats.png')

	out_src += this.getCurrentUrl()
	out_src += '\n-----\n'
	out_src += this.evaluate () ->
		return $("#crawlstats").html()
	out_src += '\n-----\n'
	out_json.crawled_pages = this.evaluate () ->
		return $("tr.chartdata td").eq(1).text()
	out_json.crawled_kbytes = this.evaluate () ->
		return $("tr.chartdata td").eq(4).text()
	out_json.crawling_time = this.evaluate () ->
		return $("tr.chartdata td").eq(7).text()

	console.log JSON.stringify(out_json)

# site-map
casper.thenOpen "#{SITE}sitemap-list?#{CC}&#{URL}#MAIN_TAB=1&CARD_TAB=1"

casper.waitFor () ->
	return this.evaluate () ->
		return !!document.querySelector("table.wmxCardTabBar") || !!document.querySelector(".gwt-Label")

casper.then () ->
	console.log('サイトマップ取得')
	render.bind(this)('sitemaps.png')

	out_src += this.getCurrentUrl()
	out_src += '\n-----\n'
	out_src += this.evaluate () ->
		return $("table.wmxCardTabBar").html()
	out_src += '\n-----\n'
	out_src += this.evaluate () ->
		return $(".GOJ0WDDBPNB").html()
	out_src += '\n-----\n'
	out_json.sitemap_sent = this.evaluate () ->
		return $(".wmxCardTabBar .wmt-legend-count").eq(2).text()
	out_json.sitemap_indexed = this.evaluate () ->
		return $(".wmxCardTabBar .wmt-legend-count").eq(3).text()
	out_json.sitemap_num = this.evaluate () ->
		return $(".GG2CFPACHLB .GG2CFPACHLB").eq(0).text()

	console.log JSON.stringify(out_json)

# finish
casper.then () ->
	out_json_file = path2log + NAME + '_' + TODAY + '.json'
	fs.write(out_json_file, JSON.stringify(out_json), 'w');
	out_src_file = path2log + NAME + '_' + TODAY + '.txt'
	fs.write(out_src_file, out_src, 'w');

	casper.exit()

# start casper
casper.run()
