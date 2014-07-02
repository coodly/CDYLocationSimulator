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

#import "CDYLocationManager.h"
#import "CDYLocationsInput.h"
#import "CDYLocation.h"

@interface CDYLocationManager ()

@property (nonatomic, strong) CDYLocationsInput *locationsInput;
@property (nonatomic, assign) BOOL started;
@property (nonatomic, assign) BOOL pushLocations;

@end

@implementation CDYLocationManager

- (instancetype)initWithInput:(CDYLocationsInput *)input {
    self = [super init];
    if (self) {
        _locationsInput = input;
        _playbackSpeed = 1;
    }
    return self;
}

- (void)startUpdatingLocation {
    dispatch_async(dispatch_get_main_queue(), ^{
        CDYLSLog(@"startUpdatingLocation");
        [self setPushLocations:YES];

        if (!self.started && ![self.locationsInput isReady]) {
            [self.locationsInput prepareInput:^{
                [self pushNextLocation];
            }];
        } else if ([self.locationsInput isReady]) {
            [self pushNextLocation];
        }

        [self setStarted:YES];
    });
}

- (void)stopUpdatingLocation {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setPushLocations:NO];
    });
}

- (void)pushNextLocation {
    if (!self.pushLocations) {
        CDYLSLog(@"Updates stopped");
        return;
    }

    CDYLocation *location = [self.locationsInput nextLocation];
    [self.delegate locationManager:self didUpdateLocations:@[location]];
    CDYLocationDelayedExecution(location.timeToNextLocation / self.playbackSpeed, ^{
        [self pushNextLocation];
    });
}

@end
