const { nodeResolve } = require('@rollup/plugin-node-resolve');
const commonjs = require('@rollup/plugin-commonjs');
const json = require('@rollup/plugin-json');
const path = require('path');

module.exports = {
  input: 'bg-remover-rollup/bg-remover-wasm-no-shebang.js',
  output: {
    file: 'bg-remover-rollup/bundle.js',
    format: 'cjs',
    inlineDynamicImports: true
  },
  external: [
    // Only exclude Node.js built-ins
    'fs', 'path', 'os', 'crypto', 'buffer', 'util', 'stream', 
    'events', 'url', 'querystring', 'child_process', 'http', 
    'https', 'net', 'tls', 'assert', 'tty', 'zlib', 'constants',
    'worker_threads', 'perf_hooks', 'module', 'fs/promises', 
    'readline', 'node:path', 'node:fs', 'node:url', 'node:os',
    // External modules that can't be bundled
    'jimp', '@jimp/custom', '@jimp/plugins', '@jimp/types',
    '@jimp/plugin-resize', '@jimp/plugin-blit', '@jimp/plugin-rotate',
    '@jimp/plugin-color', '@jimp/plugin-contain', '@jimp/plugin-cover',
    '@jimp/plugin-crop', '@jimp/plugin-displace', '@jimp/plugin-dither',
    '@jimp/plugin-flip', '@jimp/plugin-gaussian', '@jimp/plugin-invert',
    '@jimp/plugin-mask', '@jimp/plugin-normalize', '@jimp/plugin-print',
    '@jimp/plugin-blur', '@jimp/plugin-circle', '@jimp/plugin-shadow',
    '@jimp/plugin-fisheye', '@jimp/plugin-scale', '@jimp/plugin-threshold',
    '@jimp/core', '@jimp/utils',
    '@jimp/bmp', '@jimp/gif', '@jimp/jpeg', '@jimp/png', '@jimp/tiff'
  ],
  plugins: [
    {
      name: 'override-modules',
      resolveId(source, importer) {
        if (source === 'sharp') {
          return path.resolve(__dirname, 'bg-remover-rollup/sharp-mock.js');
        }
        if (source === 'onnxruntime-node') {
          return path.resolve(__dirname, 'bg-remover-rollup/onnx-web-wrapper.js');
        }
        // Force Rollup to bundle jimp
        if (source === 'jimp' && importer) {
          return null; // Let default resolution handle it
        }
        return null;
      }
    },
    nodeResolve({
      preferBuiltins: false,
      browser: false,
      exportConditions: ['node'],
      rootDir: process.cwd()
    }),
    commonjs({
      ignoreDynamicRequires: false,
      dynamicRequireTargets: [
        'bg-remover-standalone/node_modules/**/*.js'
      ]
    }),
    json()
  ],
  onwarn(warning, warn) {
    // Ignore circular dependency warnings
    if (warning.code === 'CIRCULAR_DEPENDENCY') return;
    warn(warning);
  }
};