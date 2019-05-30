#import <objc/runtime.h>
#import "RCTVideoPlayerViewController.h"

@interface RCTVideoPlayerViewController ()

@end

@implementation RCTVideoPlayerViewController

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(addObserver:forKeyPath:options:context:);
        SEL swizzledSelector = @selector(swizzled_addObserver:forKeyPath:options:context:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        SEL originalSelectorDealloc = @selector(dealloc:);
        SEL swizzledSelectorDealloc = @selector(swizzled_dealloc:);
        
        Class classDealloc = object_getClass((id)self);
        
        Method originalMethodDealloc = class_getClassMethod(classDealloc, originalSelectorDealloc);
        Method swizzledMethodDealloc = class_getClassMethod(classDealloc, swizzledSelectorDealloc);
        
        BOOL didAddMethod =
        class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
        
        BOOL didAddMethodDealloc =
        class_addMethod(classDealloc,
                        originalSelectorDealloc,
                        method_getImplementation(swizzledMethodDealloc),
                        method_getTypeEncoding(swizzledMethodDealloc));
        
        if (didAddMethodDealloc) {
            class_replaceMethod(classDealloc,
                                swizzledSelectorDealloc,
                                method_getImplementation(originalMethodDealloc),
                                method_getTypeEncoding(originalMethodDealloc));
        } else {
            method_exchangeImplementations(originalMethodDealloc, swizzledMethodDealloc);
        }
    });
}

static const void *ObserverKey = &ObserverKey;
- (void)swizzled_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
    NSMutableSet<NSArray*> *observerSet = objc_getAssociatedObject(self, ObserverKey);
    if (observerSet == nil) {
        observerSet = [[NSMutableSet alloc] init];
        objc_setAssociatedObject(self, ObserverKey, observerSet, OBJC_ASSOCIATION_RETAIN);
    }
    // store all observer info into a set.
    [observerSet addObject:@[observer, keyPath]];
    [self swizzled_addObserver:observer forKeyPath:keyPath options:options context:context]; // this will call the origin impl
}

- (BOOL)shouldAutorotate {
  if (self.autorotate || self.preferredOrientation.lowercaseString == nil || [self.preferredOrientation.lowercaseString isEqualToString:@"all"])
    return YES;
  
  return NO;
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  [_rctDelegate videoPlayerViewControllerWillDismiss:self];
  [_rctDelegate videoPlayerViewControllerDidDismiss:self];
}

#if !TARGET_OS_TV
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
  if ([self.preferredOrientation.lowercaseString isEqualToString:@"landscape"]) {
    return UIInterfaceOrientationLandscapeRight;
  }
  else if ([self.preferredOrientation.lowercaseString isEqualToString:@"portrait"]) {
    return UIInterfaceOrientationPortrait;
  }
  else { // default case
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    return orientation;
  }
}
#endif

@end
