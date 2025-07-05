#import <Foundation/Foundation.h>
#import <Automator/Automator.h>

@interface RemoveImageBackground : AMBundleAction
@end

@implementation RemoveImageBackground

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo
{
    NSBundle *bundle = [self bundle];
    NSString *scriptPath = [bundle pathForResource:@"main" ofType:@"sh"];
    
    if (!scriptPath) {
        if (errorInfo) {
            *errorInfo = @{
                NSAppleScriptErrorMessage: @"Could not find main.sh script",
                NSAppleScriptErrorNumber: @1
            };
        }
        return nil;
    }
    
    NSMutableArray *arguments = [NSMutableArray arrayWithObject:scriptPath];
    [arguments addObjectsFromArray:input];
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/bash"];
    [task setArguments:arguments];
    
    NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
    
    NSPipe *errorPipe = [NSPipe pipe];
    [task setStandardError:errorPipe];
    
    [task launch];
    [task waitUntilExit];
    
    if ([task terminationStatus] != 0) {
        NSData *errorData = [[errorPipe fileHandleForReading] readDataToEndOfFile];
        NSString *errorString = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
        
        if (errorInfo) {
            *errorInfo = @{
                NSAppleScriptErrorMessage: errorString ?: @"Unknown error",
                NSAppleScriptErrorNumber: @([task terminationStatus])
            };
        }
        [errorString release];
        [task release];
        return nil;
    }
    
    NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    
    NSArray *outputPaths = [outputString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray *results = [NSMutableArray array];
    
    for (NSString *path in outputPaths) {
        NSString *trimmedPath = [path stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([trimmedPath length] > 0 && [trimmedPath hasPrefix:@"/"]) {
            [results addObject:trimmedPath];
        }
    }
    
    [outputString release];
    [task release];
    
    return results;
}

@end