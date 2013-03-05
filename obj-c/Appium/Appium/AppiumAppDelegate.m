//
//  AppiumAppDelegate.m
//  Appium
//
//  Created by Dan Cuellar on 3/3/13.
//  Copyright (c) 2013 Appium. All rights reserved.
//

#import "AppiumAppDelegate.h"
#import "NodeInstance.h"
#import "AppiumInstallationWindowController.h"

@implementation AppiumAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // install settings from plist
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"];
	NSDictionary *settingsDict = [NSDictionary dictionaryWithContentsOfFile:filePath];
	[[NSUserDefaults standardUserDefaults] registerDefaults:settingsDict];
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:settingsDict];
    
    // create main monitor window
    [self setMainWindowController:[[AppiumMonitorWindowController alloc] initWithWindowNibName:@"AppiumMonitorWindow"]];

    // install anything that's missing
    [self performSelectorInBackground:@selector(install) withObject:nil];
    
}

-(void) install
{
    // check is nodejs, appium, or appium pre-reqs are missing
    NSString *nodeRootPath = [[NSBundle mainBundle] resourcePath];
    BOOL installationRequired = ![NodeInstance instanceExistsAtPath:nodeRootPath];
    installationRequired |= ![NodeInstance packageIsInstalledAtPath:nodeRootPath withName:@"appium"];
    installationRequired |= ![NodeInstance packageIsInstalledAtPath:nodeRootPath withName:@"argparse"];
    
    if (installationRequired)
    {
        // install software
        AppiumInstallationWindowController *installationWindow = [[AppiumInstallationWindowController alloc] initWithWindowNibName:@"AppiumInstallationWindow"];
        [installationWindow performSelectorOnMainThread:@selector(showWindow:) withObject:self waitUntilDone:YES];
        [[installationWindow window] performSelectorOnMainThread:@selector(makeKeyAndOrderFront:) withObject:self waitUntilDone:YES];
        [[installationWindow messageLabel] performSelectorOnMainThread:@selector(setStringValue:) withObject:@"Installing NodeJS..." waitUntilDone:YES];
        [[self mainWindowController] setNode:[[NodeInstance alloc] initWithPath:nodeRootPath]];
        [[installationWindow messageLabel] performSelectorOnMainThread:@selector(setStringValue:) withObject:@"Installing Appium Prerequisites..." waitUntilDone:YES];
        [[[self mainWindowController] node] installPackage:@"argparse"];
        [[installationWindow messageLabel] performSelectorOnMainThread:@selector(setStringValue:) withObject:@"Installing Appium..." waitUntilDone:YES];
        [[[self mainWindowController] node] installPackage:@"appium"];
        [[installationWindow window] performSelectorOnMainThread:@selector(close) withObject:nil waitUntilDone:YES];
    }
    else
    {
        // create node instance
        [[self mainWindowController] setNode:[[NodeInstance alloc] initWithPath:nodeRootPath]];
    }
    
    // show main monitor window
    [[self mainWindowController] performSelectorOnMainThread:@selector(showWindow:) withObject:self waitUntilDone:YES];
    [[[self mainWindowController] window] performSelectorOnMainThread:@selector(makeKeyAndOrderFront:) withObject:self waitUntilDone:YES];

    // check for updates
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"Check For Updates"])
    {
        [[self mainWindowController] performSelectorInBackground:@selector(checkForUpdates) withObject:nil];
    }
}

-(void) restart
{
    NSTask *restartTask = [NSTask new];
    [restartTask setLaunchPath:@"/bin/sh"];
    [restartTask setArguments:[NSArray arrayWithObjects: @"-c",[NSString stringWithFormat:@"sleep 2; open \"%@\"", [[NSBundle mainBundle] bundlePath] ], nil]];
    [restartTask launch];
    [[NSApplication sharedApplication] terminate:nil];
}

-(void)applicationWillTerminate:(NSNotification *)notification
{
    [[self mainWindowController] killServer];
}

@end
