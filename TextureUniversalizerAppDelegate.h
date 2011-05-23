//
//  TextureUniversalizerAppDelegate.h
//  TextureUniversalizer
//
//  Created by Shilo White on 5/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
    DisplayTypeNonRetina = 0,
    DisplayTypeRetina,
    DisplayTypeHD
} DisplayType;

@interface TextureUniversalizerAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
	IBOutlet NSTextField *mSourceTextField;
	IBOutlet NSTextField *mOutputTextField;
	IBOutlet NSButton *mSourceButton;
	IBOutlet NSButton *mOutputButton;
	IBOutlet NSButton *mNonRetinaCheckBox;
	IBOutlet NSTextField *mNonRetinaSuffixTextField;
	IBOutlet NSButton *mRetinaCheckBox;
	IBOutlet NSTextField *mRetinaSuffixTextField;
	IBOutlet NSButton *mHDCheckBox;
	IBOutlet NSTextField *mHDSuffixTextField;
	IBOutlet NSButton *mSearchSubDirectoriesCheckBox;
    IBOutlet NSButton *mKeepOriginalAspect;
	IBOutlet NSButton *mUniversalizeTexturesButton;
	IBOutlet NSTextView *mResultsTextView;
	IBOutlet NSMatrix *mOrientationRadioGroup;
	NSArray *mValidImageExtensions;
	NSTimeInterval mStartTime;
	int mImagesSaved;
	NSString *mLogSeperator;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction)onSourcePathButtonClicked:(id)sender;
- (IBAction)onOutputPathButtonClicked:(id)sender;
- (void)runOpenPanelForTextField:(NSTextField *)textField;
- (IBAction)universalizeTextures:(id)sender;
- (void)convertTextures;
- (void)createDirIfNeeded:(NSString *)path;
- (BOOL)validImageForFile:(NSString *)file;
- (NSString *)saveImage:(NSImage *)image path:(NSString *)path displayType:(DisplayType)displayType portrait:(BOOL)portrait keepAspect:(BOOL)keepAspect;
- (NSBitmapImageFileType)bitmapImageFileTypeForExtension:(NSString *)extension;
- (NSSize)imageSizeForDisplayType:(DisplayType)displayType originalSize:(NSSize)originalSize portrait:(BOOL)portrait;
- (NSSize)imageAspectSizeForDisplayType:(DisplayType)displayType originalSize:(NSSize)originalSize portrait:(BOOL)portrait;
- (NSString *)suffixForDisplayType:(DisplayType)displayType;
- (void)disableControls;
- (void)enableControls;
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
- (BOOL)showYesNoAlertWithTitle:(NSString *)title message:(NSString *)message;
- (void)log:(NSString *)message;
@end
