#!/usr/bin/env node

const { removeBackground, removeForeground, segmentForeground } = require('@imgly/background-removal-node');
const { program } = require('commander');
const chalk = require('chalk');
const ora = require('ora');
const fs = require('fs').promises;
const path = require('path');

// Polyfill Blob for Node.js if not available
if (!global.Blob) {
  global.Blob = require('buffer').Blob;
}

program
  .name('bg-remover')
  .description('CLI tool for removing backgrounds from images')
  .version('1.0.0')
  .requiredOption('-i, --input <path>', 'input image file path')
  .requiredOption('-o, --output <path>', 'output image file path')
  .option('-m, --model <type>', 'model to use: small, medium, or large', 'medium')
  .option('-f, --format <format>', 'output format: png, jpeg, or webp', 'png')
  .option('-q, --quality <value>', 'output quality (0-1)', '0.9')
  .option('--remove-foreground', 'remove foreground instead of background')
  .option('--segment-only', 'output segmentation mask only')
  .option('--debug', 'enable debug mode')
  .parse(process.argv);

const options = program.opts();

// Map model names to internal names
const modelMap = {
  'small': 'isnet_quint8',
  'medium': 'isnet_fp16',
  'large': 'isnet'
};

// Map format names to MIME types
const formatMap = {
  'png': 'image/png',
  'jpeg': 'image/jpeg',
  'jpg': 'image/jpeg',
  'webp': 'image/webp'
};

async function main() {
  const spinner = ora('Processing image...').start();
  
  try {
    // Validate input file exists
    try {
      await fs.access(options.input);
    } catch (error) {
      throw new Error(`Input file not found: ${options.input}`);
    }

    // Read input file
    const imageBuffer = await fs.readFile(options.input);
    
    // Determine MIME type from file extension
    const ext = path.extname(options.input).toLowerCase();
    let mimeType = 'image/png';
    if (ext === '.jpg' || ext === '.jpeg') {
      mimeType = 'image/jpeg';
    } else if (ext === '.webp') {
      mimeType = 'image/webp';
    }
    
    // Create a proper Blob with MIME type
    const imageBlob = new Blob([imageBuffer], { type: mimeType });
    
    // Prepare configuration
    const config = {
      publicPath: process.env.IMGLY_PUBLIC_PATH || `file://${__dirname}/node_modules/@imgly/background-removal-node/dist/`,
      debug: options.debug,
      model: options.model || 'medium', // Use the string directly, not the mapped value
      output: {
        format: formatMap[options.format] || 'image/png',
        quality: parseFloat(options.quality)
      },
      progress: (key, current, total) => {
        const percent = Math.round((current / total) * 100);
        spinner.text = `${key}: ${percent}%`;
      }
    };

    // Process image based on mode
    let resultBlob;
    if (options.removeBackground) {
      spinner.text = 'Removing foreground...';
      resultBlob = await removeForeground(imageBlob, config);
    } else if (options.segmentOnly) {
      spinner.text = 'Generating segmentation mask...';
      resultBlob = await segmentForeground(imageBlob, config);
    } else {
      spinner.text = 'Removing background...';
      resultBlob = await removeBackground(imageBlob, config);
    }

    // Convert blob to buffer
    const arrayBuffer = await resultBlob.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);

    // Ensure output directory exists
    const outputDir = path.dirname(options.output);
    await fs.mkdir(outputDir, { recursive: true });

    // Write output file
    await fs.writeFile(options.output, buffer);
    
    spinner.succeed(chalk.green(`✓ Image processed successfully!`));
    console.log(chalk.blue(`Output saved to: ${options.output}`));
    console.log(chalk.gray(`Size: ${(buffer.length / 1024).toFixed(2)} KB`));
    
  } catch (error) {
    spinner.fail(chalk.red('Processing failed'));
    console.error(chalk.red('Error:'), error.message);
    if (options.debug) {
      console.error(error.stack);
    }
    process.exit(1);
  }
}

// Handle uncaught errors
process.on('unhandledRejection', (error) => {
  console.error(chalk.red('Unhandled error:'), error);
  process.exit(1);
});

main();