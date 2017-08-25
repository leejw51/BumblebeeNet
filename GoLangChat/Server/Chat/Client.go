// ClientProgram
package main

import (
	//	"fmt"
	"net"
	"sync"
	"time"

	"github.com/golang/protobuf/proto"
)

type Client struct {
	server      string
	finish      bool
	wg          sync.WaitGroup
	packetQueue chan *Packet
	connection  net.Conn
	program     *ClientProgram

	running bool
}

func (client *Client) initialize() {
	client.server = "localhost:3000"
	client.finish = false
	client.running = false
	client.packetQueue = make(chan *Packet, 10)
}

func (client *Client) blockingSend(buf []byte) error {
	length := len(buf)
	processed := 0
	end := 0
	remain := 0

	for {
		remain = length - processed
		if 0 == remain {
			println("Send=", length)
			return nil
		}
		end = processed + remain
		n, err := client.connection.Write(buf[processed:end])
		if err != nil {
			return err
		}
		processed += n

	}

	return nil
}

func (client *Client) blockingRead(buf []byte) error {
	length := len(buf)
	processed := 0
	end := 0
	remain := 0
	for {
		remain = length - processed
		if 0 == remain {
			println("Receive=", length)
			return nil
		}
		end = processed + remain
		n, err := client.connection.Read(buf[processed:end])
		if err != nil {
			return err
		}
		processed += n

	}

	return nil
}

func (client *Client) sendRoutine() {
	defer client.wg.Done()

	for {
		select {
		case res := <-client.packetQueue:
			if client.connection != nil {
				// write head
				data, _ := res.head.encode()
				client.blockingSend(data)

				// write body
				client.blockingSend(res.body)
			}

		case <-time.After(time.Second * 1):
		}

		// receiveclient.wg.Add(2)
		if client.finish {
			break
		}
	}
}
func (client *Client) receiveRoutine() {
	defer client.wg.Done()

	// connect
	tcpAddr, err := net.ResolveTCPAddr("tcp", client.server)
	checkErrror(err)

	conn, err := net.DialTCP("tcp", nil, tcpAddr)
	if err != nil {
		println("Connect Fail=", tcpAddr.String())
		client.program.onDisconnected()
		return
	}
	checkErrror(err)

	client.connection = conn

	for {
		// receive
		if client.finish {
			break
		}

		headBytes := make([]byte, 16)
		err = client.blockingRead(headBytes)
		if err != nil {
			println("receiveSession Errror=", err)
			client.program.onDisconnected()
			return
		}

		newPacket := new(Packet)

		// read head
		newPacket.head.decode(headBytes)

		// read body
		newPacket.body = make([]byte, newPacket.head.length)
		err = client.blockingRead(newPacket.body)
		if err != nil {
			println("receiveSession Errror=", err)
			client.program.onDisconnected()
			return
		}

		client.parse(newPacket)

	}

}

func (client *Client) onReceiveBasicMessage(packet *Packet) {
	message := &BasicMessage{}
	proto.Unmarshal(packet.unpack(), message)
	println("Received=", message.Talk)

}
func (client *Client) onReceiveJsonMessage(packet *Packet) {
	message := string(packet.unpack())
	println("Received=", message)
}

func (client *Client) parse(packet *Packet) {
	parse(client, packet)
	/*var protocol Protocol = client
	switch packet.head.id {
	case PacketBasicMessage:
		protocol.onReceiveBasicMessage(packet)
	}*/
}

func (client *Client) run() {
	println("Network Client")

	client.finish = false
	client.wg.Add(2)
	go client.receiveRoutine()
	go client.sendRoutine()
	client.running = true
}

func (client *Client) stop() {
	println("Stop Client")
	if client.running {
		client.finish = true

		if client.connection != nil {
			println("Close Socket")
			client.connection.Close()
		}
		client.wg.Wait()
		client.running = false
	} else {
		println("Already Stopped")
	}
}
