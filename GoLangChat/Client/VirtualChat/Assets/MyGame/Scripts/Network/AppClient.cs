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
	


	public class AppMessage
	{

		public delegate void Callback ();

		public Callback callback;
	};

	public class AppClient: Worker<AppMessage>
	{

		public string serverIP = "localhost" ;
		public int serverPort = 3000 ;

		public delegate void OnReceivedPacketDelegate(Packet packet);

		public OnReceivedPacketDelegate onReceivedCallback;

		public WorkerReceiver receiver;
		public WorkerSender sender;


	
		public AppClient ()
		{
			receiver = new WorkerReceiver ();
			receiver.parent = this;
		
		

		}

		public void setServer(string ip, int port) 
		{
			this.serverIP = ip;
			this.serverPort = port;
		}

		// called by receiver thread
		public void onReceived (Packet packet)
		{
			
			AppMessage newmessage =	new AppMessage ();
			newmessage.callback = delegate() {
			//	string json = System.Text.Encoding.UTF8.GetString ( packet.body);
			//	Console.WriteLine("Received="+ json);

				if (onReceivedCallback!=null)
				onReceivedCallback(packet);

			};
			this.queue.push (newmessage);
		}

		// called by receiver thread
		public void onDisconnected ()
		{
			Console.WriteLine ("OnDisconnected");

			AppMessage newmessage = new AppMessage ();
			newmessage.callback = delegate () {
				Console.WriteLine ("Disconnected");
				System.Threading.Thread t = new Thread (this.processReconnect);
				t.Start ();
			};
			this.queue.push (newmessage);
		}

		// as a separte thread
		public void processReconnect ()
		{
			Console.WriteLine ("ProcessReconnect Stop");
			receiver.quit ();
			receiver.stop ();

			Console.WriteLine ("ProcessReconnect Sleep");
			this.sleepConnect ();
		}

		public void sleepConnect ()
		{
			Console.WriteLine ("Sleep");
			System.Threading.Thread.Sleep (3000);
			receiver.run ();
		}


		public void test ()
		{	
			//	this.receiver.test ();
			this.sender.test ();
		}


		public void send(Packet p)
		{
			WorkMessage m = new WorkMessage ();
			m.packet = p;
			this.sender.queue.push (m);
		}


	
		public void startSendThread ()
		{
			sender = new WorkerSender ();
			sender.parent = this;
			sender.stream = receiver.stream;
			sender.run ();
		}

		public void stopSendThread ()
		{
			if (sender != null) {
				sender.stop ();
				sender = null;
			}
		}


	


		public  override void process ()
		{

			receiver.run ();
			while (!finish) {

				var found = this.queue.pop (1000);
				if (found != null) {
					
					found.callback ();
				} else {
					//Console.WriteLine ("Program Processing");
				}
			}
			receiver.quit ();
			receiver.stop ();
		}

		// called by unity3d main thread
		public void polling()
		{
			var found =  this.queue.pop (0);
			if (found != null) {
				found.callback ();
			}
		}
	}
}

