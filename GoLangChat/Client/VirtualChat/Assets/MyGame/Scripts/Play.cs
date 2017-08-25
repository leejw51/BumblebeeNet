using UnityEngine;
using System.Collections;
using VirtualChat;
public class Play : MonoBehaviour {

	public AppClient client = null;

	public VirtualChat.Queue<Packet> packets = new VirtualChat.Queue<Packet> (10);
	public ChatInput input;
	void Awake() {
		Debug.Log ("Play");
	//	Application.runInBackground = true;
	}

	// Use this for initialization
	void Start () {
		client = new AppClient ();
		client.setServer ("localhost", 3000);
	
		client.run ();

		client.onReceivedCallback += delegate  (Packet packet) {
			
			this.packets.push(packet);

		};
	}

	void send(string json)
	{
		Packet m = new Packet ();
		m.packJson (json);

		client.send (m);
	}
	
	// Update is called once per frame
	void Update () {

		Packet ret = packets.pop (0);
		if (ret != null) {
			string json = System.Text.Encoding.UTF8.GetString ( ret.body);
			Debug.Log("Main Received="+ json);
			input.textList.Add (json);
		}
		
	}



	void OnDestroy() {
		Debug.Log ("Play Destroy");
		client.stop ();
	}

	public void OnSubmit() {

		string text = NGUIText.StripSymbols(input.mInput.value);
		Debug.Log (text);


		//input.textList.Add (text);
		string json = string.Format("[\"{0}\"]", text);
		Debug.Log (json);
		send (json);
		input.mInput.value = "";
	}
}
