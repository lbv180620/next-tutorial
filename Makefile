include Makefile.env

# 擬似ターゲット
# .PHONEY:

ps:
	docker compose ps

# ==== プロジェクトの立ち上げ ====

# launch:
# 	@make file-set
# 	@make publish-phpmyadmin
# 	@make publish-redisinsight
# 	@make build
# 	@make up
# 	@make useradd
# 	@make db-set

launch:
	cp env/.env.example .env
	@make build
	@make up
	@make useradd-client


file-set:
	mkdir -p sqls/{sql,script} infra/{data,redis} && \
		touch sqls/sql/query.sql sqls/script/set-query.sh && \
		cp env/.env.example .env && \
		mkdir .vscode && cp env/launch.json .vscode
		mkdir backend
# mkdir backend frontend

# phpMyAdmin
publish-phpmyadmin:
	mkdir -p ./infra/phpmyadmin/sessions
	sudo chown 1001 ./infra/phpmyadmin/sessions

# redisinsight
publish-redisinsight:
	mkdir -p ./infra/redisinsight/sessions
	sudo chown 1001 ./infra/redisinsight/sessions

db-set:
	docker compose exec db bash -c 'mkdir /var/lib/mysql/sql && \
		touch /var/lib/mysql/sql/query.sql && \
		chown -R mysql:mysql /var/lib/mysql'

useradd:
# web-root
	docker compose exec web bash -c ' \
		useradd -s /bin/bash -m -u $$USER_ID -g $$GROUP_ID $$USER_NAME'
# db-root
	docker compose exec db bash -c ' \
		useradd -s /bin/bash -m -u $$USER_ID -g $$GROUP_ID $$USER_NAME'
groupadd:
# web-root
	docker compose exec web bash -c ' \
		groupadd -g $$GROUP_ID $$GROUP_NAME'
# db-root
	docker compose exec db bash -c ' \
		groupadd -g $$GROUP_ID $$GROUP_NAME'

useradd-client:
# client-root
	docker compose exec client bash -c ' \
		useradd -s /bin/bash -m -u $$USER_ID -g $$GROUP_ID $$USER_NAME'
groupadd-client:
# client-root
	docker compose exec client bash -c ' \
		groupadd -g $$GROUP_ID $$GROUP_NAME'
webpack-set:
	mkdir -p $(env)/src/{scripts,styles,templates,images}
	cp -r env/webpack-$(env)/{*,.eslintrc.js,.prettierrc} $(env)/
	mkdir $(env)/src/styles/scss
	mv $(env)/styles/* $(env)/src/styles/scss/
	rm -rf $(env)/styles
	mv $(env)/setupTests.ts $(env)/src/
	mkdir $(env)/public
	cp env/.htaccess $(env)/public/

webpack-del:
	rm -r $(env)/{webpack,webpack.common.js,webpack.dev.js,webpack.prod.js,jsconfig.json,tsconfig.json,babel.config.js,postcss.config.js,stylelint.config.js,.eslintrc.js,.prettierrc,package.json,tailwind.config.js,tsconfig.jest.json,jest.config.js}

# ==========================

# ==== docker composeコマンド群 ====

build:
	docker compose build --no-cache --force-rm

up:
	docker compose up -d

rebuild:
	@make build
	@make up

down:
	docker compose down --remove-orphans

reset:
	@make down
	@make up

init:
	docker compose up -d --build
	docker compose exec web composer install
	docker compose exec web cp .env.example .env
remake:
	@make destroy
	@make init

start:
	docker compose start
stop:
	docker compose stop

restart:
	@make stop
	@make start

destroy:
	@make chown
	@make purge
	@make delete

purge:
	docker compose down --rmi all --volumes --remove-orphans

destroy-volumes:
	docker compose down --volumes --remove-orphans

delete:
	rm -rf infra/{data,redis} backend frontend sqls && rm .env
	rm -rf infra/{redisinsight,phpmyadmin} .vscode


# ログ関連

logs:
	docker compose logs
logs-watch:
	docker compose logs --follow
log-web:
	docker compose logs web
log-web-watch:
	docker compose logs --follow web
log-app:
	docker compose logs app
log-app-watch:
	docker compose logs --follow app
log-db:
	docker compose logs db
log-db-watch:
	docker compose logs --follow db

# =================================

# ==== パッケージ管理コマンド群 ====

# npm
npm:
	@make npm-install
npm-install:
	docker compose exec web npm install
npm-dev:
	docker compose exec web npm run dev
npm-watch:
	docker compose exec web npm run watch
npm-watch-poll:
	docker compose exec web npm run watch-poll
npm-hot:
	docker compose exec web npm run hot
npm-v:
	docker compose exec web npm -v
npm-init:
	docker compose exec web npm init -y
npm-i-D:
	docker compose exec web npm i -D $(pkg)
npm-run:
	docker compose exec web npm run $(cmd)
npm-un-D:
	docker compose exec web npm uninstall -D $(pkg)
# npx
npx-v:
	docker compose exec web npx -v
npx:
	docker compose exec web npx $(pkg)

# yarn
# npm-scriptコマンド
# コンテナ経由ではなく、backend/下で直接ビルドした方がいい
yarn:
	docker compose exec web yarn $(pkg)
yarn-install:
	docker compose exec web yarn install
yarn-dev:
	docker compose exec web yarn dev
yarn-build:
	docker compose exec web yarn build
yarn-watch:
	docker compose exec web yarn watch
yarn-watch-poll:
	docker compose exec web yarn watch-poll
yarn-hot:
	docker compose exec web yarn hot
yarn-v:
	docker compose exec web yarn -v
yarn-init:
	docker compose exec web yarn init -y
yarn-add:
	docker compose exec web yarn add $(pkg)
yarn-add-%:
	docker compose exec web yarn add $(@:yarn-add-%=%)
yarn-add-dev:
	docker compose exec web yarn add -D $(pkg)
yarn-add-dev-%:
	docker compose exec web yarn add -D $(@:yarn-add-dev-%=%)
yarn-run:
	docker compose exec web yarn run $(cmd)
yarn-run-s:
	docker compose exec web yarn run $(pkg)
yarn-rm:
	docker compose exec web yarn remove $(pkg)

# node
node:
	docker compose exec web node $(file)
# =====================================

# ==== コンテナ操作コマンド群 ====

# web
web:
	docker compose exec web bash
web-usr:
	docker compose exec -u $(USER) web bash
stop-web:
	docker compose stop web

# db
db:
	docker compose exec db bash
db-usr:
	docker compose exec -u $(USER) db bash

# client
client:
	docker compose exec client bash
client-usr:
	docker compose exec -u $(USER) client bash
stop-client:
	docker compose stop clinet

# sql
sql:
	docker compose exec db bash -c 'mysql -u $$MYSQL_USER -p$$MYSQL_PASSWORD $$MYSQL_DATABASE'

sql-root:
	docker compose exec db bash -c 'mysql -u root -p'

sqlc:
	@make query
	docker compose exec db bash -c 'mysql -u $$MYSQL_USER -p$$MYSQL_PASSWORD $$MYSQL_DATABASE < /var/lib/mysql/sql/query.sql'

query:
	@make chown-data
	cp ./sqls/sql/query.sql ./infra/data/sql/query.sql
# cp ./sqls/sql/query.sql ./_data/sql/query.sql
	@make chown-mysql

cp-sql:
	@make chown-data
	cp -r -n ./sqls/sql/** ./data/sql
# cp -r -n ./sqls/sql ./_data/sql
	@make chown-mysql

# redis
redis:
	docker compose exec redis redis-cli --raw

# ========================

# ==== パーミッション関連 ====

chown:
	@make chown-data
	@make chown-backend

# chown-web
chown-backend:
	sudo chown -R $(USER):$(GNAME) backend

chown-work:
	docker compose exec web bash -c 'chown -R $$USER_NAME:$$GROUP_NAME /work'

# chown-db
chown-data:
	sudo chown -R $(USER):$(GNAME) infra/data

chown-mysql:
	docker compose exec db bash -c 'chown -R mysql:mysql /var/lib/mysql'

# ===============================

# ==== Git関連 ====

# git msg=save
git:
	git add .
	git commit -m $(msg)
	git push origin $(br)
g:
	@make git

git-msg:
	env | grep "msg"

git-%:
	git add .
	git commit -m $(@:git-%=%)
	git push origin

# =============================

# ==== Volume関連 ====

# link
link:
	source
	ln -s `docker volume inspect $(rep)_db-store | grep "Mountpoint" | awk '{print $$2}' | awk '{print substr($$0, 2, length($$0)-3)}'` .
unlink:
	unlink _data
rep:
	env | grep "rep"

chown-volume:
	sudo chown -R $(USER):$(GNAME) ~/.local/share/docker/volumes

rm-data:
	@make chown-data
	rm -rf data

change-data:
	@make rm-data
	@make link

# docker
volume-ls:
	docker volume ls
volume-inspect:
	docker volume inspect $(rep)_db-store

# =======================

# ==== DB環境の切り替え ====

# webコンテナに.envファイルを持たせる:
# edit.envで環境変数を変更し、コンテナ内に.envを作成(環境変数は.envを優先するので、ビルド時にコンテナに持たせた環境変数を上書きする)
# phpdotenvを使用する際必要
cpenv:
	docker cp ./env/edit.env `docker compose ps -q web`:/work/.env

# DBの環境変更:
# DBの切り替え方法
# ①まずphpMyadminで切り替えるDB名でDBを作成しておき、かつ権限を持たせる
# ②作成したDB名でedit.envで環境変数をmake chenvで変更かつ再upしコンテナの環境変数を更新する
chenv:
	cp ./env/edit.env .env
	@make up

# ==== gulp関連 ====

yarn-add-D-gulp:
	docker compose exec web yarn add -D gulp browser-sync

mkgulp:
	cp env/gulpfile.js backend/

# ===== webpack関連 =====

# webpack5 + TS + React
yarn-add-D-webpack5-env:
	docker compose exec web yarn add -D \
	webpack webpack-cli \
	sass sass-loader css-loader style-loader \
	postcss postcss-loader autoprefixer \
	babel-loader @babel/core @babel/runtime @babel/plugin-transform-runtime @babel/preset-env core-js@3 regenerator-runtime babel-preset-minify\
	mini-css-extract-plugin html-webpack-plugin html-loader css-minimizer-webpack-plugin terser-webpack-plugin copy-webpack-plugin \
	webpack-dev-server \
	browser-sync-webpack-plugin browser-sync \
	dotenv-webpack \
	react react-dom @babel/preset-react @types/react @types/react-dom \
	react-router-dom@5.3.0 @types/react-router-dom history@4.10.1 \
	react-helmet-async \
	typescript@3 ts-loader fork-ts-checker-webpack-plugin \
	eslint@7.32.0 eslint-config-prettier@7.2.0 prettier@2.5.1 @typescript-eslint/parser@4.33.0 @typescript-eslint/eslint-plugin@4.33.0 husky@4.3.8 lint-staged@10.5.3 \
	eslint-plugin-react eslint-plugin-react-hooks eslint-config-airbnb eslint-plugin-import eslint-plugin-jsx-a11y \
	stylelint stylelint-config-standard stylelint-scss stylelint-config-standard-scss stylelint-config-prettier stylelint-config-recess-order postcss-scss \
	glob lodash rimraf npm-run-all axios \
	redux react-redux @types/redux @types/react-redux @reduxjs/toolkit @types/node \
	redux-actions redux-logger @types/redux-logger redux-thunk connected-react-router reselect typescript-fsa typescript-fsa-reducers immer normalizr \
	jest jsdom eslint-plugin-jest @types/jest @types/jsdom ts-jest \
	@testing-library/react @testing-library/jest-dom \
	@emotion/react @emotion/styled @emotion/babel-plugin \
	styled-components \
	tailwindcss@2.2.19 @types/tailwindcss eslint-plugin-tailwindcss \
	@material-ui/core @material-ui/icons @material-ui/styles @material-ui/system @types/material-ui \
	@chakra-ui/react @emotion/react@^11 @emotion/styled@^11 framer-motion@^6 @chakra-ui/icons focus-visible \
	yup react-hook-form @hookform/resolvers @hookform/error-message @hookform/error-message

# webpackの導入
yarn-add-D-webpack:
	docker compose exec web yarn add -D webpack webpack-cli
yarn-add-D-webpack-v4:
	docker compose exec web yarn add -D webpack@4.46.0 webpack-cli

# webpackの実行
yarn-webpack:
	docker compose exec web yarn webpack
webpack:
	@make yarn-webpack
wp:
	@make yarn-webpack
yarn-webpack-config:
	docker compose exec web yarn webpack --config $(path)
# modeを省略すると商用環境モードになる
yarn-run-webpack:
	docker compose exec web yarn webpack --mode $(mode)
yarn-run-webpack-dev:
	docker compose exec web yarn webpack --mode development
	docker compose exec web yarn webpack --mode development
# eval無効化
yarn-run-webpack-dev-none:
	docker compose exec web yarn webpack --mode development --devtool none

# webpack.config.js生成
touch-webpack:
	docker compose exec web touch webpack.config.js

# sass-loader
# sass ↔︎ css
yarn-add-D-loader-sass:
	docker compose exec web yarn add -D sass sass-loader css-loader style-loader

# postcss-loader
# ベンダープレフィックスを自動付与
yarn-add-D-loader-postcss:
	docker compose exec web yarn add -D postcss postcss-loader autoprefixer

# postcss-preset-env
# https://zenn.dev/lollipop_onl/articles/ac21-future-css-with-postcss
# https://levelup.gitconnected.com/setup-tailwind-css-with-webpack-3458be3eb547
yarn-add-D-postcss-preset-env:
	docker compose exec web yarn add -D postcss-preset-env

# postcss.config.js生成
touch-postcss:
	docker compose exec web touch postcss.config.js

# .browserslistrc生成(ベンダープレフィックス付与確認用)
# Chrome 4-25
touch-browserslist:
	docker compose exec web touch .browserslistrc

# file-loader
# CSSファイル内で読み込んだ画像ファイルの出力先での配置
# webpack5から不要
yarn-add-D-loader-file:
	docker compose exec web yarn add -D file-loader

# mini-css-extract-plugin
# ※webpack 4.x | mini-css-extract-plugin 1.x
# 1.6.2
# style-loaderの変わりに使う。
# これでビルドすると、CSSが別ファイルとして生成される。
# version選択できます。
yarn-add-D-plugin-minicssextract:
	docker compose exec web yarn add -D mini-css-extract-plugin@$(@)

# babel-loader
# JSX、ECMAScriptのファイルをバンドルするためのloader
# webpack 4.x | babel-loader 8.x | babel 7.x
yarn-add-D-loader-babel:
	docker compose exec web yarn add -D babel-loader @babel/core @babel/preset-env
# https://zenn.dev/sa2knight/articles/5a033a0288703c
yarn-add-D-loader-babel-full:
	docker compose exec web yarn add -D @babel/core @babel/runtime @babel/plugin-transform-runtime @babel/preset-env babel-loader

# babelでトランスパイルを行う際に、古いブラウザが持っていない機能を補ってくれるモジュール群
# regenerator-runtimeはES7で導入されたasync/awaitを補完するために使われる。
# core-js@3は色々な機能を補完
yarn-add-D-complement-babel:
	docker compose exec web yarn add -D core-js@3 regenerator-runtime

# babel-preset-minify
# https://www.npmjs.com/package/babel-preset-minify
# https://chaika.hatenablog.com/entry/2021/01/06/083000
yarn-add-D-babel-preset-minify:
	docker compose exec web yarn add -D babel-preset-minify

yarn-add-D-babel-option:
	docker compose exec web yarn add -D @babel/plugin-external-helpers @babel/plugin-proposal-class-properties @babel/plugin-proposal-object-rest-spread

# .babelrc生成
# JSON形式で記載
touch-babelrc:
	docker compose exec web touch .babelrc

# babel.config.js
touch-babel:
	docker compose exec web touch babel.config.js

# eslint-loader
# ※eslint-loader@4: minimum supported eslint version is 6
# ESlintを使うためにeslint
# ESlintとwebpackを連携するためにeslint-loader
# ESlint上でbabelと連携するためにbabel-eslint
# 8系はエラーが出る
# eslint-loaderは非推奨になった
yarn-add-D-loader-eslint:
	docker compose exec web yarn add -D eslint@6 eslint-loader babel-eslint

# eslint-webpack-plugin

# .eslintrc生成
# JSON形式で記載
touch-eslintrc:
	docker compose exec web touch .eslintrc

# 対話形式で.eslintrc生成
yarn-eslint-init:
	docker compose exec web yarn run eslint --init

# html-webpack-plugin
# 指定したhtmlに自動的にscriptタグを注入する。
# ファイル名をhashにした時に、手動でhtmlに読み込ませる必要がなくなる。
#※Drop support for webpack 4 and node <= 10 - For older webpack or node versions please use html-webpack-plugin 4.x
# 4.5.2
yarn-add-D-plugin-htmlwebpack:
	docker compose exec web yarn add -D html-webpack-plugin@$(@)

# html-loader
# htmlファイル内で読み込んだ画像をJSファイルに自動的バンドルする
# HTMLファイル内で読み込んだ画像ファイルの出力先での配置
# 1.3.2
# ※html-webpack-pluginで対象となるhtmlファイルを読み込んでいないと、html-loaderだけ記入してもimgタグはバンドルされない。
# html-loaderとhtml-webpack-pluginは一緒に使う。
yarn-add-D-loader-html:
	docker compose exec web yarn add -D html-loader@$(@)

# 商用と開発でwebpack.config.jsを分割
touch-webpack-separation:
	docker compose exec web touch webpack.common.js webpack.dev.js webpack.prod.js

# webpack-merge
# webpackの設定ファイルをmergeする
yarn-add-D-webpackmerge:
	docker compose exec web yarn add -D webpack-merge

# 商用にminify設定
# JS版: terser-webpack-plugin
# ※webpack4 4.x 4.2.3
# CSS版: optimize-css-assets-webpack-plugin(webpack4の場合)
# HTML版: html-webpack-plugin https://github.com/jantimon/html-webpack-plugin
# ※webpack5以上は、css-minimizer-webpack-plugin
yarn-add-D-minify-v4:
	docker compose exec web yarn add -D optimize-css-assets-webpack-plugin terser-webpack-plugin@4.2.3 html-webpack-plugin@4.5.2
yarn-add-D-minify-v5:
	docker compose exec web yarn add -D css-minimizer-webpack-plugin terser-webpack-plugin html-webpack-plugin

# webpack-dev-server
# 開発用のサーバが自動に立ち上がるようにする
yarn-add-D-webpackdevserver:
	docker compose exec web yarn add -D webpack-dev-server

# ejs-html-loader
# ejs-compiled-loader
# ejs-plain-loader
yarn-add-D-loader-ejs-plain:
	docker compose exec web yarn add -D ejs ejs-plain-loader

# raw-loader
# txtファイルをバンドルするためのloader
# webpack5から不要
yarn-add-D-loader-raw:
	docker compose exec web yarn add -D raw-loader

# extract-text-webpack-plugin
# webpack4以降は mini-css-extract-pluginがあるので不要
yarn-add-D-plugin-extracttextwebpack:
	docker compose exec web yarn add -D extract-text-webpack-plugin

# resolve-url-loader
yarn-add-D-loader-resolveurl:
	docker compose exec web yarn add -D resolve-url-loader

# browser-sync
yarn-add-D-plugin-browsersync:
	docker compose exec web yarn add -D browser-sync-webpack-plugin browser-sync

# copy-webpack-plugin
# copy-webpack-pluginは、指定したファイルをそのままコピーして出力します。これも、出力元と先を合わせるのに役立ちます。
# https://webpack.js.org/plugins/copy-webpack-plugin/
yarn-add-D-plugin-copy:
	docker compose exec web yarn add -D copy-webpack-plugin

# imagemin-webpack-plugin
# ファイルを圧縮します。
# 各ファイル形式に対応したパッケージもインストールします。
# png imagemin-pngquant
# jpg imagemin-mozjpeg
# gif imagemin-gifsicle
# svg imagemin-svgo
yarn-add-D-plugin-imagemin:
	docker compose exec web yarn add -D imagemin-webpack-plugin imagemin-pngquant imagemin-mozjpeg imagemin-gifsicle imagemin-svgo


# webpack-watched-glob-entries-plugin
# globの代わり
# https://shuu1104.com/2021/11/4388/
yarn-add-D-plugin-watched-glob-entries:
	docker compose exec web yarn add -D webpack-watched-glob-entries-plugin

# clean-webpack-plugin
# https://shuu1104.com/2021/12/4406/
yarn-add-D-plugin-clean:
	docker compose exec web yarn add -D clean-webpack-plugin

# webpack-stats-plugin
# mix-manifest.jsonを、laravel-mixを使わずに自作する
# https://qiita.com/kokky/items/02063edf3252e147940a
yarn-add-D-plugin-webpack-stats:
	docker compose exec web yarn add -D webpack-stats-plugin


# source-map-loader
# webpack-hot-middleware

# dotenv-webpack
# ※webpack5からそのままではprocess.envで環境変数を読み込めない
# https://forsmile.jp/javascript/1054/

yarn-add-D-dotenv-webpack:
	docker compose exec web yarn add -D dotenv-webpack

# ---- PWA化 ----

# https://www.npmjs.com/package/workbox-sw
# https://www.npmjs.com/package/workbox-webpack-plugin
# https://www.npmjs.com/package/webpack-pwa-manifest
# https://github.com/webdeveric/webpack-assets-manifest

# https://www.hivelocity.co.jp/blog/46013/
# https://qiita.com/umashiba/items/1157e7e520f668417cf0

yarn-add-D-pwa:
	docker compose exec web yarn add -D workbox-sw workbox-webpack-plugin webpack-pwa-manifest webpack-assets-manifest

# ==== jQuery ====

yarn-add-jquey:
	docker compose exec web yarn add jQuery

# ==== Bootstrap ====

yarn-add-bootstrap-v5:
	docker compose exec web yarn add bootstrap @popperjs/core
yarn-add-bootstrap-v4:
	docker compose exec web yarn add bootstrap@4.6.1

# ==== TailwindCSS 関連 ====

# https://zenn.dev/otanu/articles/f0a0b2bd0d9c44

# https://tailwindcss.jp/docs/installation
# https://gsc13.medium.com/how-to-configure-webpack-5-to-work-with-tailwindcss-and-postcss-905f335aac2
# https://qiita.com/hirogw/items/518a0143aee2160eb2d8
# https://qiita.com/maru401/items/eb4c7160b19127a76457

# インストールパッケージ
# https://github.com/tailwindlabs/tailwindcss-from-zero-to-production/tree/main/01-setting-up-tailwindcss

# entrypointに import "tailwind.css"
# webpackと一緒に使う場合は、src/css/tailwind.css -o public/css/dist.css は不要
# tailwind.css
# @tailwind base;
# @tailwind components;
# @tailwind utilities;

# package.json
# "scripts": {
#     "dev": "TAILWIND_MODE=watch postcss src/css/tailwind.css -o public/css/dist.css -w",
#     "prod": "NODE_ENV=production postcss src/css/tailwind.css -o public/css/dist.css"
#   }

yarn-add-D-tailwind-postcss-cli:
	docker compose exec web yarn add -D tailwindcss postcss postcss-cli autoprefixer cssnano
yarn-add-D-tailwind-v2-postcss-cli:
	docker compose exec web yarn add -D tailwindcss@2.2.19 postcss
	postcss-cli autoprefixer cssnano

# https://qiita.com/hironomiu/items/eac89ca4801534862fed#tailwind-install--initialize
# ホットリロードの併用すると、勝手にビルドされ続ける
yarn-add-D-tailwind-v3-webpack:
	docker compose exec web yarn add -D tailwindcss @types/tailwindcss eslint-plugin-tailwindcss
# 推奨
yarn-add-D-tailwind-v2-webpack:
	docker compose exec web yarn add -D tailwindcss@2.2.19 @types/tailwindcss eslint-plugin-tailwindcss



# postcss.config.js
# module.exports = (ctx) => {
#     return {
#         map: ctx.options.map,
#         plugins: {
#             tailwindcss: {},
#             autoprefixer: {},
#             cssnano: ctx.env === "production" ? {} : false,
#         },
#     }
# };
#
# module.exports = (ctx) => {
#     return {
#         map: ctx.options.map,
#         plugins: [
#             require('tailwindcss'),
#             require('autoprefixer'),
#             ctx.env === "production && require('cssnano')
#         ].filter(Boolean),
#     }
# };

# tailwind.config.js
# module.exports = {
#   mode: "jit",
#   purge: ["./public/index.html"],

# tailwind.config.jsとpostcss.config.js生成
yarn-tailwind-init-p:
	docker compose exec web yarn tailwindcss init -p

# tailwind.config.js生成
yarn-tailwind-init:
	docker compose exec web yarn tailwindcss init

# ==== React関連 ====

# https://zenn.dev/shohigashi/scraps/15f0eb42e97d5c

yarn-add-D-react-full:
	docker compose exec web yarn add -D react react-dom react-router-dom @babel/preset-react @types/react @types/react-dom @types/react-router-dom react-helmet-async history

yarn-add-D-react:
	docker compose exec web yarn add -D react react-dom @babel/preset-react @types/react @types/react-dom

# https://issueoverflow.com/2018/08/02/use-react-easily-with-react-scripts/
yarn-add-D-react-scripts:
	docker compose exec web yarn add -D react-scripts


# ---- react-router ----

# https://qiita.com/koja1234/items/486f7396ed9c2568b235
yarn-add-D-react-router:
	docker compose exec web yarn add -D react-router history

# 推奨
# https://zenn.dev/h_yoshikawa0724/articles/2020-09-22-react-router
# react-router も必要になりますが、react-router-dom の依存関係にあるので、一緒に追加されます。
# v6
# https://reactrouter.com/docs/en/v6
yarn-add-D-react-router-dom-v6:
	docker compose exec web yarn add -D react-router-dom @types/react-router-dom history

# v5
# https://v5.reactrouter.com/
# Reduxと一緒に使う場合は、react-routerは5系、historyは4系推奨
yarn-add-D-react-router-dom:
	docker compose exec web yarn add -D react-router-dom@5.3.0 @types/react-router-dom@ history@4.10.1

# ---- react-helmet ----

# https://github.com/nfl/react-helmet
# https://www.npmjs.com/package/@types/react-helmet
yarn-add-D-react-helmet:
	docker compose exec web yarn add -D react-helmet @types/react-helmet

# 推奨
# https://github.com/staylor/react-helmet-async
yarn-add-D-react-helmet-async:
	docker compose exec web yarn add -D react-helmet-async

# ---- react-icons ----

yarn-add-D-react-icons:
	docker compose exec web yarn add -D react-icons

# ---- react-spinners ----

yarn-add-D-react-spinners:
	docker compose exec web yarn add -D react-spinners

# ---- html-react-parser ----

yarn-add-D-html-react-parser:
	docker compose exec web yarn add -D html-react-parser

# ---- react-paginate ----

# https://www.npmjs.com/package/react-paginate
yarn-add-D-react-paginate:
	docker compose exec web yarn add -D react-paginate @types/react-paginate

# ---- react-countup ----

# https://www.npmjs.com/package/react-countup
yarn-add-D-react-countup:
	docker compose exec web yarn add -D react-countup

# ==== Create React App ====

# ---- create-react-app ----

yarn-create-react-app:
	docker compose exec web yarn create react-app .

yarn-create-react-app-npm:
	docker compose exec web yarn create react-app . --use-npm

yarn-create-react-app-ts:
	docker compose exec web yarn create react-app . --template typescript

# https://kic-yuuki.hatenablog.com/entry/2019/09/08/111817
yarn-add-eslint-config-react-app:
	docker compose exec web yarn add eslint-config-react-app

yarn-start:
	docker compose exec web yarn start

# ---- reduxjs/cra-template-redux-typescript ----

# https://github.com/reduxjs/cra-template-redux-typescript

# npx create-react-app my-app --template redux-typescript

yarn-create-react-app-redux-ts:
	docker compose exec web yarn create react-app --template redux-typescript .

# ---- PWA化 ----

# https://qiita.com/suzuki0430/items/9c2bd2b8839c164cfb28
# npx create-react-app [プロジェクト名] --template cra-template-pwa
# npx create-react-app [プロジェクト名] --template cra-template-pwa-typescript

yarn-create-react-app-ts-pwa:
	docker compose exec web yarn create react-app --template cra-template-pwa-typescript .

# ---- CRACO -----

# https://github.com/gsoft-inc/craco/blob/master/packages/craco/README.md

# カスタマイズ
# importのalias設定
# https://zukucode.com/2021/06/react-create-app-import-alias.html
yarn-add-D-craco:
	docker compose exec web yarn add -D @craco/craco eslint-import-resolver-alias

# craco.config.js
# const path = require('path');
#
# module.exports = {
#   webpack: {
#     alias: {
#       '@src': path.resolve(__dirname, 'src/'),
#     },
#   },
# };

# "scripts": {
#   "start": "craco start",
#   "build": "craco build",
#   "test": "craco test",
#   "eject": "craco eject"
# },

# tsconfig.paths.json
# {
#   "compilerOptions": {
#     "baseUrl": ".",
#     "paths": {
#       "@src/*": [
#         "./src/*"
#       ],
#     }
#   }
# }

# eslintrc.js
# module.exports = {
#   settings: {
#     'import/resolver': {
#       alias: {
#         map: [['@src', './src']],
#         extensions: ['.js', '.jsx', '.ts', '.tsx'],
#       },
#     },
#   },
# };

# tsconfig.json
# {
# 	"extends": "./tsconfig.paths.json",
# }

# Tailwind CSS for create-react-app
# https://v2.tailwindcss.com/docs/guides/create-react-app
# https://ramble.impl.co.jp/1681/#toc8
yarn-add-D-tailwind-v2-react:
	docker compose exec web yarn add -D tailwindcss@npm:@tailwindcss/postcss7-compat postcss@^7 autoprefixer@^9 @craco/craco

# "scripts": {
#     "start": "craco start",
#     "build": "craco build",
#     "test": "craco test",
#     "eject": "react-scripts eject"
#   },

# craco.config.js
# module.exports = {
#     style: {
#         postcss: {
#             plugins: [
#                 require('tailwindcss'),
#                 require('autoprefixer')
#             ]
#         }
#     }
# };
touch-caraco:
	docker compose exec web touch craco.config.js

# tailwind.config.js
# purge: [
#         './src/**/*.{js,jsx,ts,tsx}',
#         './public/index.html'
# ],
# yarn-tailwind-init:
	docker compose exec web yarn tailwind init

# ==== CSS in JSX ====

# styled-jsx
yarn-add-D-styledjsx:
	docker compose exec web yarn add -D styled-jsx

# styled-components
yarn-add-D-styledcomponents:
	docker compose exec web yarn add -D styled-components

#emotion
# https://github.com/iwakin999/next-emotion-typescript-example
# https://zenn.dev/iwakin999/articles/7a5e11e62ba668
# https://emotion.sh/docs/introduction
# https://qiita.com/cheez921/items/1d13545f8a0ea46beb51
# https://emotion.sh/docs/@emotion/babel-preset-css-prop
# https://www.npmjs.com/package/@emotion/babel-plugin
# https://qiita.com/xrxoxcxox/items/17e0762d8e69c1ef208f
#
# React v17以上
yarn-add-D-emotion-v11:
	docker compose exec web yarn add -D @emotion/react @emotion/styled @emotion/babel-plugin

# React v17以下
yarn-add-D-emotion-v10:
	docker compose exec web yarn add -D @emotion/core @emotion/styled @emotion/babel-preset-css-prop

# 非推奨
yarn-add-D-emotion-css:
	docker compose web yarn add -D @emotion/css

# Linaria
# https://github.com/callstack/linaria
# https://www.webopixel.net/javascript/1722.html
yarn-add-D-inaria:
	docker compose exec web yarn add -D @linaria/core @linaria/react @linaria/babel-preset @linaria/shaker @linaria/webpack-loader

# ==== Storybook ====

# https://zenn.dev/otanu/articles/f0a0b2bd0d9c44

# yarn add --dev @storybook/react

# npx -p @storybook/cli sb init

# yarn add -D @storybook/cli
# yarn sb init

# yarn add -D @storybook/addon-info @storybook/addon-knobs

# yarn add -D @storybook/addon-knobs \
#   @storybook/addon-viewport \
#   @storybook/addon-storysource \
#   react-docgen-typescript-loader \
#   @storybook/addon-info \
#   @storybook/addon-console

# yarn add -D @types/storybook__react \
#   @types/storybook__addon-info \
#   @types/storybook__addon-actions \
#   @types/storybook__addon-knobs

# yarn add -D gh-pages

# ==== Redux ====

# https://qiita.com/hironomiu/items/eac89ca4801534862fed

# https://redux.js.org/introduction/installation
# https://react-redux.js.org/tutorials/connect
yarn-add-D-redux:
	docker-compos exec web yarn add -D redux react-redux @types/redux @types/react-redux @types/node redux-thunk connected-react-router reselect immer normalizr

yarn-add-D-reduxjs-toolkit:
	docker compose exec web yarn add -D @reduxjs/toolkit

# https://redux-toolkit.js.org/
# https://redux-toolkit.js.org/tutorials/typescript
yarn-add-D-redux-full:
	docker compose exec web yarn add -D redux react-redux @types/redux @types/react-redux @reduxjs/toolkit @types/node redux-actions redux-logger @types/redux-logger redux-thunk connected-react-router reselect typescript-fsa typescript-fsa-reducers immer normalizr


yarn-add-line-liff:
	docker compose exec web yarn add -D @line/liff


# ---- thunk -----

# https://github.com/reduxjs/redux-thunk

yarn-add-D-redux-thunk:
	docker compose exec web yarn add -D redux-thunk

# ---- saga ----

# https://redux-saga.js.org/

yarn-add-D-redux-saga:
	docker compose exec web yarn add redux-saga

# ==== Recoil ====

# https://recoiljs.org/docs/introduction/getting-started/
# https://zenn.dev/eitarok/articles/7ee50e2f91f939
yarn-add-D-recoil:
	docker compose exec web yarn add -D recoil recoil-persist

# ==== useSWR ====

# https://swr.vercel.app/ja

yarn-add-D-swr:
	docker compose exec web yarn add -D swr

# ==== React Query ====

# https://react-query.tanstack.com/

yarn-add-react-query:
	docker compose exec web yarn add -D react-query

# ==== Next.js ====

# https://nextjs.org/docs
# https://nextjs.org/docs/getting-started
# https://nextjs-ja-translation-docs.vercel.app/docs/getting-started
# https://zenn.dev/otanu/articles/f0a0b2bd0d9c44

# tutorial
# https://nextjs.org/learn/basics/create-nextjs-app
# npx create-next-app nextjs-blog --use-npm --example "https://github.com/vercel/next-learn/tree/master/basics/learn-starter"

# Automatic Setup
yarn-create-next-app:
	docker compose exec web yarn create next-app .

yarn-create-next-app-ts:
	docker compose exec web yarn create next-app --typescript .

# Manual Setup
# package.json
# "scripts": {
#   "dev": "next dev -p 3001",
#   "build": "next build",
#   "start": "next start",
#   "lint": "next lint"
# }
yarn-add-D-next:
	yarn add -D next react react-dom

# ==== UI ====

# Material UI
# https://mui.com/getting-started/installation/
# https://next--material-ui.netlify.app/ja/guides/typescript/
# https://zenn.dev/h_yoshikawa0724/articles/2021-09-26-material-ui-v5
# https://zuma-lab.com/posts/next-mui-emotion-settings
# https://cloudpack.media/59677

# v4
yarn-add-D-ui-material-v4:
	dockert-compose exec web yarn add -D @material-ui/core @material-ui/icons @material-ui/styles @material-ui/system @types/material-ui

yarn-add-D-ui-mui-v4-webpack:
	docker compose exec web yarn add -D @material-ui/core @material-ui/icons @material-ui/system

# v5
yarn-add-D-ui-mui-emotion:
	docker compose exec web yarn add @mui/material @emotion/react @emotion/styled @mui/icons-material @mui/system @mui/styles @mui/lab

yarn-add-D-ui-mui-styled-components:
	docker compose exec web yarn add @mui/material @mui/styled-engine-sc styled-components @mui/icons-material @mui/system @mui/styles @mui/lab

# 推奨
yarn-add-D-ui-mui-v5-webpack:
	docker compose exec web yarn add -D @mui/material @mui/icons-material @mui/system @mui/styles @mui/lab


# Chakra UI
# https://chakra-ui.com/docs/getting-started

yarn-add-D-ui-chakra:
	docker compose exec web yarn add -D @chakra-ui/react @emotion/react@^11 @emotion/styled@^11 framer-motion@^6 @chakra-ui/icons focus-visible


# Headless UI
# https://headlessui.dev/
# https://github.com/tailwindlabs/headlessui/tree/main/packages/%40headlessui-react
yarn-add-D-ui-headless:
	docker compose exec web yarn add @headlessui/react


# React Hook Form & Yup | Zod
# https://react-hook-form.com/
# https://qiita.com/NozomuTsuruta/items/60d15d97eeef71993f06
# https://qiita.com/NozomuTsuruta/items/0140acaee87b7c4ed856
# https://zenn.dev/you_5805/articles/ad49926e7ad2d9
# https://www.npmjs.com/package/@hookform/error-message
# https://www.npmjs.com/package/yup
# https://www.npmjs.com/package/zod

yarn-add-D-react-hook-form-yup:
	docker compose exec web yarn add -D yup react-hook-form @hookform/resolvers @hookform/error-message

yarn-add-D-react-hook-form-zod:
	docker compose exec web yarn add -D zod react-hook-form @hookform/resolvers @hookform/error-message

# Formik
yarn-add-D-formik-yup:
	docker compose web yarn add -D yup @types/yup formik


# ==== TypeScript =====

# https://github.com/microsoft/TypeScript/tree/main/lib
# https://qiita.com/ryokkkke/items/390647a7c26933940470
# https://zenn.dev/chida/articles/bdbcd59c90e2e1
# https://www.typescriptlang.org/ja/tsconfig
# https://typescriptbook.jp/reference/tsconfig/tsconfig.json-settings
yarn-add-D-loader-ts:
	docker compose exec web yarn add -D typescript@3.9.9 ts-loader

yarn-add-D-babel-ts:
	docker compose exec web yarn add -D typescript@3.9.9 babel-loader @babel/preset-typescript

yarn-add-D-loader-ts-full:
	docker compose exec web yarn add -D typescript@3.9.9 ts-loader @babel/preset-typescript @types/react @types/react-dom

# https://qiita.com/yamadashy/items/225f287a25cd3f6ec151
yarn-add-D-ts-option:
	docker compose exec web yarn add -D @types/webpack @types/webpack-dev-server ts-node @types/node typesync

# fork-ts-checker-webpack-plugin
# https://www.npmjs.com/package/fork-ts-checker-webpack-plugin
# https://github.com/TypeStrong/fork-ts-checker-webpack-plugin
yarn-add-D-plugin-forktschecker:
	docker compose exec web yarn add -D fork-ts-checker-webpack-plugin

# ESLint & & Stylelint & Prettier(TypeScript用)
# eslint-config-prettier
# ESLintとPrettierを併用する際に
#
# @typescript-eslint/eslint-plugin
# ESLintでTypeScriptのチェックを行うプラグイン
#
# @typescript-eslint/parser
# ESLintでTypeScriptを解析できるようにする
#
# husky
# Gitコマンドをフックに別のコマンドを呼び出せる
# 6系から設定方法が変更
#
# lint-staged
# commitしたファイル(stagingにあるファイル)にlintを実行することができる
#
# ※ eslint-config-prettierの8系からeslintrcのextendsの設定は変更
# https://github.com/prettier/eslint-config-prettier/blob/main/CHANGELOG.md#version-800-2021-02-21
yarn-add-D-ts-eslint-prettier:
	docker compose exec web yarn add -D eslint@7.32.0 eslint-config-prettier@7.2.0 prettier@2.5.1 @typescript-eslint/parser@4.33.0 @typescript-eslint/eslint-plugin@4.33.0 husky@4.3.8 lint-staged@10.5.3

# https://github.com/yannickcr/eslint-plugin-react
# https://qiita.com/Captain_Blue/items/5d6969643148174e70b3
# https://zenn.dev/yhay81/articles/def73cf8a02864
# https://qiita.com/ro-komatsuna/items/bbfe5304c78ce4a10f1a
# https://zenn.dev/ro_komatsuna/articles/eslint_setup
yarn-add-D-eslint-react:
	docker compose exec web yarn add -D eslint-plugin-react eslint-plugin-react-hooks eslint-config-airbnb eslint-plugin-import eslint-plugin-jsx-a11y

yarn-add-D-eslint-option:
	docker compose exec web yarn add -D eslint-plugin-babel flowtype-plugin relay-plugin eslint-plugin-ava eslint-plugin-eslint-comments eslint-plugin-simple-import-sort eslint-plugin-sonarjs eslint-plugin-unicorn

# .eslintrc.js
# module.exports = {
#     env: {
#         browser: true,
#         es6: true
#     },
#     extends: [
#         "eslint:recommended",
#         "plugin:@typescript-eslint/recommended",
#         "prettier",
#         "prettier/@typescript-eslint"
#     ],
#     plugins: ["@typescript-eslint"],
#     parser: "@typescript-eslint/parser",
#     parserOptions: {
#         "sourceType": "module",
#         "project": "./tsconfig.json"
#     },
#     root: true,
#     rules: {}
# }
touch-eslintrcjs:
	docker compose exec web touch .eslintrc.js

# stylelint-recommended版
# https://qiita.com/y-w/items/bd7f11013fe34b69f0df
yarn-add-D-stylelint-recommended:
	docker compose exec web yarn add -D stylelint stylelint-config-recommended stylelint-scss stylelint-config-recommended-scss stylelint-config-prettier stylelint-config-recess-order postcss-scss

# stylelint-standard版
# https://rinoguchi.net/2021/12/prettier-eslint-stylelint.html
# https://lab.astamuse.co.jp/entry/stylelint
# stylelintのorderモジュール選定
# https://qiita.com/nabepon/items/4168eae542861cfd69f7
# postcss-scss
# https://qiita.com/ariariasria/items/8d33943e34d94bbaa9bf
yarn-add-D-stylelint-standard:
	docker compose exec web yarn add -D stylelint stylelint-config-standard stylelint-scss stylelint-config-standard-scss stylelint-config-prettier stylelint-config-recess-order postcss-scss


# .stylelintrc.js
# module.exports = {
#   extends: ['stylelint-config-recommended'],
#   rules: {
#     'at-rule-no-unknown': [
#       true,
#       {
#         ignoreAtRules: ['extends', 'tailwind'],
#       },
#     ],
#     'block-no-empty': null,
#     'unit-whitelist': ['em', 'rem', 's'],
#   },
# }
touch-stylelintrcjs:
		docker compose exec web touch .stylelintrc.js
# https://scottspence.com/posts/stylelint-configuration-for-tailwindcss
# {
#   "extends": [
#     "stylelint-config-standard"
#   ],
#   "rules": {
#     "at-rule-no-unknown": [
#       true,
#       {
#         "ignoreAtRules": [
#           "apply",
#           "layer",
#           "responsive",
#           "screen",
#           "tailwind"
#         ]
#       }
#     ]
#   }
# }
touch-stylelintrc:
	docker compose exec web touch .stylelintrc

# .prettierrc
# {
#     "printWidth": 120,
#     "singleQuote": true,
#     "semi": false
# }
touch-prettierrc:
	docker compose exec web touch .prettierrc


# ==== Jest関連 ====

# https://jestjs.io/ja/
# https://jestjs.io/

# https://zenn.dev/otanu/articles/f0a0b2bd0d9c44
# https://qiita.com/hironomiu/items/eac89ca4801534862fed

# package.json
# "scripts": {
#     "test": "jest",
# },
yarn-add-D-jest:
	docker compose exec web yarn add -D jest ts-jest @types/jest ts-node

# https://qiita.com/suzu1997/items/e4ee2fc1f52fbf505481
# https://zenn.dev/t_keshi/articles/react-test-practice
yarn-add-D-jest-full:
	docker compose exec web yarn add -D jest jsdom eslint-plugin-jest @types/jest @types/jsdom ts-jest

# https://testing-library.com/docs/react-testing-library/intro/
# https://qiita.com/ossan-engineer/items/4757d7457fafd44d2d2f
yarn-add-D-testing-library:
	docker compose exec web yarn add -D @testing-library/react @testing-library/jest-dom

yarn-add-D-jest-option:
	docker compose exec web yarn add -D @testing-library/user-event eslint-plugin-testing-library eslint-plugin-jest-dom

# https://jestjs.io/ja/docs/tutorial-react
yarn-add-D-jest-babel-react:
	docker compose exec web yarn add -D jest babel-jest react-test-renderer

# jest.config.js生成
# roots: [
#   "<rootDir>/src"
# ],

# transform: {
#   "^.+\\.(ts|tsx)$": "ts-jest"
# },

# ? Would you like to use Jest when running "test" script in "package.json"?	n
# ? Would you like to use Typescript for the configuration file?	y
# ? Choose the test environment that will be used for testing	jsdom
# ? Do you want Jest to add coverage reports?	n
# Which provider should be used to instrument code for coverage?	babel
# https://jestjs.io/docs/cli#--coverageproviderprovider
# ? Automatically clear mock calls, instances and results before every test?	n
jest-init:
	docker compose exec web yarn jest --init

ts-jest-init:
	docker compose exec web yarn ts-jest config:init

# ==== Vue ====

yarn-add-D-vue:
	docker compose exec web yarn add -D vue vue-class-component


# ==== Chart.js ====

# chart.js
yarn-add-D-chartjs:
	docker compose exec web yarn add -D chart.js

# react-chartjs2
yarn-add-react-chartjs-2:
	docker compose exec web yarn add -D react-chartjs-2 chart.js

# ==== Swiper.js ====

# https://swiperjs.com/
# https://swiperjs.com/react
yarn-add-D-swiper:
	docker compose exec web yarn add -D swiper

# https://www.npmjs.com/package/react-id-swiper
yarn-add-D-swiper-better:
	docker compose exec web yarn add -D swiper@5.4.2 react-id-swiper@3.0.0

# ==== Three.js ====

# https://threejs.org/
yarn-add-D-three:
	docker compose exec web yarn add -D three @types/three @react-three/fiber

# ==== Firebase ====

yarn-add-firebase:
	docker compose exec web yarn add firebase react-firebase-hooks

yarn-g-add-firebase-tools:
	docker compose exec web yarn global add firebase-tools

# ==== 便利なモジュール群 =====

# ---- モックサーバ ----
# json-server
# package.json
# {
#   "scripts": {
#     "start": "npx json-server --watch db.json --port 3001"
# }
yarn-add-D-jsonserver:
	docker compose yarn add -D json-server

# http-server
# https://www.npmjs.com/package/http-server
yarn-add-D-http-server:
	docker compose exec web yarn add -D http-server

# serve
# https://www.npmjs.com/package/serve
yarn-add-D-serve:
	docker compose exec web yarn add -D serve

# Servør
# https://www.npmjs.com/package/servor
yarn-add-D-servor:
	docker compose exec web yarn add -D servor

# ---- 便利なモジュール ----

# glob
# sass ファイル内で @import するときに*（アスタリスク）を使用できるようにするため
yarn-add-D-loader-importglob:
	docker compose add -D import-glob-loader
yarn-add-D-glob:
	docker compose exec web yarn add -D glob

# lodash
# https://qiita.com/soso_15315/items/a08e28def541c28458a0
# import _ from 'lodash';
yarn-add-D-lodash:
	docker compose exec web yarn add -D lodash @types/lodash

# https://www.nxworld.net/support-modules-for-npm-scripts-task.html
# publicフォルダを自動でクリーンにするコマンドも追加
# rimraf
# Linuxのrmコマンドと似たrimrafコマンドが使えるようになる
yarn-add-D-rimraf:
	docker compose exec web yarn add -D rimraf
yarn-cleanup:
	docker compose exec web yarn -D cleanup
# コピー
yarn-add-D-cpx:
	docker compose exec web yarn add -D	cpx
# ディレクトリ作成
yarn-add-D-mkdirp:
	docker compose exec web yarn add -D mkdirp
# ディレクトリ・ファイル名を変更
yarn-add-D-rename:
	docker compose exec web yarn add -D rename-cli
# まとめて実行・直列/並列実行
yarn-add-D-npm-run-all:
	docker compose exec web yarn add -D npm-run-all
# 監視
yarn-add-D-onchange:
	docker compose exec web yarn add -D onchange
# 環境変数を設定・使用する
yarn-add-D-cross-env:
	docker compose exec web yarn add -D cross-env
# ブラウザ確認をサポート
yarn-add-D-browser-sync:
	docker compose exec web yarn add -D browser-sync

# axios
yarn-add-D-axios:
	docker compose exec web yarn add -D axios @types/axios

# sort-package-json
# package.json を綺麗にしてくれる
yarn-add-D-sort-package-json:
	docker compose exec web yarn add -D sort-package-json

# node-sass typed-scss-modules
# CSS Modulesを使用する際に必要
# https://www.npmjs.com/package/typed-scss-modules
# https://github.com/skovy/typed-scss-modules
# https://zenn.dev/noonworks/scraps/61091d5a367487
yarn-add-D-nodesass:
	docker compose exec web yarn add -D node-sass typed-scss-modules

# ---- Node.js ----

# Express
# https://www.npmjs.com/package/@types/express
yarn-add-D-express:
	docker compose exec web yarn add -D express @types/express

# proxy中継
# https://github.com/chimurai/http-proxy-middleware
# https://www.npmjs.com/package/http-proxy-middleware
# https://www.twilio.com/blog/node-js-proxy-server-jp
# https://zenn.dev/daisukesasaki/articles/d67dfa0d75fdf77de4ad
yarn-add-D-proxy:
	docker compose exec web yarn add -D http-proxy-middleware

# ログ出力
# https://www.npmjs.com/package/morgan
# https://www.npmjs.com/package/@types/morgan
# https://qiita.com/mt_middle/items/543f83393c357ad3ab12
yarn-add-D-morgan:
		docker compose exec web yarn add -D morgan @types/morgan

# Sqlite3
yarn-add-D-sqlite3:
	docker compose exec web yarn add -D sqlite3

# body-parser
yarn-add-D-bodyparser:
	docker compose exec web yarn add -D body-parser

# node-dev
# package.json
# {
#   "scripts": {
#     "start": "npx node-dev app/app.js"
# }
yarn-add-D-nodedev:
	docker compose exec web yarn add -D node-dev

# ==== Laravel Mix ====

# laravel-mix
# https://laravel-mix.com/docs/4.0/installation
# https://qiita.com/tokimeki40/items/2c9112272a8b92bbaef9
#
# v6:
# Development
# npx mix
# Production
# npm mix --production
# watch
# npx mix watch
# Hot Module Replacemen
# npx mix watch --hot
#
# v5:
# –progress:ビルドの進捗状況を表示させるオプション
# –hide-modules:モジュールについての情報を非表示にするオプション
# –config:Laravel Mixで利用するwebpack.config.jsの読み込み
# cross-env:環境依存を解消するためにインストールしたパッケージ
#
# package.json
# "scripts": {
#     "dev": "npm run development",
#     "development": "cross-env NODE_ENV=development node_modules/webpack/bin/webpack.js --progress --config=node_modules/laravel-mix/setup/webpack.config.js",
#     "watch": "npm run development -- --watch",
#     "hot": "cross-env NODE_ENV=development node_modules/webpack-dev-server/bin/webpack-dev-server.js --inline --hot --config=node_modules/laravel-mix/setup/webpack.config.js",
#     "prod": "npm run production",
#     "production": "cross-env NODE_ENV=production node_modules/webpack/bin/webpack.js --config=node_modules/laravel-mix/setup/webpack.config.js"
# }
yarn-add-D-mix:
	docker compose exec web yarn add -D laravel-mix glob cross-env rimraf

# webpack.mix.js
touch-mix:
	docker compose exec web touch webpack.mix.js

# laravel-mix-polyfill
# https://laravel-mix.com/extensions/polyfill
# IE11対応
yarn-add-D-mix-polyfill:
	docker compose exec web add yarn -D laravel-mix-polyfill

# laravel-mix-pug
# https://laravel-mix.com/extensions/pug-recursive
yarn-add-D-mix-pug:
	docker compose exec web yarn add -D laravel-mix-pug-recursive

# laravel-mix-ejs
# https://laravel-mix.com/extensions/ejs
yarn-add-D-mix-ejs:
	docker compose exec web yarn add -D laravel-mix-ejs

# ==== Composer関連 ====

comp-update:
	docker compose exec web composer update

# ==== PHPUnit関連 ====

comp-add-D-phpunit:
	docker compose exec web composer require phpunit/phpunit --dev

# ==== DBUnit関連 ====

# {
#     "require-dev": {
#         "phpunit/phpunit": "^5.7|^6.0",
#         "phpunit/dbunit": ">=1.2"
#     }
# }
#
# composer update

# ==== phpdotenv関連 ====

comp-add-D-phpdotenv:
	docker compose exec web composer require vlucas/phpdotenv

# ==== Monolog関連 ====

# https://reffect.co.jp/php/monolog-to-understand

comp-add-D-monolog:
	docker compose exec web composer require monolog/monolog

# ==== Laravel Collection =====
# https://github.com/illuminate/support

comp-add-D-laravel-collection:
	docker compose exec web composer require illuminate/support

# ==== MongoDB ====

comp-add-D-mongodb:
	docker compose exec web composer require "mongodb/mongodb"


# ==== Dockerコマンド群 ====

# Docker for Mac におけるディスク使用
# https://docs.docker.jp/docker-for-mac/space.html

# DockerでIPアドレスが足りなくなったとき
# docker network inspect $(docker network ls -q) | grep -E "Subnet|Name"
# docker network ls
# docker network rm ネットワーク名
# docker network prune
# https://docs.docker.jp/config/daemon/daemon.html
# daemon.json
# {
#   "experimental": false,
#   "default-address-pools": [
#       {"base":"172.16.0.0/12", "size":24}
#   ],
#   "builder": {
#     "gc": {
#       "enabled": true,
#       "defaultKeepStorage": "20GB"
#     }
#   },
#   "features": {
#     "buildkit": true
#   }
# }

# docker networkの削除ができない
# https://qiita.com/shundayo/items/8b24af5239d9162b253c
# error while removing network でDocker コンテナを終了できない時の対処
# https://sun0range.com/information-technology/docker-error-while-removing-network/#%E3%83%8D%E3%83%83%E3%83%88%E3%83%AF%E3%83%BC%E3%82%AF%E5%89%8A%E9%99%A4%E3%82%92%E8%A9%A6%E3%81%BF%E3%82%8B
#
# # ネットワーク検証
# docker network inspect ネットワーク名
# # network削除
# docker network rm ネットワーク名
# # 確認
# docker network ls


# ==== Linuxコマンド群 ====

# githubにアップされている画像の取り込み方法
# 1. 画像ファイルを開く
# 2. ダウンロードボタンをクリック
# 3. ダウンロード画面のURLをコピー
# 4. 適当なフォルダでwgetコマンドで取り込みむ
# 例) https://raw.githubusercontent.com/deatiger/ec-app-demo/develop/src/assets/img/src/no_image.png
# wget <URL>
