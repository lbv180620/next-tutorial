// v3
// module.exports = {
//     mode: "jit",
//     content: ["./src/**/*.{js,jsx,ts,tsx}", "./public/**/*.{js,jsx,ts,tsx}"],
//     darkMode: 'media', // or 'media' or 'class'
//     theme: {
//         extend: {},
//     },
//     variants: {
//         extend: {},
//     },
//     plugins: [],
// }

// v2
module.exports = {
    mode: "jit",
    purge: ["./src/**/*.{js,jsx,ts,tsx,php}", "./public/**/*.{js,jsx,ts,tsx}"],
    darkMode: false, // or 'media' or 'class'
    theme: {
        extend: {},
    },
    variants: {
        extend: {},
    },
    plugins: [],
}
