using System;

namespace VirtualChat
{
	class MainClass
	{
		
		public static void Main (string[] args)
		{
			Console.WriteLine ("Hello World!");
			AppClient client = new AppClient ();
			client.setServer ("localhost", 3000);
			client.run ();

			client.onReceivedCallback += delegate  (Packet packet) {
				string json = System.Text.Encoding.UTF8.GetString ( packet.body);
				Console.WriteLine("Main Received="+ json);

			};

			while (true) {
				Console.WriteLine ("1. test");
				Console.WriteLine ("q. exit");
				var b = Console.ReadLine ();

				if ("1" == b) {
					var packet = new Packet ();
					packet.packJson ("[1,2,3,4,5]");
					client.send (packet);

				}
				else if ("q" == b) {
					client.stop ();
					break;
				}
			}
		}
	}
}
