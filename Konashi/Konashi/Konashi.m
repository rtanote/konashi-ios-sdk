/* ========================================================================
 * Konashi.m
 *
 * http://konashi.ux-xu.com
 * ========================================================================
 * Copyright 2013 Yukai Engineering Inc.
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
 * ======================================================================== */

#import <QuartzCore/QuartzCore.h>
#import "KNSPeripheralImpls.h"
#import "KonashiUtils.h"
#import "Konashi.h"
#import "KNSHandlerManager.h"
#import "Konashi+UI.h"
#import "CBUUID+Konashi.h"

@interface Konashi ()
{
	NSString *findName;
	BOOL isReady;
	BOOL isCallFind;
	KNSHandlerManager *handlerManager;
}

@end

@implementation Konashi

#pragma mark -
#pragma mark - Singleton

+ (Konashi *) shared
{
    static Konashi *_konashi = nil;
    
    @synchronized (self){
        static dispatch_once_t pred;
        dispatch_once(&pred, ^{
            _konashi = [[Konashi alloc] init];
        });
    }
	
    return _konashi;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		[KNSCentralManager sharedInstance];
		handlerManager = [KNSHandlerManager new];
		__weak typeof(findName) bfindName = findName;
		__block typeof(isCallFind) bisCallFind = isCallFind;
		[[NSNotificationCenter defaultCenter] addObserverForName:KonashiEventCentralManagerPowerOnNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
			if (bisCallFind) {
				bisCallFind = NO;
				if (bfindName) {
					KNS_LOG(@"Try findWithName");
					[self findModuleWithName:bfindName timeout:KonashiFindTimeoutInterval];
				}
				else {
					[self findModule:KonashiFindTimeoutInterval];
				}
			}
		}];
		[[NSNotificationCenter defaultCenter] addObserverForName:KonashiEventReadyToUseNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
			KNSPeripheral *connectedPeripheral = [note userInfo][KonashiPeripheralKey];
			KNS_LOG(@"Peripheral(UUID : %@) is ready to use.", connectedPeripheral.peripheral.identifier.UUIDString);
			_activePeripheral = connectedPeripheral;
			_activePeripheral.handlerManager = handlerManager;
		}];
	}
	
	return self;
}

#pragma mark -
#pragma mark - Konashi control public methods

+ (KonashiResult) find
{
//TODO: use KNSPeripheral
    return [[Konashi shared] findModule:KonashiFindTimeoutInterval];
}

+ (KonashiResult) findWithName:(NSString*)name
{
//TODO : use KNSPeripheral
    return [[Konashi shared] findModuleWithName:name timeout:KonashiFindTimeoutInterval];
}

+ (NSString *)softwareRevisionString
{
	return [[Konashi shared].activePeripheral softwareRevisionString];
}

+ (KonashiResult) disconnect
{
	if([Konashi shared].activePeripheral && [Konashi shared].activePeripheral.state == CBPeripheralStateConnected){
		[[KNSCentralManager sharedInstance] cancelPeripheralConnection:[Konashi shared].activePeripheral.peripheral];
		return KonashiResultSuccess;
	}
	else{
		return KonashiResultFailure;
	}
}

+ (BOOL) isConnected
{
	return ([Konashi shared].activePeripheral && [Konashi shared].activePeripheral.state == CBPeripheralStateConnected);
}

+ (BOOL) isReady
{
    return [[Konashi shared].activePeripheral isReady];
}

+ (NSString *) peripheralName
{
    return [Konashi shared].activePeripheral.peripheral.name;
}

#pragma mark -
#pragma mark - Konashi PIO public methods

+ (KonashiResult) pinMode:(KonashiDigitalIOPin)pin mode:(KonashiPinMode)mode
{    
    return [[Konashi shared].activePeripheral pinMode:pin mode:mode];
}

+ (KonashiResult) pinModeAll:(int)mode
{
    return [[Konashi shared].activePeripheral pinModeAll:mode];
}

+ (KonashiResult) digitalWrite:(KonashiDigitalIOPin)pin value:(KonashiLevel)value
{
	return [[Konashi shared].activePeripheral digitalWrite:pin value:value];
}

+ (KonashiResult) digitalWriteAll:(int)value
{
	return [[Konashi shared].activePeripheral digitalWriteAll:value];
}

+ (KonashiResult) pinPullup:(KonashiDigitalIOPin)pin mode:(KonashiPinMode)mode
{
    return [[Konashi shared].activePeripheral pinPullup:pin mode:mode];
}

+ (KonashiResult) pinPullupAll:(int)mode
{
    return [[Konashi shared].activePeripheral pinPullupAll:mode];
}

#pragma mark -
#pragma mark - Konashi PWM public methods

+ (KonashiResult) pwmMode:(KonashiDigitalIOPin)pin mode:(KonashiPWMMode)mode
{
    return [[Konashi shared].activePeripheral pwmMode:pin mode:mode];
}

+ (KonashiResult) pwmPeriod:(KonashiDigitalIOPin)pin period:(unsigned int)period
{
    return [[Konashi shared].activePeripheral pwmPeriod:pin period:period];
}

+ (KonashiResult) pwmDuty:(KonashiDigitalIOPin)pin duty:(unsigned int)duty
{
    return [[Konashi shared].activePeripheral pwmDuty:pin duty:duty];
}

+ (KonashiResult) pwmLedDrive:(KonashiDigitalIOPin)pin dutyRatio:(int)ratio
{
    return [[Konashi shared].activePeripheral pwmLedDrive:pin dutyRatio:ratio];
}

#pragma mark -
#pragma mark - Konashi analog IO public methods

+ (int) analogReference
{
    return [[Konashi shared].activePeripheral analogReference];
}

+ (KonashiResult) analogReadRequest:(KonashiAnalogIOPin)pin
{
    return [[Konashi shared].activePeripheral analogReadRequest:pin];
}

+ (KonashiResult) analogWrite:(KonashiAnalogIOPin)pin milliVolt:(int)milliVolt
{
    return [[Konashi shared].activePeripheral analogWrite:pin milliVolt:(int)milliVolt];
}

#pragma mark -
#pragma mark - Konashi I2C public methods

+ (KonashiResult) i2cMode:(KonashiI2CMode)mode
{
    return [[Konashi shared].activePeripheral i2cMode:mode];
}

+ (KonashiResult) i2cStartCondition
{
    return [[Konashi shared].activePeripheral i2cSendCondition:KonashiI2CConditionStart];
}

+ (KonashiResult) i2cRestartCondition
{
    return [[Konashi shared].activePeripheral i2cSendCondition:KonashiI2CConditionRestart];
}

+ (KonashiResult) i2cStopCondition
{
    return [[Konashi shared].activePeripheral i2cSendCondition:KonashiI2CConditionStop];
}

+ (KonashiResult)i2cWrite:(NSData *)data address:(unsigned char)address
{
	return [[Konashi shared].activePeripheral i2cWrite:data address:address];
}

+ (KonashiResult) i2cWriteString:(NSString *)data address:(unsigned char)address
{
	return [[Konashi shared].activePeripheral i2cWrite:(int)MIN(data.length, [[[Konashi shared].activePeripheral.impl class] i2cDataMaxLength]) data:(unsigned char *)data.UTF8String address:address];
}

+ (KonashiResult) i2cReadRequest:(int)length address:(unsigned char)address
{
    return [[Konashi shared].activePeripheral i2cReadRequest:length address:address];
}

+ (NSData *)i2cReadData
{
	return [[Konashi shared].activePeripheral i2cReadData];
}

#pragma mark -
#pragma mark - Konashi UART public methods

+ (KonashiResult) uartMode:(KonashiUartMode)mode
{
    return [[Konashi shared].activePeripheral uartMode:mode];
}

+ (KonashiResult) uartBaudrate:(KonashiUartBaudrate)baudrate
{
    return [[Konashi shared].activePeripheral uartBaudrate:baudrate];
}

+ (KonashiResult) uartWriteData:(NSData *)data
{
	return [[Konashi shared].activePeripheral uartWriteData:data];
}

+ (KonashiResult) uartWriteString:(NSString *)string
{
	return [[Konashi shared].activePeripheral uartWrite:[string UTF8String][0]];
}

+ (NSData *)readUartData
{
	return [[Konashi shared].activePeripheral readUartData];
}

#pragma mark -
#pragma mark - Konashi hardware public methods

+ (KonashiResult) reset
{
    return [[Konashi shared].activePeripheral reset];
}

+ (KonashiResult) batteryLevelReadRequest
{
    return [[Konashi shared].activePeripheral batteryLevelReadRequest];
}

+ (KonashiResult) signalStrengthReadRequest
{
    return [[Konashi shared].activePeripheral signalStrengthReadRequest];
}

#pragma mark -
#pragma mark - Blocks

- (void)setConnectedHandler:(KonashiEventHandler)connectedHander
{
	handlerManager.connectedHandler = connectedHander;
}

- (void)setReadyHandler:(KonashiEventHandler)readyHander
{
	handlerManager.readyHandler = readyHander;
}

- (void)setDigitalInputDidChangeValueHandler:(KonashiDigitalPinDidChangeValueHandler)digitalInputDidChangeValueHandler
{
	handlerManager.digitalInputDidChangeValueHandler = digitalInputDidChangeValueHandler;
}

- (void)setDigitalOutputDidChangeValueHandler:(KonashiDigitalPinDidChangeValueHandler)digitalOutputDidChangeValueHandler
{
	handlerManager.digitalOutputDidChangeValueHandler = digitalOutputDidChangeValueHandler;
}

- (void)setAnalogPinDidChangeValueHandler:(KonashiAnalogPinDidChangeValueHandler)analogPinDidChangeValueHandler
{
	handlerManager.analogPinDidChangeValueHandler = analogPinDidChangeValueHandler;
}

- (void)setUartRxCompleteHandler:(KonashiUartRxCompleteHandler)uartRxCompleteHandler
{
	handlerManager.uartRxCompleteHandler = uartRxCompleteHandler;
}

- (void)setI2cReadCompleteHandler:(KonashiI2CReadCompleteHandler)i2cReadCompleteHandler
{
	handlerManager.i2cReadCompleteHandler = i2cReadCompleteHandler;
}

- (void)setBatteryLevelDidUpdateHandler:(KonashiBatteryLevelDidUpdateHandler)batteryLevelDidUpdateHandler
{
	handlerManager.batteryLevelDidUpdateHandler = batteryLevelDidUpdateHandler;
}

- (void)setSignalStrengthDidUpdateHandler:(KonashiSignalStrengthDidUpdateHandler)signalStrengthDidUpdateHandler
{
	handlerManager.signalStrengthDidUpdateHandler = signalStrengthDidUpdateHandler;
}

#pragma mark -
#pragma mark - Konashi control private methods

- (KonashiResult)findModule:(NSTimeInterval)timeout
{
    if(self.activePeripheral && self.activePeripheral.state == CBPeripheralStateConnected){
        return KonashiResultFailure;
    }
	
    if ([KNSCentralManager sharedInstance].state  != CBCentralManagerStatePoweredOn) {
        KNS_LOG(@"CoreBluetooth not correctly initialized !");
        KNS_LOG(@"State = %ld (%@)", (long)[KNSCentralManager sharedInstance].state, NSStringFromCBCentralManagerState([KNSCentralManager sharedInstance].state));
		
        isCallFind = YES;
        
        return KonashiResultSuccess;
    }
	
	[[KNSCentralManager sharedInstance] discover:^(CBPeripheral *peripheral, BOOL *stop) {
	} timeoutBlock:^(NSSet *peripherals) {
		if ([peripherals count] > 0) {
			[[NSNotificationCenter defaultCenter] postNotificationName:KonashiEventPeripheralFoundNotification object:nil];
			[self showModulePickerWithPeripherals:[[KNSCentralManager sharedInstance].peripherals allObjects]];
		}
		else {
			[[NSNotificationCenter defaultCenter] postNotificationName:KonashiEventNoPeripheralsAvailableNotification object:nil];
		}
	} timeoutInterval:KonashiFindTimeoutInterval];
	
    return KonashiResultSuccess;
}

- (KonashiResult)findModuleWithName:(NSString*)name timeout:(NSTimeInterval)timeout
{
    if(self.activePeripheral && self.activePeripheral.state == CBPeripheralStateConnected){
        return KonashiResultFailure;
    }
	
    if ([KNSCentralManager sharedInstance].state  != CBCentralManagerStatePoweredOn) {
        KNS_LOG(@"CoreBluetooth not correctly initialized !");
        KNS_LOG(@"State = %ld (%@)", (long)[KNSCentralManager sharedInstance].state, NSStringFromCBCentralManagerState([KNSCentralManager sharedInstance].state));
        isCallFind = YES;
        return KonashiResultSuccess;
    }
	[[KNSCentralManager sharedInstance] discover:^(CBPeripheral *peripheral, BOOL *stop) {
		if ([peripheral.name isEqualToString:name]) {
			[[KNSCentralManager sharedInstance] connectWithPeripheral:peripheral];
			*stop = YES;
		}
	} timeoutBlock:^(NSSet *peripherals) {
		KNS_LOG(@"Peripherals: %lu", (unsigned long)[peripherals count]);
		__block CBPeripheral *peripheral = nil;
		if ([peripherals count] > 0) {
			[peripherals enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
				CBPeripheral *p = obj;
				if ([[p name] isEqualToString:name]) {
					peripheral = p;
					*stop = YES;
				}
			}];
		}
		if (peripheral) {
			[[KNSCentralManager sharedInstance] connectWithPeripheral:peripheral];
		}
		else {
			[[NSNotificationCenter defaultCenter] postNotificationName:KonashiEventPeripheralNotFoundNotification object:nil];
		}
	} timeoutInterval:timeout];
    
    return KonashiResultSuccess;
}

- (void) readyModule
{
    // set konashi property
    isReady = YES;
    
	[[NSNotificationCenter defaultCenter] postNotificationName:KonashiEventReadyToUseNotification object:nil];
	
    // Enable PIO input notification
	[_activePeripheral enablePIOInputNotification];
	
    // Enable UART RX notification
	[_activePeripheral enableUART_RXNotification];
}

#pragma mark - Depricated methods

#pragma mark - digital

+ (KonashiLevel) digitalRead:(KonashiDigitalIOPin)pin
{
	return [[Konashi shared].activePeripheral digitalRead:pin];
}

+ (int) digitalReadAll
{
	return [[Konashi shared].activePeripheral digitalReadAll];
}

#pragma mark - analog

+ (int) analogRead:(KonashiAnalogIOPin)pin
{
	return [[Konashi shared].activePeripheral analogRead:pin];
}

#pragma mark - I2C

+ (KonashiResult) i2cWrite:(int)length data:(unsigned char*)data address:(unsigned char)address
{
	return [[Konashi shared].activePeripheral i2cWrite:length data:data address:address];
}

+ (KonashiResult) i2cRead:(int)length data:(unsigned char*)data
{
	return [[Konashi shared].activePeripheral i2cRead:length data:data];
}

#pragma mark - Uart

+ (KonashiResult) uartWrite:(unsigned char)data
{
	return [[Konashi shared].activePeripheral uartWrite:data];
}

+ (unsigned char) uartRead
{
	NSData *d = [[Konashi shared].activePeripheral readUartData];
	unsigned char data;
	[d getBytes:&data length:1];
	return data;
}

#pragma mark - Hardware

+ (int) batteryLevelRead
{
	return [[Konashi shared].activePeripheral batteryLevelRead];
}

+ (int) signalStrengthRead
{
	return [[Konashi shared].activePeripheral signalStrengthRead];
}

#pragma mark - Notification

+ (void) addObserver:(id)notificationObserver selector:(SEL)notificationSelector name:(NSString*)notificationName
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:notificationObserver selector:notificationSelector name:notificationName object:nil];
}

+ (void) removeObserver:(id)notificationObserver
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:notificationObserver];
}

- (void) postNotification:(NSString*)notificationName
{
	NSNotification *n = [NSNotification notificationWithName:notificationName object:self];
	[[NSNotificationCenter defaultCenter] postNotification:n];
}

@end
