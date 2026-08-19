const { jestConfig } = require("@salesforce/sfdx-lwc-jest/config");

const setupFilesAfterEnv = jestConfig.setupFilesAfterEnv || [];

module.exports = {
  ...jestConfig,
  setupFilesAfterEnv: [...setupFilesAfterEnv, "<rootDir>/jest-sa11y-setup.js"],
  modulePathIgnorePatterns: ["<rootDir>/.localdevserver"]
};
