const { merge } = require('webpack-merge');
const common = require('./webpack.common');
const BrowserSyncPlugin = require('browser-sync-webpack-plugin');
const path = require('path');

const outputFile = '[name].bundle';
const assetFile = '[name]';

const getEntriesPlugin = require('./webpack/utils/getEntriesPlugin');
const entries = getEntriesPlugin();
const htmlGlobPlugin = require('./webpack/utils/htmlGlobPlugin');

module.exports = () => merge(common({ outputFile, assetFile }), {
    mode: 'development',
    // https://webpack.js.org/configuration/devtool/
    devtool: 'source-map',
    watch: true,
    watchOptions: {
        ignored: ['node_modules/**']
    },
    plugins: [
        new BrowserSyncPlugin({
            host: 'localhost',
            port: 2000,
            proxy: 'http://localhost:8080',
            open: false
        }),
        ...htmlGlobPlugin(entries, ...[path.join(__dirname, 'src/templates'), path.join(__dirname, 'public/views'), 'php', 'php'])
    ]
});
