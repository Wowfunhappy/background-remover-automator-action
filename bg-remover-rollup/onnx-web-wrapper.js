// Wrapper to replace onnxruntime-node with onnxruntime-web
const ort = require('onnxruntime-web');

// Set up WebAssembly backend
ort.env.wasm.numThreads = 1; // Single thread for compatibility
ort.env.wasm.simd = false; // Disable SIMD for better compatibility

// Create a compatibility layer that mimics onnxruntime-node API
const InferenceSession = {
  create: async (modelPath, options) => {
    // If modelPath is a file:// URL, we need to read it
    if (typeof modelPath === 'string' && modelPath.startsWith('file://')) {
      const fs = require('fs').promises;
      const path = require('path');
      const filePath = modelPath.replace('file://', '');
      const modelBuffer = await fs.readFile(filePath);
      return await ort.InferenceSession.create(modelBuffer, options);
    }
    return await ort.InferenceSession.create(modelPath, options);
  }
};

// Export compatibility layer
module.exports = {
  InferenceSession,
  Tensor: ort.Tensor,
  env: ort.env
};