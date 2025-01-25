// jest.config.js
module.exports = {
  transform: {
    "^.+\\.js$": "babel-jest",
  },
  moduleFileExtensions: ["js", "jsx", "ts", "tsx"],
  testEnvironment: "jsdom", // Simulate a browser environment for DOM testing
  setupFilesAfterEnv: ["@testing-library/jest-dom"],
  testPathIgnorePatterns: ["/node_modules/", "/public/"],
  moduleNameMapper: {
    "rails-ujs": "<rootDir>/test/dummy_modules/rails-ujs.js", // Mock rails-ujs
  },
};
