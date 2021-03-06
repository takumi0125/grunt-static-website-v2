'use strict'

SRC_DIR = './src'
PUBLISH_DIR = '../htdocs'
DATA_JSON = "_data.json"

ASSETS_DIR = '/assets'

paths =
  html: '**/*.html'
  jade: '**/*.jade'
  css: '**/*.css'
  sass: '**/*.{sass,scss}'
  js: '**/*.js'
  json: '**/*.json'
  coffee: '**/*.coffee'
  img: '**/img/**'
  others: [
    '**'
    '!**/*.{html,jade,css,sass,scss,js,json,coffee,md}'
    '!**/img/**'
    '!**/.git/**'
    '!**/.gitkeep'
    '!**/_*/**'
    '!**/_*'
  ]
  jadeInclude  : '**/_*.jade'
  sassInclude  : '**/_*.{sass,scss}'
  coffeeInclude: '**/_*.{coffee}'

#
# Grunt 主要設定
# --------------
module.exports = (grunt) ->
  # 頭に SRC_DIR/ をつけて返す
  addSrcPath = (path)->
    if path instanceof Array
      path.map (p)-> "#{SRC_DIR}/#{p}"
    else
      "#{SRC_DIR}/#{path}"


  #「_」が先頭のファイル、ディレクトリを除外するように src 用の配列を生成
  createSrcArr = (name) -> [].concat paths[name], '!**/_*/**', '!**/_*'

  #
  # spritesmith のタスクを生成
  #
  # @param {string} taskName       タスクを識別するための名前 スプライトタスクが複数ある場合はユニークにする
  # @param {string} imgDir         画像ディレクトリへのパス
  # @param {string} cssDir         CSSディレクトリへのパス
  # @param {string} outputImgPath  CSSに記述される画像パス
  #
  # #{SRC_DIR}#{imgDir}/_#{taskName}/
  # 以下にソース画像を格納しておくと
  # #{SRC_DIR}#{cssDir}/_#{taskName}.scss と
  # #{SRC_DIR}#{imgDir}/#{taskName}.png が生成される
  # かつ watch タスクの監視も追加
  #
  #
  # CSS スプライト作成タスク
  #
  # * [grunt-spritesmith](https://github.com/Ensighten/grunt-spritesmith)
  #
  createSpritesTask = (taskName, imgDir, cssDir, outputImgPath = '') ->
    if !conf.hasOwnProperty('sprite') then conf.sprite = {}

    srcImgFiles = "#{SRC_DIR}#{imgDir}/_#{taskName}/*"
    conf.sprite[taskName] =
      src:   [ srcImgFiles ]
      dest: "#{SRC_DIR}#{imgDir}/#{taskName}.png"
      destCss: "#{SRC_DIR}#{cssDir}/_#{taskName}.scss"
      algorithm: 'binary-tree'
      padding: 2

    if outputImgPath then conf.sprite[taskName].imgPath = outputImgPath

    if conf.watch.hasOwnProperty('sprite')
      conf.watch.sprite.files.push srcImgFiles
    else
      conf.watch.sprite =
        files: [ srcImgFiles ]
        tasks: [
          "sprite:#{taskName}"
          'notify:build'
        ]

    conf.watch.img.files.push "!#{srcImgFiles}"


  #
  # Grunt 初期設定オブジェクト (`grunt.initConfig()` の引数として渡す用)
  #
  conf =

    # 各種パス設定 (`<%= path.PROP %>` として読込)
    path:
      source: './src'
      publish: '../htdocs'


    ################
    ###   init   ###
    ################

    #
    # Bowerによるライブラリインストールタスク
    #
    # * [grunt-bower-task](https://github.com/yatskevich/grunt-bower-task)
    #
    bower:
      source:
        options:
          targetDir: "#{SRC_DIR}#{ASSETS_DIR}"
          layout: (type, component, source)->
            if source.match /(.*)\.css/ then return 'css/lib'
            if source.match /(.*)\.js/ then return 'js/lib'
          install: true
          verbose: true
          cleanTargetDir: false
          cleanBowerDir: false


    ################
    ###   html   ###
    ################

    #
    # Jade コンパイルタスク
    #
    # * [grunt-contrib-jade](https://github.com/gruntjs/grunt-contrib-jade)
    #
    jade:
      options:
        pretty: true
        basedir: SRC_DIR
        data: ->
          return grunt.file.readJSON addSrcPath DATA_JSON
      source:
        expand: true
        cwd: SRC_DIR
        src: createSrcArr 'jade'
        filter: 'isFile'
        dest: PUBLISH_DIR
        ext: '.html'


    ###############
    ###   css   ###
    ###############

    #
    # Sass/SCSS コンパイルタスク
    #
    # * [grunt-contrib-sass](https://github.com/gruntjs/grunt-contrib-sass)
    #
    sass:
      options:
        unixNewlines: true
        sourcemap: 'none'
        style: 'expanded'
      source:
        expand: true
        cwd: SRC_DIR
        src: createSrcArr 'sass'
        filter: 'isFile'
        dest: PUBLISH_DIR
        ext: '.css'

    #
    # autoprefixer タスク
    #
    # * [grunt-autoprefixer](https://github.com/nDmitry/grunt-autoprefixer)
    #
    autoprefixer:
      options:
        browsers: [ 'last 2 versions', 'ie 8', 'ie 9', 'Android 4', 'iOS 7' ]
      source:
        expand: true
        cwd: '<%= path.publish %>'
        src: '**/!(_)*.css'
        filter: 'isFile'
        dest: '<%= path.publish %>'
        ext: '.css'


    ##############
    ###   js   ###
    ##############

    #
    # CoffeeScript 静的解析タスク
    #
    # * [grunt-coffeelint](https://github.com/vojtajina/grunt-coffeelint)
    # * [CoffeeLint options](http://www.coffeelint.org/#options)
    #
    coffeelint:
      general:
        expand: true
        cwd: SRC_DIR
        src: paths.coffee
        filter: 'isFile'

    #
    # CoffeeScript コンパイルタスク
    #
    # * [grunt-contrib-coffee](https://github.com/gruntjs/grunt-contrib-coffee)
    #
    coffee:
      options:
        bare: false
        sourceMap: false
      general:
        expand: true
        cwd: SRC_DIR
        src: createSrcArr 'coffee'
        filter: 'isFile'
        dest: PUBLISH_DIR
        ext: '.js'


    #
    # JSHint による JavaScript 静的解析タスク
    #
    # * [grunt-contrib-jshint](https://github.com/gruntjs/grunt-contrib-jshint)
    #
    jshint:
      source:
        expand: true
        cwd: SRC_DIR
        src: [
          paths.js
          '!**/lib/**/*.js' #ライブラリは除外
        ]
        filter: 'isFile'


    ################
    ###   json   ###
    ################

    #
    # JSON 静的解析タスク
    #
    # * [grunt-jsonlint](https://github.com/brandonramirez/grunt-jsonlint)
    #
    jsonlint:
      source:
        expand: true
        cwd: SRC_DIR
        src: paths.json
        filter: 'isFile'


    #################
    ###   clean   ###
    #################

    #
    # ファイルとディレクトリ削除タスク
    #
    # * [grunt-contrib-clean](https://github.com/gruntjs/grunt-contrib-clean)
    #
    clean:
      options:
        force: true
      general:
        src: PUBLISH_DIR


    ###################
    ###   connect   ###
    ###################

    #
    # ローカルサーバー (Connect) と LiveReload タスク
    #
    # * [grunt-contrib-connect](https://github.com/gruntjs/grunt-contrib-connect)
    # * [grunt-contrib-livereload](https://github.com/gruntjs/grunt-contrib-livereload)
    #
    connect:
      publish:
        options:
          port: 50000
          hostname: '*'
          base: [ PUBLISH_DIR ]
          livereload: true
          middleware: (conn, opt)->
            fs = require 'fs'
            url = require 'url'
            ssi = require 'ssi'

            middlewares = []
            middlewares.push (req, res, next) ->
              urlobj = url.parse req.originalUrl
              filename = PUBLISH_DIR + urlobj.pathname + if urlobj.pathname.substr(-1) is '/' then 'index.html' else ''

              if fs.existsSync(filename) and filename.match(/\.s?html$/)
                parser = new ssi(PUBLISH_DIR, '', '')
                content = parser.parse(filename, fs.readFileSync(filename, {encoding: 'utf8'})).contents

                res.writeHead 200,
                  'Content-Type': 'text/html'
                  'Content-Length': Buffer.byteLength content, 'utf8'
                res.end content
              else
                next()

            middlewares.push conn.static(PUBLISH_DIR)

            middlewares


    ################
    ###   copy   ###
    ################

    #
    # ファイルコピータスク
    #
    # * [grunt-contrib-copy](https://github.com/gruntjs/grunt-contrib-copy)
    #
    copy:
      html:
        expand: true
        cwd: SRC_DIR
        src: createSrcArr 'html'
        filter: 'isFile'
        dest: PUBLISH_DIR

      css:
        expand: true
        cwd: SRC_DIR
        src: createSrcArr 'css'
        filter: 'isFile'
        dest: PUBLISH_DIR

      js:
        expand: true
        cwd: SRC_DIR
        src: createSrcArr 'js'
        filter: 'isFile'
        dest: PUBLISH_DIR

      json:
        expand: true
        cwd: SRC_DIR
        src: createSrcArr 'json'
        filter: 'isFile'
        dest: PUBLISH_DIR

      img:
        expand: true
        cwd: SRC_DIR
        src: createSrcArr 'img'
        filter: 'isFile'
        dest: PUBLISH_DIR

      others:
        expand: true
        cwd: SRC_DIR
        src: paths.others
        filter: 'isFile'
        dest: PUBLISH_DIR


    ##################
    ###   notify   ###
    ##################

    #
    # メッセージ通知タスク
    #
    # * [grunt-notify](https://github.com/dylang/grunt-notify)
    #
    notify:
      build:
        options:
          title: 'ビルド完了'
          message: 'タスクが正常終了しました。'
      watch:
        options:
          title: '監視開始'
          message: 'ローカルサーバーを起動しました: http://localhost:50000/'


    ##################
    ###   concat   ###
    ##################

    #
    # ファイル結合タスク
    #
    # * [grunt-contrib-concat](https://github.com/gruntjs/grunt-contrib-concat)
    #
    concat:
      options:
        separator: ''
      easeljs:
        src: []
        dest: "#{SRC_DIR}/common/js/build.js"


    #################
    ###   watch   ###
    #################

    #
    # ファイル更新監視タスク
    #
    # * [grunt-contrib-watch](https://github.com/gruntjs/grunt-contrib-watch)
    #
    watch:
      options:
        livereload: true
        spawn: false

      html:
        files: addSrcPath paths.html
        tasks: [
          'newer:copy:html'
          'notify:build'
        ]

      jade:
        files: addSrcPath paths.jade
        tasks: [
          'newer:jade'
          'notify:build'
        ]

      css:
        files: addSrcPath paths.css
        tasks: [
          'newer:copy:css'
          'autoprefixer'
          'notify:build'
        ]

      sass:
        files: addSrcPath paths.sass
        tasks: [
          'newer:sass'
          'notify:build'
        ]

      js:
        files: addSrcPath paths.js
        tasks: [
          'newer:jshint'
          'newer:copy:js'
          'notify:build'
        ]

      json:
        files: addSrcPath paths.json
        tasks: [
          'newer:jsonlint'
          'newer:copy:json'
          'notify:build'
        ]

      coffee:
        files: addSrcPath paths.coffee
        tasks: [
          'newer:coffeelint'
          'newer:coffee'
          'notify:build'
        ]

      img:
        files: [ addSrcPath paths.img ]
        tasks: [
          'newer:copy:img'
          'notify:build'
        ]

      others:
        files: addSrcPath paths.others
        tasks: [
          'newer:copy:others'
          'notify:build'
        ]

      jadeAll:
        files: paths.jadeInclude
        tasks: [
          'jade'
          'notify:build'
        ]

      sassAll:
        files: paths.sassInclude
        tasks: [
          'sass'
          'notify:build'
        ]

      coffeeAll:
        files: paths.coffeeInclude
        tasks: [
          'newer:coffeelint'
          'coffee'
          'notify:build'
        ]


  # spritesタスクを生成
  createSpritesTask 'commonSprites', "#{ASSETS_DIR}/img/common", "#{ASSETS_DIR}/css", "#{ASSETS_DIR}/img/common/commonSprites.png"
  createSpritesTask 'indexSprites', "#{ASSETS_DIR}/img/index", "#{ASSETS_DIR}/css", "#{ASSETS_DIR}/img/index/indexSprites.png"

  #
  # 実行タスクの順次定義 (`grunt.registerTask tasks.TASK` として登録)
  #
  tasks =
    init: [
      'bower'
    ]
    css: [
      'sass'
      'copy:css'
      'autoprefixer'
    ]
    html: [
      'jade'
      'copy:html'
    ]
    img: [
      'sprite'
      'copy:img'
    ]
    js: [
      #'coffeelint'
      'coffee'
      'jshint'
      'copy:js'
    ]
    json: [
      'jsonlint'
      'copy:json'
    ]
    watcher: [
      'notify:watch'
      'connect'
      'watch'
    ]
    default: [
      'clean'
      'js'
      'json'
      'img'
      'css'
      'html'
      'copy:others'
      'notify:build'
    ]


  # Grunt プラグイン読込
  require('load-grunt-tasks')(grunt)

  # 初期設定オブジェクトの登録
  grunt.initConfig conf

  # 実行タスクの登録
  grunt.registerTask 'init',    tasks.init
  grunt.registerTask 'css',     tasks.css
  grunt.registerTask 'html',    tasks.html
  grunt.registerTask 'img',     tasks.img
  grunt.registerTask 'js',      tasks.js
  grunt.registerTask 'json',    tasks.json
  grunt.registerTask 'watcher', tasks.watcher
  grunt.registerTask 'default', tasks.default
