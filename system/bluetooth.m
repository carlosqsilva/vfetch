#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>
#import <CoreBluetooth/CoreBluetooth.h>

int get_connected_devices() {
  @autoreleasepool {
    // Check TCC permission before touching IOBluetooth.
    // CBManager.authorization is safe to call without permission and won't crash.
    CBManagerAuthorization auth = [CBCentralManager authorization];
    if (auth != CBManagerAuthorizationAllowedAlways) {
      return -1;
    }

    @try {
      NSArray *pairedDevices = [IOBluetoothDevice pairedDevices];

      int connectedDeviceCount = 0;
      for (IOBluetoothDevice *device in pairedDevices) {
        if ([device isPaired] && [device isConnected]) {
          connectedDeviceCount++;
        }
      }
      return connectedDeviceCount;
    } @catch (NSException *exception) {
      return -1;
    }
  }
}
