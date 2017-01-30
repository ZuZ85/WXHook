//
//  WXHook.mm
//  WXHook
//
//  Created by 王文臻 on 2017/1/26.
//  Copyright (c) 2017年 __MyCompanyName__. All rights reserved.
//

// CaptainHook by Ryan Petrich
// see https://github.com/rpetrich/CaptainHook/

#import <Foundation/Foundation.h>
#import "CaptainHook/CaptainHook.h"
#include <notify.h> // not required; for examples only

int sharetext = 0;
NSString *sharemsg = @"";
BOOL isShared = NO;


CHDeclareClass(BaseMessageCellView)
CHDeclareClass(WCNewCommitViewController);
CHDeclareClass(TextMessageViewModel);
CHDeclareClass(MMUIViewController);
CHDeclareClass(CBaseContact);
CHDeclareClass(UINavigationController);
CHDeclareClass(WCFacade);
CHDeclareClass(MMGrowTextView);
CHDeclareClass(MMTextView);

CHDeclareClass(MMServiceCenter)
CHDeclareClass(TextMessageCellView)
CHDeclareClass(ImageMessageCellView)
CHDeclareClass(VoiceMessageCellView)
CHDeclareClass(VideoMessageCellView)
CHDeclareClass(EmoticonMessageCellView)

#pragma mark- 赋值发送消息
CHOptimizedMethod1(self, void, WCNewCommitViewController, viewWillAppear, BOOL, animated) {
  if (sharetext) {
    MMGrowTextView *grow =  CHIvar(self, _textView, MMGrowTextView*);
    MMTextView *textView = CHIvar(grow, _textView, MMTextView*);
    [textView setText: sharemsg];
    [grow postTextChangeNotification];
    sharemsg = @"";
    sharetext = 0;
  }
  return CHSuper1(WCNewCommitViewController, viewWillAppear, animated);
}

#pragma mark- 消息转发是退出不保存
CHOptimizedMethod1(self, void, WCNewCommitViewController, writeOldText, id, arg1) {
  if (!isShared) {
    CHSuper1(WCNewCommitViewController, writeOldText, arg1);
  }
}
CHOptimizedMethod0(self, void, WCNewCommitViewController, OnReturn) {
  
  CHSuper0(WCNewCommitViewController, OnReturn);
  
  if (isShared) {
    isShared = NO;
  }
}

CHDeclareClass(UIMenuController)
CHDeclareClass(UIMenuItem)
CHOptimizedMethod1(self, void, UIMenuController, setMenuItems, NSArray *, array) {
  
  UIMenuItem *item = [CHAlloc(UIMenuItem) initWithTitle: @"朋友圈" action: @selector(timeline:)];
  
  NSMutableArray *newArray = [array mutableCopy];
  [newArray insertObject:item atIndex:0];
  CHSuper1(UIMenuController, setMenuItems, newArray);
}

CHOptimizedMethod2(self, BOOL, BaseMessageCellView, canPerformAction, SEL, arg1, withSender, id, arg2) {
  BOOL canPerform = CHSuper2(BaseMessageCellView, canPerformAction, arg1, withSender, arg2);

  if (!canPerform) {
    if (arg1 == NSSelectorFromString(@"timeline:")) {
      if ([self isKindOfClass:CHClass(TextMessageCellView)] || [self isKindOfClass: CHClass(ImageMessageCellView)] || [self isKindOfClass: CHClass(VideoMessageCellView)]) {
        return YES;
      }
    }
  }
  return canPerform;
}

#pragma mark- 转发实际执行方法
CHDeclareMethod1(void, BaseMessageCellView, textTimeline, UIMenuItem *, menu) {
  id vc = CHIvar(self, m_delegate, id);// BaseMsgContentViewController
  TextMessageViewModel *msgViewModel = [self viewModel];
  NSString *msgtext = CHIvar(msgViewModel, m_contentText, NSString *);
  CBaseContact *contact = CHIvar(msgViewModel, m_contact, CBaseContact *);
  
  sharemsg = msgtext;
  sharetext = 1;
  
  WCNewCommitViewController *wcvc = [CHAlloc(WCNewCommitViewController) initWithImages:nil contacts:nil];
  
  [wcvc setType: 2];
  [wcvc removeOldText];
  isShared = YES;
  
  [wcvc setTempSelectContacts: @[contact]];
  
  UINavigationController *navC = [CHAlloc(UINavigationController) initWithRootViewController:wcvc];
  [vc presentViewController:navC animated:YES completion:nil];
}
CHDeclareClass(ImageMessageViewModel);
CHDeclareClass(MMImage);
CHDeclareClass(UIImage);
CHDeclareMethod1(void, ImageMessageCellView, imageTimeline, UIMenuItem *, menu) {
  
  id vc = CHIvar(self, m_delegate, id);
  ImageMessageViewModel *imageViewMdel = [self viewModel];
  NSData *imageData = [imageViewMdel imageData];
  UIImage *image = [UIImage imageWithData:imageData];
  MMImage *mmImage = [CHAlloc(MMImage) initWithImage: image];
  
  CBaseContact *contact = CHIvar(imageViewMdel, m_contact, CBaseContact *);
  
  WCNewCommitViewController *wcvc = [CHAlloc(WCNewCommitViewController) initWithImages:@[mmImage] contacts:nil];
  
  [wcvc setType: 1];
  [wcvc removeOldText];
  isShared = YES;
  
  [wcvc setTempSelectContacts: @[contact]];
  
  UINavigationController *navC = [CHAlloc(UINavigationController) initWithRootViewController:wcvc];
  [vc presentViewController:navC animated:YES completion:nil];
}
CHDeclareMethod1(void, VideoMessageCellView, videoTimeline, UIMenuItem *, menu) {
  CHLog(@"videocellview good job");
}
CHDeclareMethod1(void, BaseMessageCellView, timeline, UIMenuItem *, menu) {
  if ([self isKindOfClass: CHClass(TextMessageCellView)]) {
    [self performSelector: @selector(textTimeline:) withObject: menu];
  }
  else if ([self isKindOfClass: CHClass(ImageMessageCellView)]) {
    [self performSelector: @selector(imageTimeline:) withObject: menu];
  }
  else if ([self isKindOfClass: CHClass(VideoMessageCellView)]) {
    [self performSelector: @selector(videoTimeline:) withObject: menu];
  }
  else {
    [self performSelector: @selector(onForward:) withObject: menu];
  }
}

#pragma mark- 默认屏蔽消息发送者
CHOptimizedMethod0(self, int, WCFacade, getPostPrivacy) {
  if (isShared) {
    return 5;
  }
  return CHSuper0(WCFacade, getPostPrivacy);
}

CHConstructor // code block that runs immediately upon load
{
  @autoreleasepool
  {
    
    CHLoadLateClass(WCNewCommitViewController);
    CHHook1(WCNewCommitViewController, viewWillAppear);
    CHHook1(WCNewCommitViewController, writeOldText);
    CHHook0(WCNewCommitViewController, OnReturn);
    
    CHLoadLateClass(UINavigationController);
    
    CHLoadLateClass(UIMenuController);
    CHLoadLateClass(UIMenuItem);
    CHHook1(UIMenuController, setMenuItems);
    
    CHLoadLateClass(BaseMessageCellView);
    CHHook2(BaseMessageCellView, canPerformAction, withSender);
    
    CHLoadLateClass(TextMessageCellView);
    
    CHLoadLateClass(MMServiceCenter);
    CHLoadLateClass(WCFacade);
    CHHook0(WCFacade, getPostPrivacy);
    
    CHLoadLateClass(TextMessageCellView);
    CHLoadLateClass(ImageMessageCellView);
    CHLoadLateClass(VoiceMessageCellView);
    CHLoadLateClass(VideoMessageCellView);
    CHLoadLateClass(EmoticonMessageCellView);
    
    CHLoadLateClass(ImageMessageViewModel);
    CHLoadLateClass(MMImage);
    CHLoadLateClass(UIImage);
  }
}
