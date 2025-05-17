const {
  defineConfig,
  globalIgnores,
} = require("eslint/config");

const globals = require("globals");

const {
  fixupConfigRules,
  fixupPluginRules,
} = require("@eslint/compat");

const tsParser = require("@typescript-eslint/parser");
const typescriptEslint = require("@typescript-eslint/eslint-plugin");
const _import = require("eslint-plugin-import");
const js = require("@eslint/js");

const {
  FlatCompat,
} = require("@eslint/eslintrc");

const compat = new FlatCompat({
  baseDirectory: __dirname,
  recommendedConfig: js.configs.recommended,
  allConfig: js.configs.all
});

module.exports = defineConfig([{
  languageOptions: {
    globals: {
      ...globals.node,
    },

    parser: tsParser,
    sourceType: "module",

    parserOptions: {
      project: ["tsconfig.json", "tsconfig.dev.json"],
    },
  },

  extends: fixupConfigRules(compat.extends(
    "eslint:recommended",
    "plugin:import/errors",
    "plugin:import/warnings",
    "plugin:import/typescript",
    // "google",
    "plugin:@typescript-eslint/recommended",
  )),

  plugins: {
    "@typescript-eslint": fixupPluginRules(typescriptEslint),
    import: fixupPluginRules(_import),
  },

  rules: {
    // "quotes": ["error", "double"],
    "import/no-unresolved": 0,
    "indent": ["error", 2],

    "@typescript-eslint/no-unused-vars": ["error", {
      varsIgnorePattern: "^_",
      argsIgnorePattern: "^_",
    }],
  },
}, globalIgnores([
  "lib/**/*", // Ignore built files.
  "generated/**/*" // Ignore generated files.
])]);
