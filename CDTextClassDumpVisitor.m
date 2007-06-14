//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 2007 Steve Nygard.  All rights reserved.

#import "CDTextClassDumpVisitor.h"

#include <mach-o/arch.h>

#import "NSArray-Extensions.h"
#import "CDClassDump.h"
#import "CDObjCSegmentProcessor.h"
#import "CDMachOFile.h"
#import "CDOCProtocol.h"
#import "CDDylibCommand.h"
#import "CDOCClass.h"
#import "CDOCCategory.h"
#import "CDSymbolReferences.h"

@implementation CDTextClassDumpVisitor

- (id)init;
{
    if ([super init] == nil)
        return nil;

    resultString = [[NSMutableString alloc] init];
    symbolReferences = nil;

    return self;
}

- (void)dealloc;
{
    [resultString release];
    [symbolReferences release];

    [super dealloc];
}

- (void)writeResultToStandardOutput;
{
    NSData *data;

    data = [resultString dataUsingEncoding:NSUTF8StringEncoding];
    [(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] writeData:data];
}

- (void)willVisitClass:(CDOCClass *)aClass;
{
    NSArray *protocols;

    [resultString appendFormat:@"@interface %@", [aClass name]];
    if ([aClass superClassName] != nil)
        [resultString appendFormat:@" : %@", [aClass superClassName]];

    protocols = [aClass protocols];
    if ([protocols count] > 0) {
        [resultString appendFormat:@" <%@>", [[protocols arrayByMappingSelector:@selector(name)] componentsJoinedByString:@", "]];
        [symbolReferences addProtocolNamesFromArray:[protocols arrayByMappingSelector:@selector(name)]];
    }

    [resultString appendString:@"\n"];
}

- (void)didVisitClass:(CDOCClass *)aClass;
{
    if ([aClass hasMethods])
        [resultString appendString:@"\n"];

    [resultString appendString:@"@end\n\n"];
}

- (void)willVisitIvarsOfClass:(CDOCClass *)aClass;
{
    [resultString appendString:@"{\n"];
}

- (void)didVisitIvarsOfClass:(CDOCClass *)aClass;
{
    [resultString appendString:@"}\n\n"];
}

- (void)willVisitCategory:(CDOCCategory *)aCategory;
{
    NSArray *protocols;

    [resultString appendFormat:@"@interface %@ (%@)", [aCategory className], [aCategory name]];

    protocols = [aCategory protocols];
    if ([protocols count] > 0) {
        [resultString appendFormat:@" <%@>", [[protocols arrayByMappingSelector:@selector(name)] componentsJoinedByString:@", "]];
        [symbolReferences addProtocolNamesFromArray:[protocols arrayByMappingSelector:@selector(name)]];
    }

    [resultString appendString:@"\n"];
}

- (void)didVisitCategory:(CDOCCategory *)aCategory;
{
    [resultString appendString:@"@end\n\n"];
}

- (void)visitClassMethod:(CDOCMethod *)aMethod;
{
    [resultString appendString:@"+ "];
    [aMethod appendToString:resultString classDump:classDump symbolReferences:symbolReferences];
    [resultString appendString:@"\n"];
}

- (void)visitInstanceMethod:(CDOCMethod *)aMethod;
{
    [resultString appendString:@"- "];
    [aMethod appendToString:resultString classDump:classDump symbolReferences:symbolReferences];
    [resultString appendString:@"\n"];
}

- (void)visitIvar:(CDOCIvar *)anIvar;
{
    [anIvar appendToString:resultString classDump:classDump symbolReferences:symbolReferences];
    [resultString appendString:@"\n"];
}

@end