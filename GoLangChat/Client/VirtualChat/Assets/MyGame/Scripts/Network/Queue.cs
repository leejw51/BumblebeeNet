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
	public class Queue<T> where T: class
	{
		public List<T> queue ;
		public System.Threading.Semaphore sema;

		public Queue (int count)
		{
			this.queue = new List<T> (count);
			this.sema = new System.Threading.Semaphore (0, count);
		}

		public void push (T newone)
		{
			this.queue.Add (newone);
			this.sema.Release ();
		}

		public T pop (int milliseconds)
		{
			bool gotMessage = sema.WaitOne (milliseconds);
			if (gotMessage) {
				var top = this.queue [0];
				this.queue.RemoveAt (0);

				return top;
			} else {
				return null;
			}
		}

	}
}

