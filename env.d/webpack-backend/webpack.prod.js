const TerserPlugin = require('terser-webpack-plugin');
const CssMinimizerPlugin = require('css-minimizer-webpack-plugin');

const path = require('path');
const { merge } = require('webpack-merge');
const common = require('./webpack.common');

const outputFile = '[name].[chunkhash]';
const assetFile = '[contenthash]';

const getEntriesPlugin = require('./webpack/utils/getEntriesPlugin');
const entries = getEntriesPlugin();
const htmlGlobMinifyPlugin = require('./webpack/utils/htmlGlobMinifyPlugin');

module.exports = (env, argv) => {

    const isProd = argv.mode === "production";
    if (isProd) {
        process.env.NODE_ENV = "production";
    }

    return merge(common({ outputFile, assetFile }), {
        // mode: 'production',

        plugins: [
            ...htmlGlobMinifyPlugin(entries, ...[path.join(__dirname, 'src/templates'), path.join(__dirname, 'public/views'), 'php', 'php'])
        ],

        optimization: {
            minimizer: [
                new TerserPlugin(),
                new CssMinimizerPlugin()
            ]
        }
    });
};
