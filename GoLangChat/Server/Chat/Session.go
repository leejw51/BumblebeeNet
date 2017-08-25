// coded by Jongwhan Lee   (leejw51@gmail.com)
// Session
package main

import (
	//"fmt"
	"net"
	"time"
	//	"os"
	//"bytes"
	//"encoding/binary"
	"sync"

	"github.com/golang/protobuf/proto"
)

type Session struct {
	program    *Program
	Name       string
	connection net.Conn
	Finish     bool
	wg         sync.WaitGroup

	packetQueue chan *Packet
	Active      bool // this session is active
}

func (session *Session) stop() {
	println("Wait To Finish")
	session.Finish = true

	session.connection.Close()

	session.wg.Wait()
	session.Active = false
	println("Wait Done")
}

func (session *Session) initialize() {
	session.Finish = false
	session.Active = true
	session.wg.Add(2)
	session.packetQueue = make(chan *Packet, 10)
}

func (session *Session) blockingSend(buf []byte) error {
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
		n, err := session.connection.Write(buf[processed:end])
		if err != nil {
			println("Send Error=", err)
			session.Active = false
			return err
		}
		processed += n

	}

	return nil
}

func (session *Session) blockingRead(buf []byte) error {
	length := len(buf)
	processed := 0
	end := 0
	remain := 0
	for {
		remain = length - processed
		if 0 == remain {
			println("Read=", length)
			return nil
		}
		end = processed + remain
		n, err := session.connection.Read(buf[processed:end])
		if err != nil {
			println("Receive Error=", err)
			session.Active = false
			return err
		}
		processed += n

	}

	return nil
}
func (session *Session) receiveRoutine() {
	defer session.wg.Done()

	for {

		headBytes := make([]byte, 16)
		err := session.blockingRead(headBytes)
		if err != nil {
			return
		}

		newPacket := new(Packet)

		// read head
		newPacket.head.decode(headBytes)
		println("ID=", newPacket.head.id, "   Length=", newPacket.head.length)

		// read body
		newPacket.body = make([]byte, newPacket.head.length)
		err = session.blockingRead(newPacket.body)
		if err != nil {

			return
		}
		/*	buf := newPacket.unpack()
			message := &BasicMessage{}
			proto.Unmarshal(buf, message)

			println("message=", message.Talk)*/

		session.program.onReceivePacket(session, newPacket)

		if session.Finish {
			break
		}
	}
}

func (session *Session) sendRoutine() {

	defer session.wg.Done()

	for {
		select {
		case res := <-session.packetQueue:
			// write head
			data, _ := res.head.encode()
			err := session.blockingSend(data)
			if err != nil {
				return
			}

			// write body
			err = session.blockingSend(res.body)
			if err != nil {
				return
			}

		case <-time.After(time.Second * 1):
		}

		if session.Finish {
			break
		}
	}
}

func (session *Session) run() {

	go session.receiveRoutine()
	go session.sendRoutine()
}

func (session *Session) sendPacket(packet *Packet) {
	session.packetQueue <- packet
}

//--------- main routine..
func (session *Session) doProcess(packet *Packet) {
	session.parse(packet)

}

// called from main routine
func (session *Session) onReceiveBasicMessage(packet *Packet) {
	message := &BasicMessage{}
	proto.Unmarshal(packet.unpack(), message)
	println("Received=", message.Talk)

	session.program.broadcast(packet)
}

func (session *Session) onReceiveJsonMessage(packet *Packet) {
	message := packet.unpack()
	println("Received=", string(message))

	session.program.broadcast(packet)
}

func (session *Session) parse(packet *Packet) {
	parse(session, packet)
}
