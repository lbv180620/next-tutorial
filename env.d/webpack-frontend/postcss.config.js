module.exports = (ctx) => {
    return {
        // map: ctx.options.map,
        plugins: [
            require('tailwindcss'),
            require('autoprefixer'),
        ]
    }
};
