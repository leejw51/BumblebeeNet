// coded by Jongwhan Lee   (leejw51@gmail.com)
// Session
package main

import (
	//"fmt"
	//	"net"
	//	"time"
	//	"os"
	"bytes"
	"encoding/binary"
	//	"sync"
)

type PacketHead struct {
	id     int64
	length int64
}

func (head *PacketHead) encode() (output []byte, output_err error) {
	buf := new(bytes.Buffer)
	err := binary.Write(buf, binary.LittleEndian, head.id)
	err = binary.Write(buf, binary.LittleEndian, head.length)
	return buf.Bytes(), err
}

func (head *PacketHead) decode(input []byte) error {
	buf := bytes.NewBuffer(input)
	err := binary.Read(buf, binary.LittleEndian, &head.id)
	err = binary.Read(buf, binary.LittleEndian, &head.length)
	return err
}
