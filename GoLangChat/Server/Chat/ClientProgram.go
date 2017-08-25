// ClientProgram
package main

import (
	"fmt"
	//	"net"
	"encoding/json"
	"sync"
	"time"

	"github.com/golang/protobuf/proto"
)

type ClientMessage struct {
	packet *Packet
}
type ClientProgram struct {
	client       *Client
	messageQueue chan *ClientMessage
	finish       bool
	wg           sync.WaitGroup
}

func (program *ClientProgram) initialize() {
	program.client = new(Client)
	program.client.initialize()
	program.client.program = program
	program.finish = false

	program.wg.Add(1)

	program.messageQueue = make(chan *ClientMessage, 10)
}

func (program *ClientProgram) run() {
	defer program.wg.Done()
	program.client.run()

	for {
		select {
		case res := <-program.messageQueue:
			message := &BasicMessage{}
			buf := res.packet.unpack()
			proto.Unmarshal(buf, message)
			println("Received=", message.Talk)

		case <-time.After(time.Second * 1):

		}

		if program.finish {
			break
		}

		//	println("Client Processing Finish=", program.finish)
	}

}

func (program *ClientProgram) stop() {
	program.finish = true
	program.client.stop()
	program.wg.Wait()
}

func (program *ClientProgram) sleepConnect() {
	time.Sleep(3 * time.Second)
	program.client.stop()
	program.client.run()
}

func (program *ClientProgram) onDisconnected() {
	go program.client.stop()
	go program.sleepConnect()
}

func clientProgram() {

	program := new(ClientProgram)
	program.initialize()
	go program.run()

	for {

		println("1. send packet")
		println("2. send json")
		println("q. exit")

		var a string
		_, _ = fmt.Scanf("%s", &a)

		switch a {
		case "1":
			var b string
			print("Enter=")
			_, _ = fmt.Scanf("%s", &b)
			message := &BasicMessage{Talk: b}
			buf, _ := proto.Marshal(message)

			var packet = new(Packet)
			packet.pack(buf)
			packet.head.id = PacketBasicMessage

			println("Send to PacketQueue")
			program.client.packetQueue <- packet

		case "2":
			jsonData := []string{"apple", "peach", "pear"}
			jsonEncoded, _ := json.Marshal(jsonData)
			var packet = new(Packet)
			println("Send=", string(jsonEncoded))
			packet.pack(jsonEncoded)
			packet.head.id = PacketJsonMessage

			program.client.packetQueue <- packet

		case "q":
			println("stop")
			program.stop()
			break
		}
		if "q" == a {
			break
		}

	}
}
