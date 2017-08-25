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
	public class WorkerSender : Worker<WorkMessage>
	{
		public AppClient parent;

		public NetworkStream stream = null;


		public override void process ()
		{


			while (!finish) {
				var found = this.queue.pop (1000);
				if (found != null) {
					


					doSend (found.packet);

				} else {

				}
			}
		}

		void doSend (Packet p)
		{

			byte[] buf = null;

			buf = BitConverter.GetBytes (p.id);
			blockingSend (buf, 8);

			buf = BitConverter.GetBytes (p.length);
			blockingSend (buf, 8);

			blockingSend (p.body, (int)p.length);

		}


		public virtual void test2 ()
		{

			var newone = new WorkMessage ();
			newone.packet = new Packet ();
			newone.packet.packJson ("Test!");
			this.queue.push (newone);
		}

		public  void test ()
		{
			WorkMessage m = new WorkMessage ();
			m.packet = new Packet ();
			m.packet.packJson ("[1,2,3,4,5]");
			this.queue.push (m);
		}

		public int blockingSend (byte[] buf, int length)
		{
			int processed = 0;
			int remain = 0;
			while (true) {
				remain = length - processed;
				if (0 == remain)
					return length;
				this.stream.Write (buf, processed, remain);// send all data
				processed += remain;

			}
		}
	}

}

