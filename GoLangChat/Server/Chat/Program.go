// coded by Jongwhan Lee   (leejw51@gmail.com)
// Program
package main

import (
	"fmt"
	"net"
	"os"

	"time"

	"github.com/golang/protobuf/proto"
	"github.com/nu7hatch/gouuid"
)

type ProgramMessage struct {
	session *Session
	packet  *Packet
}

func (message *ProgramMessage) runProgram(program *Program) {
	message.session.doProcess(message.packet)
}

type ProgramMessageInterface interface {
	runProgram(program *Program)
}

type Program struct {
	name          string
	sessions      map[string]*Session
	messsageQueue chan ProgramMessageInterface
	finish        bool
}

func (program *Program) broadcast(packet *Packet) {
	//println("Program SendPacket")
	//session.sendPacket(packet)
	for k, v := range program.sessions {
		print("SendTo=", k, "   ID=", packet.head.id, "  Lengh=", packet.head.length)
		v.sendPacket(packet)
	}
}
func (p *Program) testPacket() {
	print("Server\n")
	person := &Person{
		Name: "space earth sun moon stars",
	}
	data, err := proto.Marshal(person)
	println("Error=", err)
	println("Data=", data)
	println("DataLength=", len(data))
}

func (program *Program) initialize() {
	program.sessions = make(map[string]*Session)
	program.messsageQueue = make(chan ProgramMessageInterface, 10)
	program.finish = false
}

func (program *Program) addSession(session *Session) {
	program.sessions[session.Name] = session
	println("Current Sessions=", len(program.sessions))
}
func (program *Program) removeSession(session *Session) {
	delete(program.sessions, session.Name)

}

func (program *Program) listSession() {
	println("List Sessions")
	for k, v := range program.sessions {
		println("Key=", k, "   Value=", v)
	}
}

func (program *Program) removeAllSessions() {
	for k, v := range program.sessions {
		println("Remove Session=", k)
		v.stop()
	}

	program.sessions = make(map[string]*Session)
}

func (program *Program) sendTalks() {
	println("Send Talks")

	message := &BasicMessage{Talk: "Talk!"}
	buf, _ := proto.Marshal(message)
	var packet = new(Packet)
	packet.pack(buf)

	for k, v := range program.sessions {
		println("SendTalk Sesion=", k)
		v.sendPacket(packet)
	}
}

func (program *Program) onReceivePacket(session *Session, receivedPacket *Packet) {
	//sendPacketSession(session, receivedPacket)
	newone := new(ProgramMessage)
	newone.session = session
	newone.packet = receivedPacket
	program.messsageQueue <- newone
}

// main thread
func (program *Program) processRoutine() {
	for {
		select {
		case res := <-program.messsageQueue:
			//	res.session.doProcess(res.packet)
			res.runProgram(program)

		case <-time.After(time.Second * 1):
		}

		program.processSessions()

		if program.finish {
			break
		}

	}
}

func (program *Program) processSessions() {
	nodes := []*Session{}

	for _, v := range program.sessions {
		if !v.Active {
			nodes = append(nodes, v)
		}
	}

	if len(nodes) > 0 {
		program.stopSessions(nodes)
	}
}

func (program *Program) stopSessions(sessions []*Session) {
	for _, v := range sessions {
		println("Delete=", v.Name)
		one := v
		delete(program.sessions, v.Name)
		go one.stop()
	}
}

func (program *Program) listenRoutine() {
	service := ":3000"
	tcpAddr, err := net.ResolveTCPAddr("tcp4", service)
	checkErrror(err)

	listener, err := net.ListenTCP("tcp", tcpAddr)
	checkErrror(err)
	for {
		conn, err := listener.Accept()
		if err != nil {
			continue
		}

		newsession := new(Session)
		newsession.initialize()
		newsession.connection = conn
		newsession.program = program

		newid, err := uuid.NewV4()
		newsession.Name = newid.String()
		println("NewSession=", newid.String())

		program.addSession(newsession)
		newsession.run()
	}
}

func (program *Program) run() {
	println("Network Server")
	go program.listenRoutine()
	go program.processRoutine()

}

func serverProgram() {
	program := new(Program)
	program.initialize()

	go program.run()

	go startHttp(program)

	var quit = false
	for {

		println("1. list session")
		println("2. remove all sessions")
		println("3. send talks")
		println("q. quit")
		var a string
		_, err := fmt.Scanf("%s", &a)
		println(a, err)
		switch a {
		case "1":
			println("List Sessions")
			program.listSession()
			break
		case "2":
			program.removeAllSessions()
			break
		case "3":
			program.sendTalks()
			break
		case "q":
			quit = true
			break
		default:
			println("quit")
			break
		}

		if quit {
			program.finish = true
			break
		}
	}
}

func checkErrror(err error) {
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error:%s", err.Error())
		os.Exit(1)
	}
}
