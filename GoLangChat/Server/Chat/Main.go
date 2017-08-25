// Main
package main

import (
	//	"bytes"
	//	"encoding/binary"
	"encoding/json"
	"fmt"
)

type TestData struct {
	name  int64
	price int64
}

func testPacket() {
	head := PacketHead{1, 2000}
	data, err := head.encode()
	println("Length=", len(data))
	checkErrror(err)

	head2 := PacketHead{-1, -1}
	err2 := head2.decode(data)
	checkErrror(err2)
	println(head2.id, "   ", head2.length)
}

func main2() {

	a := []string{"apple", "peach", "pear"}
	b, _ := json.Marshal(a)
	fmt.Println(string(b))
}

func main() {

	println("1. Server")
	println("2. Client")
	println("q. Exit")
	var a string
	_, err := fmt.Scanf("%s", &a)
	println(a, err)
	switch a {
	case "1":
		serverProgram()
	case "2":
		clientProgram()
	default:
	}
}
