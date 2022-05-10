const defaultTheme = require("tailwindcss/defaultTheme");
const colors = require("tailwindcss/colors");

const customColors = {
  transparent: "transparent",
  current: "currentColor",
  black: colors.black,
  white: colors.white,
  gray: colors.gray,
  blue: colors.blue,
  indigo: colors.indigo,
  red: colors.red,
  green: colors.green,
  yellow: colors.yellow,
  brand: {
    DEFAULT: "var(--primary-color)",
    hover: "var(--primary-hover)",
    active: "var(--primary-active)",
    background: "var(--background)",
    dark: "var(--primary-dark)",
    grey: "#e0e0e0",
    50: "var(--primary-50)",
    100: "var(--primary-100)",
    200: "var(--primary-200)",
    300: "var(--primary-300)",
    400: "var(--primary-400)",
    500: "var(--primary-500)",
    600: "var(--primary-600)",
    700: "var(--primary-700)",
    800: "var(--primary-800)",
    900: "var(--primary-900)",
  },
  secondary: {
    DEFAULT: "#f5a48b",
    hover: "#d8e5e6",
    active: "#e3eeee",
    50: "#fdede8",
    100: "#fce5de",
    200: "#fbd6cb",
    300: "#f9c4b4",
    400: "#f7b5a1",
    500: "#f5a38a",
    600: "#f07651",
    700: "#ec4e1e",
    800: "#bc3810",
    900: "#83270b",
  },
};

module.exports = {
  mode: "jit",
  purge: [
    __dirname + "/src/**/*.purs",
  ],
  theme: {
    colors: customColors,
    backgroundColors: customColors,
  },
};
