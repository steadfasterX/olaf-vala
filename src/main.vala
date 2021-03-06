using GLib;
using Olaf.Packet;

namespace Olaf
{
	public class Program
	{
		private static void InitializeMaps()
		{
			stdout.printf("Initializing maps - yes, vala has its quirks\n");
			Packet.AtCommandMap.init();
			Packet.LAFCommandMap.init();
		}

		private static Communication.LGDevice? ChooseDevice(List<Communication.LGDevice?> devices)
		{
			int index = 0, choice = 0, deviceCount = (int)devices.length();

			if (deviceCount == 1)
				// Auto connect
				return devices.nth_data(0);

			devices.foreach ((entry) => {
				stdout.printf("%i) %s\n",++index, entry.to_string());
			});
			
			stdout.printf("Choose device: ");
			stdin.scanf("%d", out choice);

			--choice;
			if (choice < 0 || choice > deviceCount)
				// Invalid choice
				return null;

			return devices.nth_data(choice);
		}

		public static int main(string[] args)
		{
			// Disable stdout/stderr buffering
			Posix.setvbuf(Posix.stdout, null, Posix.BufferMode.Unbuffered, 0);
			Posix.setvbuf(Posix.stderr, null, Posix.BufferMode.Unbuffered, 0);

			stdout.printf("Hello from OLAF - [O]pen LG [LAF]\n");

			InitializeMaps();
			Communication.BaseEnumerator enumerator;
	#if WIN32 || MINGW
			stdout.printf("Windows -> Choosing serial communication\n");
			enumerator = new Communication.SerialEnumerator();
	#else
			stdout.printf("Unix -> Choosing usb communication\n");
			enumerator = new Communication.UsbEnumerator();
	#endif

			List<Communication.LGDevice?> devices;
			int devCount = enumerator.GetDevices(out devices);
			if (devCount <= 0)
			{
				stdout.printf("No LG devices found! Bye!\n");
				return 1;
			}
			stdout.printf("Found %i devices:\n", devCount);

			Communication.LGDevice selectedDevice = ChooseDevice(devices);
			if(selectedDevice == null)
			{
				stdout.printf("Bye!\n");
				return 2;
			}

			if (!selectedDevice.Open())
			{
				stderr.printf("Opening the device failed!\n");
				return 1;
			}
			
			string filePath = "";
			LAFProtocol protocol = new LAFProtocol(selectedDevice);
			//protocol.SendHello();
			/*
			int fileHandle = 0;
			if (protocol.SendOpen(filePath, out fileHandle) != 0)
				return 2;
			
			stdout.printf("FileHandle opened for %s => %i\n", filePath, fileHandle);


			stdout.printf("Closing FileHandle\n");
			protocol.SendClose(fileHandle);
				*/
			DeviceProperties props;
			if (protocol.SendGetInfo(out props) != 0)
			{
				stderr.printf("Failed to get device properties\n");
				return 2;
			}
			stdout.printf(props.to_string());

			uint8[] partTable;
			if (protocol.GetPartitionTable(out partTable) != 0)
			{
				stderr.printf("Failed to get partition table\n");
				return 3;
			}
			
			return 0;
		}
	}
}
