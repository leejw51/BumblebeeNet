// coded by Jongwhan Lee   (leejw51@gmail.com)
// Session
package main

//	"github.com/golang/protobuf/proto"

//"fmt"
//	"net"1
//	"time"
//	"os"
//	"bytes"
//	"encoding/binary"
//	"sync"

type PacketType int

const (
	PacketBasicMessage = 0 // google protobuf
	PacketJsonMessage  = 1 // just json
)

type Packet struct {
	head PacketHead
	body []byte
}

func (packet *Packet) pack(src []byte) {
	buf := src
	packet.body = buf
	packet.head.length = int64(len(packet.body))
}

func (packet *Packet) unpack() (dst []byte) {
	buf := packet.body
	return buf[0:]
}

type Protocol interface {
	onReceiveBasicMessage(packet *Packet) // google protobuf
	onReceiveJsonMessage(packet *Packet)  // json
}

func parse(protocol Protocol, packet *Packet) {
	switch packet.head.id {
	case PacketBasicMessage:
		protocol.onReceiveBasicMessage(packet)

	case PacketJsonMessage:
		protocol.onReceiveJsonMessage(packet)
	}
}
