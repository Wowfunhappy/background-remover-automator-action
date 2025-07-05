// Mock sharp module using Jimp
const Jimp = require('jimp');

class SharpMock {
  constructor(input) {
    this.input = input;
    this.operations = [];
  }

  metadata() {
    return new Promise(async (resolve, reject) => {
      try {
        const image = await Jimp.read(this.input);
        // Determine format from image mime type
        let format = 'png';
        if (image._originalMime === Jimp.MIME_JPEG) {
          format = 'jpeg';
        } else if (image._originalMime && image._originalMime.includes('webp')) {
          format = 'webp';
        }
        
        resolve({
          width: image.bitmap.width,
          height: image.bitmap.height,
          channels: image.hasAlpha() ? 4 : 3,
          format: format,
          space: 'srgb',
          depth: 'uchar',
          density: 72,
          chromaSubsampling: '4:2:0',
          isProgressive: false,
          hasProfile: false,
          hasAlpha: image.hasAlpha()
        });
      } catch (error) {
        reject(error);
      }
    });
  }

  ensureAlpha() {
    this.operations.push('ensureAlpha');
    return this;
  }

  raw() {
    this.operations.push('raw');
    return this;
  }

  toFormat(format, options = {}) {
    this.operations.push({ action: 'toFormat', format, options });
    return this;
  }

  async toBuffer() {
    try {
      const image = await Jimp.read(this.input);
      
      // Handle raw output
      if (this.operations.includes('raw')) {
        // Return raw RGBA buffer
        const buffer = Buffer.alloc(image.bitmap.width * image.bitmap.height * 4);
        for (let i = 0; i < image.bitmap.data.length; i++) {
          buffer[i] = image.bitmap.data[i];
        }
        return buffer;
      }
      
      // Handle format conversion
      const formatOp = this.operations.find(op => op.action === 'toFormat');
      if (formatOp) {
        const { format, options } = formatOp;
        let mime;
        
        switch(format) {
          case 'png':
            mime = Jimp.MIME_PNG;
            break;
          case 'jpeg':
          case 'jpg':
            mime = Jimp.MIME_JPEG;
            if (options.quality) {
              image.quality(options.quality);
            }
            break;
          default:
            mime = Jimp.MIME_PNG;
        }
        
        return await image.getBufferAsync(mime);
      }
      
      // Default to PNG
      return await image.getBufferAsync(Jimp.MIME_PNG);
      
    } catch (error) {
      throw error;
    }
  }
}

// Factory function that mimics sharp's API
function sharp(input, options = {}) {
  if (options.raw) {
    // Handle raw pixel data input
    const { width, height, channels } = options.raw;
    const jimp = new Jimp(width, height);
    
    // Copy pixel data
    const data = Buffer.from(input);
    for (let i = 0; i < data.length; i++) {
      jimp.bitmap.data[i] = data[i];
    }
    
    return {
      toFormat: (format, opts = {}) => ({
        toBuffer: async () => {
          let mime;
          switch(format) {
            case 'png':
              mime = Jimp.MIME_PNG;
              break;
            case 'jpeg':
            case 'jpg':
              mime = Jimp.MIME_JPEG;
              if (opts.quality) {
                jimp.quality(opts.quality);
              }
              break;
            default:
              mime = Jimp.MIME_PNG;
          }
          return await jimp.getBufferAsync(mime);
        }
      })
    };
  }
  
  return new SharpMock(input);
}

// Export versions info
sharp.versions = () => Promise.resolve({
  vips: '8.14.5-mock',
  sharp: '0.32.4-mock'
});

module.exports = sharp;