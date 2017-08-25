package main
import (
	"github.com/golang/protobuf/proto"
)

func main() {
	test := & Person {
	Name: proto.String("Mary"),
	}
	
	data,_ := proto.Marshal(test)
	println("Data Length=", len(data))


	newtest := & Person {}
	_ = proto.Unmarshal(data, newtest)
	println("Name=", *newtest.Name)
	

}
