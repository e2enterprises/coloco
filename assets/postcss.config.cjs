// References for PostCSS setup:
// https://github.com/SteffenDE/phx_colocated_postcss_example/commit/9ec8372b7708f64217b7e38ab98fbd37ed8774a1
// https://github.com/phoenixframework/phoenix_live_view/pull/4149
// https://github.com/phoenixframework/phoenix_live_view/pull/4138

const path = require("path")

module.exports = {
  plugins: [
    require("postcss-import")({ path: process.env.NODE_PATH.split(path.delimiter) }),
    require("@tailwindcss/postcss"),
    require("postcss-nesting"),
    require("autoprefixer"),
  ],
}
