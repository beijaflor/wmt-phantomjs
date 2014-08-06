page = require('webpage').create()
fs   = require('fs')
sys  = require('system')

# VARIABLES path
path2bowerComponent = 'bower_components/'
path2jQuery =  path2bowerComponent + 'jquery/dist/jquery.min.js'
path2log = 'log/'

# VARIABLES setting
setting = require './setting'

d = new Date()

SITE = "https://www.google.com/webmasters/tools/"
CC   = "hl=ja"
ACCOUNT = setting.account
PASSWD  = setting.passwd
DATE_BEGIN  = 'db=' + setting.date_begin
DATE_END    = 'de=' + setting.date_end
TODAY       = [d.getFullYear(), d.getMonth()+1, d.getDate()].join '-'
RENDER_MODE = setting.render_mode

args = sys.args
if args.length < 3
	console.log("should given 2 args")
	phantom.exit(1)

URL  = "siteUrl=" + args[1]
NAME = args[2]

# show STATUS
console.log TODAY
console.log "get informations as "+NAME+":"+URL
console.log ACCOUNT
console.log DATE_BEGIN + ' - ' + DATE_END
console.log 'render_mode: ' + RENDER_MODE

# INITIALIZE
phantom.out_json = {}
phantom.out_src = ''
phantom.out_json.site = NAME

phantom.timerID = []

page.onInitialized = () ->
	page.evaluate () ->
		document.addEventListener 'DOMContentLoaded', () ->
			window.callPhantom('DOMContentLoaded')
			return
		, false
	return

funcs = (funcs) ->
	this.funcs = funcs
	this.init()
	return

funcs.prototype =
	init: () ->
		self = this
		page.onCallback = (data) ->
			if data is 'DOMContentLoaded'
				self.next()
			return
		return
	next: () ->
		func = this.funcs.shift()
		if func isnt undefined
			func()
		else
			page.onCallback = () ->
				return
		return

waitUntil = (fn, options, callback) ->

	options = options || {}
	retry = options["retry"] || 10
	wait = options["wait"] || 1

	result = fn()
	if result
		for id in phantom.timerID
			clearTimeout(id)
		phantom.timerID = []
		callback();
	else
		phantom.timerID.push(setTimeout () ->
			options["retry"] = --retry
			if options["retry"] is 0
				die "retry over"
			else
				waitUntil(fn, options, callback)
			return
		, wait * 1000)
	return

renderTo = (fn) ->
	path = path2log + NAME + '-' + fn
	if RENDER_MODE
		page.render(path)
	return

die = (m) ->
	page.render path2log + "error_shot.png"
	console.warn m
	console.log JSON.stringify(phantom.out_json)
	console.log phantom.out_src
	phantom.exit(1)

finish = () ->
	out_json_file = path2log + NAME + '_' + TODAY + '.json'
	fs.write(out_json_file, JSON.stringify(phantom.out_json), 'w');

	out_src_file = path2log + NAME + '_' + TODAY + '.txt'
	fs.write(out_src_file, phantom.out_src, 'w');

	phantom.exit()

# utilities 
util = {}

util.getLoc = () ->
	page.evaluate () ->
		return window.location.toString()

new funcs([
	() ->
		console.log('スタート')
		page.open('https://accounts.google.com/ServiceLogin')
		return

	() ->
		console.log('ログイン画面')
		waitUntil( () ->
			return page.evaluate () ->
				return !!document.querySelector("#gaia_loginform")
		, {}, () ->
			page.evaluate () ->
				document.getElementById("Email").value = "webmasters@nttr.co.jp"
				document.getElementById("Passwd").value = "CFVxxURbnwrb"
				return
			renderTo('login.png')
			page.evaluate () ->
				document.getElementById("gaia_loginform").submit()
				return
			return
		)
		return

	() ->
		console.log('ログイン中')
		renderTo('logging.png')
		page.open SITE + 'structured-data?' + CC + '&' + URL
		return

	() ->
		console.log('構造化データ取得')
		nextPage = SITE + 'top-search-queries?' + CC + '&' + URL + '&prep=WEB&regien&' + DATE_BEGIN + '&' + DATE_END + '&more=ture&grid.r=1&grid.s=20'

		waitUntil( () ->
			return page.evaluate () ->
				return !!document.querySelector("#structured-data-summary-tablePanel table") || !!document.querySelector(".alert-widget")
		,{} , () ->
			page.injectJs path2jQuery
			console.log page.evaluate () ->
				if $("#structured-data-summary-tablePanel table").length < 1
					return '：構造化データ無し'
				else
					return ''
			phantom.out_src += util.getLoc()
			phantom.out_src += '\n-----\n'
			phantom.out_src += page.evaluate () ->
				return $("#structured-data-summary-tablePanel table").html()
			phantom.out_src += '\n-----\n'
			phantom.out_json.stdata_item = page.evaluate () ->
				return $(".GOJ0WDDBMB").eq(0).text()
			phantom.out_json.stdata_item_err = page.evaluate () ->
				return $(".GOJ0WDDBBC").eq(0).text()
			phantom.out_json.stdata_page = page.evaluate () ->
				return $(".GOJ0WDDBMB").eq(1).text()
			phantom.out_json.stdata_page_err = page.evaluate () ->
				return $(".GOJ0WDDBBC").eq(1).text()

			console.log JSON.stringify(phantom.out_json)
			renderTo('structure-data.png')
			page.open nextPage
			return
		)
		return


	() ->
		console.log('検索クエリデータ取得')
		nextPage = SITE + 'html-suggestions?' + CC + '&' + URL

		waitUntil( () ->
			return page.evaluate () ->
				return !!document.querySelector(".showing-amount")
		,{} , () ->
			page.injectJs path2jQuery
			phantom.out_src += util.getLoc()
			phantom.out_src += '¥n-----¥n'
			phantom.out_src += page.evaluate () ->
				return $(".showing-amount table").html()
			phantom.out_src += '¥n-----¥n'
			phantom.out_src += page.evaluate () ->
				return $(".properties-table").html()
			phantom.out_src += '¥n-----¥n'
			phantom.out_json.query_num = page.evaluate () ->
				return $("table.properties-table td.property .primary").eq(0).text()
			phantom.out_json.display_num = page.evaluate () ->
				return $("table.properties-table td.property .primary").eq(1).text()
			phantom.out_json.click_num = page.evaluate () ->
				return $("table.properties-table td.property .primary").eq(2).text()

			console.log JSON.stringify(phantom.out_json)
			renderTo('search-query.png')
			page.open nextPage
			return
		)
		return

	() ->
		console.log('htmlの改善取得')
		nextPage = SITE + 'external-links?' + CC + '&' + URL

		waitUntil( () ->
			return page.evaluate () ->
				return !!document.querySelector(".timestamp") || !!document.querySelector(".empty-mini")
		,{} , () ->
			page.injectJs path2jQuery
			phantom.out_src += util.getLoc()
			phantom.out_src += '\n-----\n'
			phantom.out_src += page.evaluate () ->
				return $(".g-section").html()
			phantom.out_src += '\n-----\n'
			phantom.out_json.desc_multi = page.evaluate () ->
				return $("table.content-problems td.pages").eq(0).text()
			phantom.out_json.desc_long = page.evaluate () ->
				return $("table.content-problems td.pages").eq(1).text()
			phantom.out_json.desc_short = page.evaluate () ->
				return $("table.content-problems td.pages").eq(2).text()
			phantom.out_json.title_no = page.evaluate () ->
				return $("table.content-problems td.pages").eq(3).text()
			phantom.out_json.title_multi = page.evaluate () ->
				return $("table.content-problems td.pages").eq(4).text()
			phantom.out_json.title_long = page.evaluate () ->
				return $("table.content-problems td.pages").eq(5).text()
			phantom.out_json.title_short = page.evaluate () ->
				return $("table.content-problems td.pages").eq(6).text()
			phantom.out_json.title_lack = page.evaluate () ->
				return $("table.content-problems td.pages").eq(7).text()

			console.log JSON.stringify(phantom.out_json)
			renderTo('html-error.png')
			page.open nextPage
			return
		)
		return

	() ->
		console.log('サイトへのリンク取得')
		nextPage = SITE + 'crawl-errors?' + CC + '&' + URL

		waitUntil( () ->
			return page.evaluate () ->
				return !!document.querySelector("#backlinks-dashboard") || !!document.querySelector(".empty-mini")
		,{} , () ->
			page.injectJs path2jQuery
			phantom.out_src += util.getLoc()
			phantom.out_src += '\n-----\n'
			phantom.out_src += page.evaluate () ->
				return $("#backlinks-dashboard").html()
			phantom.out_src += '\n-----\n'
			phantom.out_json.backlinks = page.evaluate () ->
				return $(".primary").eq(0).text()

			console.log JSON.stringify(phantom.out_json)
			renderTo('sitelink.png')
			page.open nextPage
			return
		)
		return

	() ->
		console.log('クロールエラー取得')
		nextPage = SITE + 'index-status?' + CC + '&' + URL + '&is-view=a&is-indx=true&is-rbt=true'

		waitUntil( () ->
			return page.evaluate () ->
				return !!document.querySelector(".wmxCardTabBar") || !!document.querySelector("#wmx_gwt_feature_CRAWL_ERRORS .gwt-InlineLabel")
		,{} , () ->
			page.injectJs path2jQuery
			phantom.out_src += util.getLoc()
			phantom.out_src += '¥n-----¥n'
			phantom.out_src += page.evaluate () ->
				return $(".gwt-TabPanel").html()
			phantom.out_src += '¥n-----¥n'
			phantom.out_json.err_1l = page.evaluate () ->
				return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(0).text()
			phantom.out_json.err_1d = page.evaluate () ->
				return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(1).text()
			phantom.out_json.err_2l = page.evaluate () ->
				return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(3).text()
			phantom.out_json.err_2d = page.evaluate () ->
				return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(4).text()
			phantom.out_json.err_3l = page.evaluate () ->
				return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(6).text()
			phantom.out_json.err_3d = page.evaluate () ->
				return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(7).text()
			phantom.out_json.err_4l = page.evaluate () ->
				return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(9).text()
			phantom.out_json.err_4d = page.evaluate () ->
				return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(10).text()
			phantom.out_json.err_5l = page.evaluate () ->
				return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(12).text()
			phantom.out_json.err_5d = page.evaluate () ->
				return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(13).text()
			phantom.out_json.err_6l = page.evaluate () ->
				return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(15).text()
			phantom.out_json.err_6d = page.evaluate () ->
				return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(16).text()
			phantom.out_json.err_7l = page.evaluate () ->
				return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(18).text()
			phantom.out_json.err_7d = page.evaluate () ->
				return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(19).text()
			phantom.out_json.err_8l = page.evaluate () ->
				return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(21).text()
			phantom.out_json.err_8d = page.evaluate () ->
				return $(".gwt-TabPanel .wmxCardTabBar").eq(0).find(".gwt-Label").eq(22).text()

			console.log JSON.stringify(phantom.out_json)
			renderTo('crowl-error.png')
			page.open nextPage
			return
		)
		return
	() ->
		console.log('インデックスステータス取得')
		nextPage = SITE + 'crawl-stats?' + CC + '&' + URL

		waitUntil( () ->
			return page.evaluate () ->
				return !!document.querySelector("#index-status-chart-legend")
		,{} , () ->
			page.injectJs path2jQuery
			phantom.out_src += util.getLoc()
			phantom.out_src += '\n-----\n'
			phantom.out_src += page.evaluate () ->
				return $("#index-status-chart-legend").html()
			phantom.out_src += '\n-----\n'
			phantom.out_json.page_indexed = page.evaluate () ->
				return $("#index-status-chart-legend .primary").eq(0).text()
			phantom.out_json.page_blocked = page.evaluate () ->
				return $("#index-status-chart-legend .primary").eq(1).text()

			console.log JSON.stringify(phantom.out_json)
			renderTo('index-status.png')
			page.open nextPage
			return
		)
		return

	() ->
		console.log('クロール統計取得')
		nextPage = SITE + 'sitemap-list?' + CC + '&' + URL + '#MAIN_TAB=1&CARD_TAB=1'

		waitUntil( () ->
			return page.evaluate () ->
				return !!document.querySelector("#crawlstats")
		,{} , () ->
			page.injectJs path2jQuery
			phantom.out_src += util.getLoc()
			phantom.out_src += '\n-----\n'
			phantom.out_src += page.evaluate () ->
				return $("#crawlstats").html()
			phantom.out_src += '\n-----\n'
			phantom.out_json.crawled_pages = page.evaluate () ->
				return $("tr.chartdata td").eq(1).text()
			phantom.out_json.crawled_kbytes = page.evaluate () ->
				return $("tr.chartdata td").eq(4).text()
			phantom.out_json.crawling_time = page.evaluate () ->
				return $("tr.chartdata td").eq(7).text()

			console.log JSON.stringify(phantom.out_json)
			renderTo('crawlstats.png')
			page.open nextPage
			return
		)
		return

	() ->
		console.log('サイトマップ取得')

		waitUntil( () ->
			return page.evaluate () ->
				return !!document.querySelector("table.wmxCardTabBar") || !!document.querySelector(".gwt-Label")
		,{} , () ->
			page.injectJs path2jQuery
			phantom.out_src += util.getLoc()
			phantom.out_src += '\n-----\n'
			phantom.out_src += page.evaluate () ->
				return $("table.wmxCardTabBar").html()
			phantom.out_src += '\n-----\n'
			phantom.out_src += page.evaluate () ->
				return $(".GOJ0WDDBPNB").html()
			phantom.out_src += '\n-----\n'
			phantom.out_json.sitemap_sent = page.evaluate () ->
				return $(".wmxCard .GG2CFPACMB").eq(2).text()
			phantom.out_json.sitemap_indexed = page.evaluate () ->
				return $(".wmxCard .GG2CFPACMB").eq(3).text()
			phantom.out_json.sitemap_num = page.evaluate () ->
				return $(".GG2CFPACHLB .GG2CFPACHLB").eq(0).text()

			console.log JSON.stringify(phantom.out_json)
			renderTo('sitemaps.png')

			finish()
			return
		)
		return

])
.next()
