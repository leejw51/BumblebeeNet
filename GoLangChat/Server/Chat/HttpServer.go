// HttpServer
package main

import (
	"fmt"
	//"html"
	"encoding/json"
	"net/http"
)

type Fruit struct {
	Name  string
	Price int
}

type WebServer struct {
	port    int
	fruits  []Fruit
	program *Program
}

func (server *WebServer) initialize() {
	server.port = 8000

	server.fruits = make([]Fruit, 0)
	server.fruits = append(server.fruits, Fruit{"apple", 200})
	server.fruits = append(server.fruits, Fruit{"banana", 500})
	server.fruits = append(server.fruits, Fruit{"strawberry", 150})
}

func (server *WebServer) fruitHandler(res http.ResponseWriter, req *http.Request) {
	//m := "Apple"
	//res.Write([]byte(m))
	//	fmt.Fprintf(res, "Apple,%q\n", html.EscapeString(req.URL.Path))
	//res.Write([]byte(req.FormValue("Name")))
	//res.Write([]byte(req.FormValue("Price")))

	j, _ := json.Marshal(server.fruits)
	println(j)
	println(string(j))
	res.Write(j)

}

func (server *WebServer) sessionsHandler(res http.ResponseWriter, req *http.Request) {

	b, _ := json.Marshal(server.program.sessions)
	res.Write(b)
}

func (server *WebServer) rootHandler(res http.ResponseWriter, req *http.Request) {
	res.Header().Set("Content-Type", "text/html")
	fmt.Fprintf(res, "Virtual Chat <br>")
	fmt.Fprintf(res, "1. <a  href=sessions> sessions </a>")
}

func (server *WebServer) webMain() {

	port := fmt.Sprintf(":%d", server.port)
	println("Port=", port)

	// file server
	http.Handle("/", http.FileServer(http.Dir("./static")))
	http.HandleFunc("/menu", server.rootHandler)
	http.HandleFunc("/fruit", server.fruitHandler)
	http.HandleFunc("/sessions", server.sessionsHandler)
	http.ListenAndServe(port, nil)

}

func startHttp(program *Program) {
	server := new(WebServer)
	server.program = program
	server.initialize()
	go server.webMain()
}
