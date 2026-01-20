/**
 * @type {import("lint-staged").Configuration}
 */
module.exports = {
  "*.{json,svg,yml}": "bun prettier --cache --write",
  "*.md": "mdformat",
  "*.sol": () => "just full-write-all",
};
