const path = require('path');
const getEntriesPlugin = require('./webpack/utils/getEntriesPlugin.js');
const entries = getEntriesPlugin();

const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const { ProvidePlugin } = require('webpack');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const ForkTsCheckerPlugin = require('fork-ts-checker-webpack-plugin');
const Dotenv = require('dotenv-webpack');

console.log(entries);

module.exports = ({ outputFile, assetFile, distPath, publicPath }) => ({
    context: path.join(__dirname, 'src'),
    entry: entries,
    output: {
        path: path.join(__dirname, `${distPath}/static`),
        publicPath: `${publicPath}/static`,
        filename: `js/${outputFile}.js`,
        chunkFilename: `js/chunks/async/${outputFile}.js`
    },
    module: {
        rules: [
            {
                test: /\.(js|jsx)$/,
                exclude: /node_modules/,
                loader: 'babel-loader'
            },
            {
                test: /\.(ts|tsx)$/,
                exclude: /node_modules/,
                use: [
                    'babel-loader',
                    {
                        loader: 'ts-loader',
                        options: {
                            transpileOnly: true,
                        }
                    }
                ]
            },
            {
                test: /\.(sa|sc|c)ss$/i,
                use: [
                    MiniCssExtractPlugin.loader,
                    {
                        loader: 'css-loader',
                        options: {
                            url: true
                        }
                    },
                    'postcss-loader',
                    {
                        loader: 'sass-loader',
                        options: {
                            implementation: require('sass')
                        }
                    }
                ]
            },
            {
                test: /\.(jpe?g|gif|png|svg|woff2?|ttf|eot)$/i,
                generator: {
                    filename: `./images/${assetFile}[ext]`,
                },
                type: 'asset',
                parser: {
                    dataUrlCondition: {
                        maxSize: 1 * 1024
                    }
                }
            },
            {
                test: /\.(html|php)$/i,
                loader: 'html-loader'
            }
        ]
    },
    // ES5(IE11等)向けの指定（webpack 5以上で必要）
    target: ["web", "es5"],
    plugins: [
        new MiniCssExtractPlugin({
            filename: `css/${outputFile}.css`,
            chunkFilename: `css/chunks/async/${outputFile}.css`
        }),

        new ProvidePlugin({
            jQuery: 'jquery',
            $: 'jquery'
        }),

        new CopyWebpackPlugin({
            patterns: [
                {
                    from: path.join(__dirname, 'src/templates/components'),
                    to: path.join(__dirname, `${distPath}/views/components`),
                    noErrorOnMissing: true
                }
            ]
        }),

        new ForkTsCheckerPlugin({
            typescript: {
                configFile: path.resolve(__dirname, 'tsconfig.json'),
            },
            async: false
        }),
        
        new Dotenv(),
    ],
    resolve: {
        alias: {
            '@scss': path.resolve(__dirname, 'src/styles/scss/'),
            '@images': path.resolve(__dirname, 'src/images/')
        },
        extensions: ['.js', '.jsx', '.ts', '.tsx', '.scss', 'module.scss'],
        modules: [path.resolve(__dirname, 'src'), "node_modules"]
    },
    performance: {
        maxEntrypointSize: 500000,
        maxAssetSize: 500000,
    },
    optimization: {
        // https://webpack.js.org/plugins/split-chunks-plugin/#split-chunks-example-2
        splitChunks: {
            chunks: 'all',
            minSize: 0,
            cacheGroups: {
                vendors: {
                    name: "vendors",
                    test: /node_modules/,
                    priority: -10
                },
                syncModules: {
                    name: "chunks/syncModules",
                    test: /src[\\/]scripts[\\/].*[\\/]_.+\.(js|jsx|ts|tsx)$/,
                    chunks: 'initial'
                },
                asyncModules: {
                    name: "asyncModules",
                    test: /src[\\/]scripts[\\/].*[\\/]_.+\.(js|jsx|ts|tsx)$/,
                    chunks: 'async'
                },
                mainStyles: {
                    name: "chunks/mainStyles",
                    test: /src[\\/]styles[\\/]scss[\\/]@main.scss$/,
                    chunks: 'initial'
                },
                appStyles: {
                    name: "chunks/appStyles",
                    test: /src[\\/]styles[\\/]scss[\\/]@app.scss$/,
                    chunks: 'initial'
                },
                indexStyles: {
                    name: "chunks/indexStyles",
                    test: /src[\\/]styles[\\/]scss[\\/]@index.scss$/,
                    chunks: 'initial'
                },
                bootstrapStyles: {
                    name: "chunks/bootstrapStyles",
                    test: /src[\\/]styles[\\/]scss[\\/]bootstrap.scss$/,
                    chunks: 'initial'
                },
                tailwindStyles: {
                    name: "chunks/tailwindStyles",
                    test: /src[\\/]styles[\\/]scss[\\/]tailwind.scss$/,
                    chunks: 'initial'
                },
                asyncStyles: {
                    name: "asyncStyles",
                    test: /src[\\/]styles[\\/]/,
                    chunks: 'async'
                }
            }
        }
    }
});
