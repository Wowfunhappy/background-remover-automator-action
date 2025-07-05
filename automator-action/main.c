#include <stdlib.h>
#include <unistd.h>
#include <string.h>

int main(int argc, char *argv[]) {
    // Get the path to this executable
    char path[1024];
    char *last_slash;
    
    if (readlink("/proc/self/exe", path, sizeof(path)-1) == -1) {
        // Fallback for macOS
        strncpy(path, argv[0], sizeof(path)-1);
    }
    
    // Find the directory containing this executable
    last_slash = strrchr(path, '/');
    if (last_slash != NULL) {
        *last_slash = '\0';
    }
    
    // Build path to the shell script
    strcat(path, "/../Resources/main.sh");
    
    // Build new argv with shell script
    char **new_argv = malloc(sizeof(char*) * (argc + 2));
    new_argv[0] = "/bin/bash";
    new_argv[1] = path;
    
    // Copy original arguments
    for (int i = 1; i < argc; i++) {
        new_argv[i + 1] = argv[i];
    }
    new_argv[argc + 1] = NULL;
    
    // Execute the shell script
    execv("/bin/bash", new_argv);
    
    // If we get here, exec failed
    return 1;
}