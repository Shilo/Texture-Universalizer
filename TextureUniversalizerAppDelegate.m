//
//  TextureUniversalizerAppDelegate.m
//  TextureUniversalizer
//
//  Created by Shilo White on 5/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TextureUniversalizerAppDelegate.h"

@implementation TextureUniversalizerAppDelegate

@synthesize window;

- (void)awakeFromNib {
	[window center];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	mValidImageExtensions = [[NSArray alloc] initWithObjects:@"bmp", @"gif", @"jpg", @"jpeg", @"png", @"tif", @"tiff", nil];
	mLogSeperator = @"-------------------------------------------------------------------------------------------------------------";
}

- (IBAction)onSourcePathButtonClicked:(id)sender {
	[self runOpenPanelForTextField:mSourceTextField];
}

- (IBAction)onOutputPathButtonClicked:(id)sender {
	[self runOpenPanelForTextField:mOutputTextField];
}

- (void)runOpenPanelForTextField:(NSTextField *)textField {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	openPanel.canChooseFiles = NO;
	openPanel.canChooseDirectories = YES;
	
	NSInteger openPanelResult = [openPanel runModal];
	if (openPanelResult == NSFileHandlingPanelOKButton) {
		NSString *path = [[[openPanel URLs] objectAtIndex:0] absoluteString];
		if ([path hasPrefix:@"file://localhost"]) path = [path stringByReplacingOccurrencesOfString:@"file://localhost" withString:@""];
		path = [path stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
		textField.stringValue = path;
	}
}

- (IBAction)universalizeTextures:(id)sender {
	if ([[mSourceTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
		[self showAlertWithTitle:@"Unable to Universalize Textures." message:@"Source path is empty."];
		return;
	} else if ([[mOutputTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
		[self showAlertWithTitle:@"Unable to Universalize Textures." message:@"Output path is empty."];
		return;
	} else if ([[mSourceTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:[mOutputTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]]) {
		if ([self showYesNoAlertWithTitle:@"Warning, files may be overwritten." message:@"The output path is the same as the source path, this may overwrite files.\nWould you like to continue?"]) {
			return;
		}
	}
	
	[self disableControls];
	[self log:@"Texture Universalization Started"];
	[self log:mLogSeperator];
	[self log:@"Processing files..."];
	[self performSelector:@selector(convertTextures) withObject:nil afterDelay:1];
}

- (void)convertTextures {
	mImagesSaved = 0;
	mStartTime = [[NSDate date] timeIntervalSince1970];
	
	BOOL nonRetina = (mNonRetinaCheckBox.state == NSOnState);
	BOOL retina = (mRetinaCheckBox.state == NSOnState);
	BOOL hd = (mHDCheckBox.state == NSOnState);
	BOOL searchSubDirs = (mSearchSubDirectoriesCheckBox.state == NSOnState);
	BOOL portrait = [((NSButtonCell *)mOrientationRadioGroup.selectedCell).title isEqualToString:@"Portrait"];
    BOOL keepAspect = (mKeepOriginalAspect.state == NSOnState);
	NSString *sourcePath = mSourceTextField.stringValue;
	NSString *outputPath = mOutputTextField.stringValue;
	
	NSArray *files;
	if (searchSubDirs) {
		files = [[NSFileManager defaultManager] subpathsAtPath:sourcePath];
	} else {
		files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sourcePath error:nil];
	}
	
	BOOL imagesExist = NO;
	for (NSString *file in files) {
		if ([self validImageForFile:file]) {
			imagesExist = YES;
			
			NSString *path = [sourcePath stringByAppendingPathComponent:file];
			NSImage *image = [[NSImage alloc] initWithContentsOfFile:path];
			path = [outputPath stringByAppendingPathComponent:file];
			[self createDirIfNeeded:[path stringByDeletingLastPathComponent]];
			NSString *filename;
			
			if (nonRetina) {
				filename = [self saveImage:image path:path displayType:DisplayTypeNonRetina portrait:portrait keepAspect:keepAspect];
				if (filename) [self log:[@"Saved: " stringByAppendingString:filename]];
			}
			if (retina) {
				filename = [self saveImage:image path:path displayType:DisplayTypeRetina portrait:portrait keepAspect:keepAspect];
				if (filename) [self log:[@"Saved: " stringByAppendingString:filename]];
			}
			if (hd) {
				filename = [self saveImage:image path:path displayType:DisplayTypeHD portrait:portrait keepAspect:keepAspect];
				if (filename) [self log:[@"Saved: " stringByAppendingString:filename]];
			}
			[image release];
		}
	}
	
	[self log:mLogSeperator];
	[self log:@"Texture Universalization finished"];
	if (!imagesExist) {
		[self log:[NSString stringWithFormat:@"No images exist in directory \"%@\".", sourcePath]];
	} else {
		[self log:[NSString stringWithFormat:@"%i images saved in %.2f seconds.", mImagesSaved, [[NSDate date] timeIntervalSince1970]-mStartTime]];
	}
	[self performSelector:@selector(enableControls) withObject:nil afterDelay:1];
}

- (void)createDirIfNeeded:(NSString *)path {
	NSFileManager *fileManager = [NSFileManager defaultManager]; 
	if(![fileManager fileExistsAtPath:path isDirectory:nil]) {
		if(![fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL]) {
			[NSString stringWithFormat:@"Error: Unable to create directory \"%@\"", path];
		}
	}
}

- (BOOL)validImageForFile:(NSString *)file {
	NSString *extension = [[file pathExtension] lowercaseString];
	for (NSString *validExtension in mValidImageExtensions) {
		if ([extension isEqualToString:validExtension]) {
			return YES;
		}
	}
	return NO;
}

- (NSString *)saveImage:(NSImage *)image path:(NSString *)path displayType:(DisplayType)displayType portrait:(BOOL)portrait keepAspect:(BOOL)keepAspect {
	NSSize imageSize = (keepAspect)?[self imageAspectSizeForDisplayType:displayType originalSize:image.size portrait:portrait]:[self imageSizeForDisplayType:displayType originalSize:image.size portrait:portrait];
	NSString *suffix = [self suffixForDisplayType:displayType];
	NSString *filename = [[path stringByDeletingPathExtension] stringByAppendingFormat:@"%@.%@", suffix, [path pathExtension]];
	
	NSImage *newImage = [[NSImage alloc] initWithSize:imageSize];
	
	@try {
		[newImage lockFocus];
	}
	@catch(id NSException) {
		[self log:[NSString stringWithFormat:@"Error: filename \"%@\" is too small to create.", filename]];
		return nil;
	}
	[image drawInRect:NSMakeRect(0, 0, imageSize.width, imageSize.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	[newImage unlockFocus];
	
	NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithData:newImage.TIFFRepresentation];
	[[bitmapImageRep representationUsingType:[self bitmapImageFileTypeForExtension:[path pathExtension]] properties:nil] writeToFile:filename atomically:NO];
	[bitmapImageRep release];
	[newImage release];
	
	mImagesSaved++;
	return filename;
}

- (NSBitmapImageFileType)bitmapImageFileTypeForExtension:(NSString *)extension {
	extension = [extension lowercaseString];
	if ([extension isEqualToString:@"jpg"] || [extension isEqualToString:@"jpeg"]) {
		return NSJPEGFileType;
	} else if ([extension isEqualToString:@"png"]) {
		return NSPNGFileType;
	} else if ([extension isEqualToString:@"gif"]) {
		return NSGIFFileType;
	} else if ([extension isEqualToString:@"tif"] || [extension isEqualToString:@"tiff"]) {
		return NSTIFFFileType;
	} else {
		return NSBMPFileType;
	}
}

- (NSSize)imageSizeForDisplayType:(DisplayType)displayType originalSize:(NSSize)originalSize portrait:(BOOL)portrait {
	double retinaWidthRatio = 0.833333333333333;
	double retinaHeightRatio = 0.9375;
	double nonRetinaWidthRatio = retinaWidthRatio/2;
	double nonRetinaHeightRatio = retinaHeightRatio/2;
	
	switch (displayType) {
		case DisplayTypeHD:
			return originalSize;
		case DisplayTypeRetina: {
			int width = round(originalSize.width * ((portrait)?retinaWidthRatio:retinaHeightRatio));
			int height = round(originalSize.height * ((portrait)?retinaHeightRatio:retinaWidthRatio));
			return NSMakeSize(width, height);
		} default: {
			int width = round(originalSize.width * ((portrait)?nonRetinaWidthRatio:nonRetinaHeightRatio));
			int height = round(originalSize.height * ((portrait)?nonRetinaHeightRatio:nonRetinaWidthRatio));
			return NSMakeSize(width, height);
		}
	}
}

- (NSSize)imageAspectSizeForDisplayType:(DisplayType)displayType originalSize:(NSSize)originalSize portrait:(BOOL)portrait {
    double retinaWidthRatio = 0.833333333333333;
	double retinaHeightRatio = 0.9375;
	double nonRetinaWidthRatio = retinaWidthRatio/2;
	double nonRetinaHeightRatio = retinaHeightRatio/2;
    double scaleAspect = ((originalSize.width>originalSize.height)?originalSize.width/originalSize.height:originalSize.height/originalSize.width);
	
	switch (displayType) {
		case DisplayTypeHD:
			return originalSize;
		case DisplayTypeRetina: {
            int height;
            int width;
            if (originalSize.width>originalSize.height) {
                width = round(originalSize.width * ((portrait)?retinaWidthRatio:retinaHeightRatio) * scaleAspect);
                height = round(width/scaleAspect);
            } else {
                height = round(originalSize.height * ((portrait)?retinaHeightRatio:retinaWidthRatio) * scaleAspect);
                width = round(height/scaleAspect);
            }
			return NSMakeSize(width, height);
		} default: {
            int height;
            int width;
            if (originalSize.width>originalSize.height) {
                width = round(originalSize.width * ((portrait)?nonRetinaWidthRatio:nonRetinaHeightRatio) * scaleAspect);
                height = round(width/scaleAspect);
            } else {
                height = round(originalSize.height * ((portrait)?nonRetinaHeightRatio:nonRetinaWidthRatio) * scaleAspect);
                width = round(height/scaleAspect);
            }
			return NSMakeSize(width, height);
		}
	}
}

- (NSString *)suffixForDisplayType:(DisplayType)displayType {
	switch (displayType) {
		case DisplayTypeHD:
			return mHDSuffixTextField.stringValue;
		case DisplayTypeRetina:
			return mRetinaSuffixTextField.stringValue;
		default:
			return mNonRetinaSuffixTextField.stringValue;
	}
}

- (void)disableControls {
	[mUniversalizeTexturesButton setEnabled:NO];
	[mSourceTextField setEnabled:NO];
	[mSourceButton setEnabled:NO];
	[mOutputTextField setEnabled:NO];
	[mOutputButton setEnabled:NO];
	[mNonRetinaCheckBox setEnabled:NO];
	[mRetinaCheckBox setEnabled:NO];
	[mHDCheckBox setEnabled:NO];
    [mKeepOriginalAspect setEnabled:NO];
	[mNonRetinaSuffixTextField setEnabled:NO];
	[mRetinaSuffixTextField setEnabled:NO];
	[mHDSuffixTextField setEnabled:NO];
	[mSearchSubDirectoriesCheckBox setEnabled:NO];
	[mOrientationRadioGroup setEnabled:NO];
}

- (void)enableControls {
	[mUniversalizeTexturesButton setEnabled:YES];
	[mSourceTextField setEnabled:YES];
	[mSourceButton setEnabled:YES];
	[mOutputTextField setEnabled:YES];
	[mOutputButton setEnabled:YES];
	[mNonRetinaCheckBox setEnabled:YES];
	[mRetinaCheckBox setEnabled:YES];
	[mHDCheckBox setEnabled:YES];
    [mKeepOriginalAspect setEnabled:YES];
	[mNonRetinaSuffixTextField setEnabled:YES];
	[mRetinaSuffixTextField setEnabled:YES];
	[mHDSuffixTextField setEnabled:YES];
	[mSearchSubDirectoriesCheckBox setEnabled:YES];
	[mOrientationRadioGroup setEnabled:YES];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
	NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert setMessageText:title];
    [alert setInformativeText:message];
	[alert runModal];
	[alert release];
}

- (BOOL)showYesNoAlertWithTitle:(NSString *)title message:(NSString *)message {
	NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert setMessageText:title];
    [alert setInformativeText:message];
	[alert addButtonWithTitle:@"No"];
	[alert addButtonWithTitle:@"Yes"];
	[alert autorelease];
	return ([alert runModal] == 1000)?YES:NO;
}

- (void)log:(NSString *)message {
	mResultsTextView.string = [mResultsTextView.string stringByAppendingFormat:@"%@%@", ([mResultsTextView.string isEqualToString:@""])?@"":([message isEqualToString:@"Texture Universalization Started"])?[NSString stringWithFormat:@"\n\n%@\n", mLogSeperator]:@"\n", message];
	[mResultsTextView scrollRangeToVisible:NSMakeRange(mResultsTextView.string.length, 0)];
	[mResultsTextView displayIfNeeded];
}
@end
