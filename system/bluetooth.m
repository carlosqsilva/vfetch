// #import <Foundation/Foundation.h>
// #import <IOBluetooth/IOBluetooth.h>

// int main(int argc, const char * argv[]) {
//     @autoreleasepool {
//         // Get the list of paired devices
//         NSArray *devices = [IOBluetoothDevice pairedDevices];

//         if ([devices count] == 0) {
//             NSLog(@"No Bluetooth devices are paired.");
//             return 0;
//         }

//         // Iterate through the list of devices
//         for (IOBluetoothDevice *device in devices) {
//             NSString *deviceName = [device name];
//             NSString *deviceAddress = [device addressString];
//             BOOL isConnected = [device isConnected];

//             NSLog(@"Device Name: %@", deviceName);
//             NSLog(@"Device Address: %@", deviceAddress);
//             NSLog(@"Connected: %@", isConnected ? @"Yes" : @"No");
//             NSLog(@"-----------------------------");
//         }
//     }
//     return 0;
// }

#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>

int get_connected_devices() {
  NSArray *pairedDevices = [IOBluetoothDevice pairedDevices];
  NSUInteger pairedDevicesCount = [pairedDevices count];

  if (pairedDevicesCount == 0) {
    return 0;
  }

  int connectedDeviceCount = 0;

  for (IOBluetoothDevice *device in pairedDevices) {
    BOOL isPaired = [device isPaired];
    BOOL isConnected = [device isConnected];

    if (isPaired && isConnected) {
      connectedDeviceCount++;
    }
  }

  return connectedDeviceCount;
}
