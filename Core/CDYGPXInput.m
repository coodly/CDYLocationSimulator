/*
 * Copyright 2014 Coodly LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "CDYGPXInput.h"
#import "ONOXMLDocument.h"
#import "CDYLocation.h"

@interface CDYGPXInput ()

@property (nonatomic, strong) NSURL *inputFileURL;
@property (nonatomic, strong) NSArray *locations;
@property (nonatomic, assign) NSUInteger readLocation;

@end

@implementation CDYGPXInput

- (instancetype)initWithFileURL:(NSURL *)inputFileURL {
    self = [super init];
    if (self) {
        _inputFileURL = inputFileURL;
    }
    return self;
}

- (void)prepareInput:(CDYLocationActionBlock)completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        CDYLSLog(@"Load data from:%@", self.inputFileURL);
        NSData *data = [NSData dataWithContentsOfURL:self.inputFileURL];

        NSError *parseError = nil;
        ONOXMLDocument *document = [ONOXMLDocument XMLDocumentWithData:data error:&parseError];
        if (parseError) {
            CDYLSLog(@"Parse error:%@", parseError);
        }

        NSMutableArray *locations = [NSMutableArray array];

        NSDate *lastPointTime = nil;
        
        NSArray *tracks = [document.rootElement childrenWithTag:@"trk"];
        for (ONOXMLElement *trackElement in tracks) {
            NSArray *segments = [trackElement childrenWithTag:@"trkseg"];
            for (ONOXMLElement *segmentElement in segments) {
                NSArray *points = [segmentElement childrenWithTag:@"trkpt"];
                for (ONOXMLElement *point in points) {
                    NSString *latitude = point.attributes[@"lat"];
                    NSString *longitude = point.attributes[@"lon"];
                    NSDate *date = [point firstChildWithTag:@"time"].dateValue;
                    ONOXMLElement *extensions = [point firstChildWithTag:@"extensions"];
                    ONOXMLElement *trackPointExtensions = [extensions firstChildWithTag:@"TrackPointExtension"];
                    ONOXMLElement *speedElement = [trackPointExtensions firstChildWithTag:@"speed"];
                    ONOXMLElement *courseElement = [trackPointExtensions firstChildWithTag:@"course"];
                    NSNumber *speed = @(speedElement.stringValue.doubleValue);
                    NSNumber *course = @(courseElement.stringValue.doubleValue);

                    NSTimeInterval fromLastPoint = lastPointTime ? [date timeIntervalSinceDate:lastPointTime] : 1;
                    lastPointTime = date;
                    
                    CDYLocation *location = [[CDYLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue)
                                                                           altitude:0
                                                                 horizontalAccuracy:5
                                                                   verticalAccuracy:0
                                                                             course:course.doubleValue
                                                                              speed:speed.doubleValue
                                                                          timestamp:nil];
                    [location setTimeToNextLocation:fromLastPoint];
                    [locations addObject:location];
                }
            }
        }

        CDYLSLog(@"Did read %d locations", locations.count);
        [self setLocations:[NSArray arrayWithArray:locations]];
        dispatch_async(dispatch_get_main_queue(), completion);
    });
}

- (BOOL)isReady {
    return self.locations.count > 0;
}

- (CDYLocation *)nextLocation {
    if (self.readLocation >= self.locations.count) {
        [self setReadLocation:0];
    }

    CDYLocation *location = self.locations[self.readLocation];
    self.readLocation++;
    return location;
}

@end
