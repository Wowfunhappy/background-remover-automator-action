#include <stdlib.h>
#include <stdint.h>

// Shim for CCRandomGenerateBytes
// This function is normally provided by CommonCrypto framework
// We'll use arc4random_buf as a fallback
int CCRandomGenerateBytes(void *bytes, size_t count) {
    arc4random_buf(bytes, count);
    return 0; // Success
}