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
	public class Packet
	{
		public Int64 id;
		public Int64 length;
		// body length
		public byte[] body;

		public void packJson(string json)
		{
			
			this.id = 1;
			this.body = System.Text.Encoding.UTF8.GetBytes (json);
			this.length = this.body.Length;
		}
	}

	public class WorkMessage
	{
		public Packet packet;
	}

}

