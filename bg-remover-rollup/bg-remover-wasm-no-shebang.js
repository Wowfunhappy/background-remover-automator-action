// Override require to use our wrappers
const Module = require('module');
const originalRequire = Module.prototype.require;

Module.prototype.require = function(id) {
  if (id === 'sharp') {
    return require('./sharp-mock.js');
  }
  if (id === 'onnxruntime-node') {
    return require('./onnx-web-wrapper.js');
  }
  return originalRequire.apply(this, arguments);
};

// Polyfill Blob for Node.js if not available
if (!global.Blob) {
  global.Blob = require('buffer').Blob;
}

// Set WASM paths if provided
if (process.env.ONNX_WASM_PATHS) {
  process.env.ORT_WASM_PATHS = process.env.ONNX_WASM_PATHS;
}

// Run the CLI
require('./cli-no-shebang.js');