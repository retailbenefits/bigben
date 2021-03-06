//
//  Copyright 2012 Lolay, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <mach/mach_time.h>
#import "LolayTimer.h"
#import "LolayTimerMeasurement.h"

@interface LolayTimer ()

@property (nonatomic, retain) NSString* name;
@property (nonatomic) UInt64 startTime;
@property (nonatomic) UInt64 incrementTime;
@property (nonatomic, retain, readwrite) NSMutableArray* measurements;

@end

@implementation LolayTimer

@synthesize name = name_;
@synthesize startTime = startTime_;
@synthesize incrementTime = incrementTime_;
@synthesize measurements = measurements_;

static Float64 wavelength;

+ (void) initialize {
	mach_timebase_info_data_t timebase;
	mach_timebase_info(&timebase);
	wavelength = ((Float64) timebase.numer) / ((Float64) timebase.denom);
}

- (id) initWithName:(NSString*) inName {
	self = [super init];
	
	if (self) {
		self.name = inName;
		self.measurements = [NSMutableArray array];
		self.startTime = 0;
		self.incrementTime = 0;
	}
	
	return self;
}

- (void) start {
	UInt64 time = mach_absolute_time();
	self.startTime = time;
	self.incrementTime = time;
}

- (void) stop {
	if (self.startTime == 0) {
		return;
	}
	UInt64 stopTime = mach_absolute_time();
	[((NSMutableArray*) self.measurements) addObject:[[LolayTimerMeasurement alloc] initWithValues:@"stop" withStartTime:self.startTime withStopTime:stopTime]];
	self.startTime = 0;
	self.incrementTime = 0;
}

- (LolayTimerMeasurement*) elapsed {
	if (self.startTime == 0) {
		return nil;
	}
	UInt64 stopTime = mach_absolute_time();
	return [[LolayTimerMeasurement alloc] initWithValues:@"elapsed" withStartTime:self.startTime withStopTime:stopTime];
}

- (LolayTimerMeasurement*) increment {
	return [self increment:@"increment"];
}

- (LolayTimerMeasurement*) increment:(NSString*) incrementName {
	if (self.incrementTime == 0) {
		return nil;
	}
	UInt64 stopTime = mach_absolute_time();
	LolayTimerMeasurement* increment = [[LolayTimerMeasurement alloc] initWithValues:incrementName withStartTime:self.incrementTime withStopTime:stopTime];
	self.incrementTime = stopTime;
	[((NSMutableArray*) self.measurements) addObject:increment];
	return increment;
}

- (NSNumber*) nanoseconds {
	return [[self.measurements lastObject] nanoseconds];
}

- (NSNumber*) milliseconds {
	return [[self.measurements lastObject] milliseconds];
}

- (NSNumber*) seconds {
	return [[self.measurements lastObject] seconds];
}

- (NSString*) description {
	return [NSString stringWithFormat:@"<LolayTimer name=%@, startTime=%qu, incrementTime=%qu, measurements=%@>", self.name, self.startTime, self.incrementTime, self.measurements];
}

@end