//
//  AppDelegate.h
//  MetalTexturePractice
//
//  Created by WeiTing Ruan on 2020/2/8.
//  Copyright © 2020 papa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

