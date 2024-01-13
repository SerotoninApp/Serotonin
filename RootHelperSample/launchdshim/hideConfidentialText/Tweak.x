// change confidential text - thx fiore
@import Foundation;
@import UIKit;
@interface SBUILegibilityLabel : UIView
@property(nonatomic, assign, readwrite)NSString* string;
@property(assign,nonatomic) long long textAlignment;
@property(nonatomic, assign, readwrite)UIColor* textColor;
@end

%group thething
%hook CSStatusTextView
- (void)setInternalLegalText:(NSString *)string {
    %orig(@"");
}
%end
%end

%ctor {
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/.serotonin_hidetext"]; // no cfprefsd hook, will rework when I get system injection working
    if (fileExists) {
        %init(thething)
    }
}
        
