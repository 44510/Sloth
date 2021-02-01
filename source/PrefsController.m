/*
    Copyright (c) 2004-2021, Sveinbjorn Thordarson <sveinbjorn@sveinbjorn.org>
    All rights reserved.

    Redistribution and use in source and binary forms, with or without modification,
    are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice, this
    list of conditions and the following disclaimer in the documentation and/or other
    materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its contributors may
    be used to endorse or promote products derived from this software without specific
    prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
    IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
    INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
    NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
    PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
    WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/

#import "Common.h"
#import "PrefsController.h"
#import "IconUtils.h"

@interface PrefsController ()
{
    NSMutableArray *filters;
}
@property (weak) IBOutlet NSTableView *filtersTableView;
@property (weak) IBOutlet NSButton *removeFilterButton;
@property (weak) IBOutlet NSButton *addFilterButton;

@end

@implementation PrefsController

- (void)windowDidLoad {
    [super windowDidLoad];
    NSImage *img = [IconUtils imageNamed:@"Prefs"];
    if (img) {
        [self.window setRepresentedURL:[NSURL URLWithString:@""]]; // Not representing a URL
        [[self.window standardWindowButton:NSWindowDocumentIconButton] setImage:img];
    }
    filters = [NSMutableArray new];
    for (NSArray *a in [DEFAULTS objectForKey:@"filters"]) {
        [filters addObject:[a mutableCopy]];
    }
    [self updateButtonStatus];
}

- (BOOL)window:(NSWindow *)window shouldPopUpDocumentPathMenu:(NSMenu *)menu {
    // Prevent popup menu when window icon/title is cmd-clicked
    return NO;
}

- (BOOL)window:(NSWindow *)window shouldDragDocumentWithEvent:(NSEvent *)event from:(NSPoint)dragImageLocation withPasteboard:(NSPasteboard *)pasteboard {
    // Prevent dragging of title bar icon
    return NO;
}

- (IBAction)restoreDefaults:(id)sender {
    [DEFAULTS setBool:NO forKey:@"dnsLookup"];
    [DEFAULTS setBool:NO forKey:@"showProcessBinaries"];
    [DEFAULTS setBool:NO forKey:@"showCurrentWorkingDirectories"];
    [DEFAULTS setBool:YES forKey:@"friendlyProcessNames"];
    [DEFAULTS setBool:NO forKey:@"authenticateOnLaunch"];
    [DEFAULTS setObject:@[@[@NO, @"*\\.metallib"]] forKey:@"filters"];
    [DEFAULTS synchronize];
    filters = [[DEFAULTS objectForKey:@"filters"] mutableCopy];
    [self.filtersTableView reloadData];
}

- (IBAction)addFilter:(id)sender {
    [filters addObject:[@[@YES, @"Regex"] mutableCopy]];
    [self saveFilters];
    [self.filtersTableView reloadData];
    [self.filtersTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[filters count] -1] byExtendingSelection:NO];
}

- (IBAction)removeFilter:(id)sender {
    NSInteger selected =  [self.filtersTableView selectedRow];
    if (selected != -1 && selected < [filters count]) {
        [filters removeObjectAtIndex:selected];
    }
    [self saveFilters];
    [self.filtersTableView reloadData];
    [self updateButtonStatus];
}

- (void)saveFilters {
    [DEFAULTS setObject:filters forKey:@"filters"];
    [DEFAULTS synchronize];
}

- (void)updateButtonStatus {
    BOOL hasSelection = ([[self.filtersTableView selectedRowIndexes] count] > 0);
    [self.removeFilterButton setEnabled:hasSelection];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [filters count];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)value forTableColumn:(NSTableColumn *)column row:(NSInteger)row {
    if ([[column identifier] isEqualToString:@"1"]) {
        [filters objectAtIndex:row][0] = @(![[filters objectAtIndex:row][0] boolValue]);
    } else {
        [filters objectAtIndex:row][1] = value;
    }
    [self saveFilters];
    [self.filtersTableView reloadData];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)rowIndex {
    if ([[column identifier] isEqualToString:@"1"]) {
        return [[filters objectAtIndex:rowIndex] objectAtIndex:0];
    } else {
        NSString *filterStr = [[filters objectAtIndex:rowIndex] objectAtIndex:1];
        // Make sure the string successfully compiles as a regex
        NSError *error = nil;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:filterStr options:0 error:&error];
        regex = nil; // Silence warning about unused variable
        // If regex compilation fails, show it colored red
        if (error != nil) {
            DLog(@"Regex compilation failed: %@", [error localizedDescription]);
            NSDictionary *textAttributes = @{ NSForegroundColorAttributeName: [NSColor redColor] };
            return [[NSAttributedString alloc] initWithString:filterStr attributes:textAttributes];
        }
        
        return filterStr;
    }
    
    return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    [self updateButtonStatus];
}

@end
