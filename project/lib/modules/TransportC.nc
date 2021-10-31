#define AM_TRANSPORT 25

configuration TransportC{
	provides interface Transport;
}

implementation{
	components TransportP;
	Transport = TransportP.Transport;

	components new SimpleSendC(AM_TRANSPORT);
	TransportP.Sender -> SimpleSendC;

	components new TimerMilliC() as Timer;
	TransportP.Timer -> Timer;

	components new QueueC(pack, 100) as packetQueue;
	TransportP.packetQueue -> packetQueue;

	components new ListC(socket_t, 100) as SocketList;
	TransportP.SocketList -> SocketList;

	//components LinkStateC;
	//TransportP.LinkState -> LinkStateC.LinkState;

	// components ForwarderC;
	// TransportP.Forwarder -> ForwarderC;
}