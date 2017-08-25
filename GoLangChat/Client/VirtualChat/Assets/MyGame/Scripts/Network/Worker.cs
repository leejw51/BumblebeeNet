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
	public class Worker<T> where T: class
	{
		public Thread thread;
		public bool finish;


		public Queue<T> queue;
	
		public Worker (int count=10)
		{
			finish = false;


			this.queue =   new Queue<T> (count);

		}

		public virtual void process ()
		{
		}

		public void run ()
		{
			Console.WriteLine ("AppClient Run");

			this.finish = false;
			this.thread = new Thread (process);
			this.thread.Start ();
		}

		public void quit ()
		{
			this.finish = true;
		}

		public virtual void stop ()
		{
			this.finish = true;
			thread.Join ();
		}

	






	}

}

