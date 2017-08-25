/*
 coded by Jongwhan Lee

leejw51@gmail.com

@2016 Bumblebee
 */
using System;
using System.Threading;
using System.Collections.Generic;
using System.Net;
using System.Net.Sockets;


namespace VirtualChat
{
	public class WorkerReceiver: Worker<WorkMessage>
	{
		public AppClient parent;

		public TcpClient client = null;
		public NetworkStream stream = null;


		public override void process ()
		{
			client = new TcpClient ();

			try {
				client.Connect ( parent.serverIP,   parent.serverPort);
				Console.WriteLine ("Connected");
				var stream = client.GetStream ();
				this.stream = stream;


				parent.startSendThread ();
				doProcess ();
			} catch (Exception e) {
				Console.WriteLine ("Error=" + e.ToString ());
			}


			parent.stopSendThread ();

			parent.onDisconnected ();
		}




		public void doProcess ()
		{
			Int64 id = 0;
			Int64 bodyLength = 0;

			byte[] buf = new byte[8];
			int readBytes = 0;
			while (!this.finish) {


				readBytes = blockingRead (buf, 8);
				if (0 == readBytes)
					break;
				id = BitConverter.ToInt64 (buf, 0);

				readBytes = blockingRead (buf, 8);
				if (0 == readBytes)
					break;
				bodyLength = BitConverter.ToInt64 (buf, 0);

				Console.WriteLine (string.Format ("ID={0}  Length={1}", id, bodyLength));
				byte[] body = new byte[ bodyLength];
				readBytes = blockingRead (body, (int)bodyLength);
				if (0 == readBytes)
					break;

				Packet newpacket = new Packet ();
				newpacket.id = id;
				newpacket.length = bodyLength;
				newpacket.body = body;
				parent.onReceived (newpacket);
				//string json = System.Text.Encoding.UTF8.GetString (body);
				//Console.WriteLine ("Read Bytes=" + readBytes + "   Json=" + json);
			}
		}

		public override void stop ()
		{
			if (this.stream != null) {
				this.stream.Close ();
				this.stream = null;
			}
			base.stop (); 
		}

		public int blockingRead (byte[] buf, int length)
		{
			int processed = 0;
			int remain = 0;
			int n = 0;
			while (true) {
				remain = length - processed;
				if (0 == remain)
					return length;
				n = this.stream.Read (buf, processed, remain);
				if (0 == n)
					return n;
				processed += n;

			}
		}


	}

}

