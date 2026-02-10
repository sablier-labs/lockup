/**
 * @notice Lint CIs run from within the protocol directories. So, prettier needs to resolve devkit from the protocol's
 * node_modules folder.
 */
function resolveDevkit() {
  try {
    return require("@sablier/devkit/.prettierrc.json");
  } catch {
    for (const pkg of ["airdrops", "bob", "flow", "lockup", "utils"]) {
      try {
        return require(`./${pkg}/node_modules/@sablier/devkit/.prettierrc.json`);
      } catch {}
    }
  }
}

const baseConfig = resolveDevkit();

/**
 * @see https://prettier.io/docs/configuration
 * @type {import("prettier").Config}
 */
const config = {
  ...baseConfig,
  overrides: [
    ...(baseConfig.overrides || []),
    {
      files: "*.svg",
      options: {
        parser: "html",
      },
    },
  ],
};

module.exports = config;
