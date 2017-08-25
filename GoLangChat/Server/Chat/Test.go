// coded by Jongwhan Lee   (leejw51@gmail.com)

package main

//"fmt"
//"os"

func testMap() {
	m := make(map[string]int)
	m["apple"] = 200
	m["pear"] = 1500

	for k, v := range m {
		println(k, v)
	}
}

func testQueue() {
	type Fruit struct {
		price int
		name  string
	}

	var fruits []Fruit

	fruits = append(fruits, Fruit{200, "apple"})
	fruits = append(fruits, Fruit{500, "pear"})

	for k, v := range fruits {
		println("Key=", k, "  Value=", v.name)
	}
}

func testArray2() {
	var nodes []string
	nodes = append(nodes, "apple1")
	nodes = append(nodes, "apple2")
	nodes = append(nodes, "apple3")
	nodes = append(nodes, "apple4")
	nodes = append(nodes, "apple5")

	nodes2 := nodes
	nodes2[0] = "apple1*"
	nodes2 = append(nodes2, "apple6")
	nodes2 = append(nodes2, "apple7")

	for k, v := range nodes {
		println(k, v)
	}

	for k, v := range nodes2 {
		println(k, v)
	}

	println("Count=", len(nodes))
}
