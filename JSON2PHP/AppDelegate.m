//
//  AppDelegate.m
//  JSON2PHP
//
//  Created by Xinqi Chan on 8/25/15.
//  Copyright (c) 2015 Xinqi Chan. All rights reserved.
//

#import "AppDelegate.h"
#import "ObjectPhpResult.h"

@interface AppDelegate (){
        int objecCount;
}

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    NSString* path = [[NSBundle mainBundle] pathForResource:@"source"
                                                     ofType:@"txt"];
    NSData* contentData = [NSData dataWithContentsOfFile:path];
    
    NSError * error;
    NSDictionary * dict = [NSJSONSerialization JSONObjectWithData:contentData options:NSJSONReadingAllowFragments error:&error];
    
    if (error) {
        NSLog(@"source is not a json");
        return;
    }
    
    
    NSString * phpStringHeader = @"\r\n<?php\r\nerror_reporting(0);\r\nheader('Content-Type: text/html');\r\n";
    NSString * phpStringConetnt = @"";
    NSString * phpStringEnd = @"echo json_encode($object0, JSON_PRETTY_PRINT);\r\n?>";
    phpStringConetnt = ((ObjectPhpResult*)[self phpContentString:dict]).resultString;
    
    NSString * result = [[phpStringHeader stringByAppendingString:phpStringConetnt] stringByAppendingString:phpStringEnd];
    
    
    
    NSArray * paths = NSSearchPathForDirectoriesInDomains (NSDesktopDirectory, NSUserDomainMask, YES);
    NSString * desktopPath = [paths objectAtIndex:0];
    
    NSError *merror;
    
    BOOL succeed = [result writeToFile:[desktopPath stringByAppendingPathComponent:@"AdvertLoopAct.php"]
                              atomically:YES encoding:NSUTF8StringEncoding error:&merror];
    if (!succeed){
        // Handle error here
    }
    
}

- (ObjectPhpResult *)phpContentString:(id)source{
    
    NSString * resultString = @"";
    NSString *objectString = [NSString stringWithFormat:@"$object%i", objecCount];
    ObjectPhpResult * phpResult = [ObjectPhpResult new];
    if ([source isKindOfClass:[NSDictionary class]]) {
        NSDictionary * dict = (NSDictionary*)source;
        for (NSString * key in [dict allKeys]) {
            id  value = [dict objectForKey:key];
            if ([value isKindOfClass:[NSString class]]) {
                NSString * phpString = [NSString stringWithFormat:@"%@->%@=\"%@\";\r\n",objectString,key,value];
                resultString = [resultString stringByAppendingString:phpString];
            }else{
                objecCount ++;
                ObjectPhpResult * objectPR = [self phpContentString:value];
                resultString = [resultString stringByAppendingString:objectPR.resultString];
                
                NSString * objectFormat;
                if ([value isKindOfClass:[NSDictionary class]]) {
                    objectFormat = [NSString stringWithFormat:@"%@->%@=%@;\r\n",objectString,key,objectPR.objectName];
                }else{
                    objectFormat = [NSString stringWithFormat:@"%@->%@=%@;\r\n",objectString,key,objectPR.arrayName];
                }
                
                resultString = [resultString stringByAppendingString:objectFormat];
                
            }
            
        }
    }else if([source isKindOfClass:[NSArray class]]){
        NSDate * date = [NSDate date];
        NSString * dateString = [NSString stringWithFormat:@"%f",[date timeIntervalSince1970]];
        dateString = [dateString stringByReplacingOccurrencesOfString:@"."
                                                           withString:@""];
        NSString * arrayName = [NSString stringWithFormat:@"$array%@", dateString];
        phpResult.arrayName = arrayName;
        NSString * arrayDeclareString = [NSString stringWithFormat:@"%@ = array();\r\n",arrayName];
        resultString = [resultString stringByAppendingString:arrayDeclareString];
        NSArray * souceArray = (NSArray*)source;
        for (id value in souceArray) {
            if ([value isKindOfClass:[NSString class]]) {
                NSString * phpString = [NSString stringWithFormat:@"array_push(%@, \"%@\");\r\n",arrayName,value];
                resultString = [resultString stringByAppendingString:phpString];
            }else{
                objecCount ++;
                ObjectPhpResult * objectPR = [self phpContentString:value];
                resultString = [resultString stringByAppendingString:objectPR.resultString];
                NSString * phpString = [NSString stringWithFormat:@"array_push(%@, %@);\r\n",phpResult.arrayName,objectPR.objectName];
                resultString = [resultString stringByAppendingString:phpString];
            }
        }
    }
    
    phpResult.objectName = objectString;
    phpResult.resultString = resultString;
    
    return phpResult;
    
}





@end
