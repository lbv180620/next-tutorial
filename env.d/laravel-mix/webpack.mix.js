const mix = require('laravel-mix');
const glob = require('glob');
require('laravel-mix-polyfill');
// const path = require('path');

// paths
const srcDir = './src';
const distDir = './public';
const paths = {
    html: {
        src: `${srcDir}/templates/`,
        dist: `${distDir}/`,
    },
    css: {
        src: `${srcDir}/styles/`,
        dist: `${distDir}/styles/`,
    },
    js: {
        src: `${srcDir}/scripts/`,
        dist: `${distDir}/scripts/`,
    },
};

mix
    .setPublicPath(distDir)
    .browserSync({
        files: 'dist/**/*',
        server: 'dist/',
        proxy: false
    })
    .disableSuccessNotifications()
    .pug = require('laravel-mix-pug');

// JS
glob.sync(`${paths.js.src}*.js`).map(file => {
    mix.js(file, `${paths.js.dist}bundle.js`)
        .polyfill({
            enabled: true,
            useBuiltIns: "usage",
            targets: {
                "firefox": "50",
                "ie": 11
            }
        })
        .sourceMaps();
});

// Sass
glob.sync(`${paths.css.src}*.scss`, { ignore: `${paths.css.src}_*.scss` }).map((file) => {
    mix.sass(file, paths.css.dist, {})
        .sourceMaps();
});

// Pug
// glob.sync(`${paths.html.src}*.pug`, { ignore: `${paths.html.src}_*.pug` }).map((file) => {
//     mix.pug(file, path.relative(paths.html.src, paths.html.dist), {
//         pug: {
//             pretty: true
//         }
//     })
//         .sourceMaps()
// });
