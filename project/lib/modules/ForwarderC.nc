#define AM_FORWARDER 50

configuration ForwarderC{
	provides interface SimpleSend as Forwarder;
	provides interface Receive as ForwarderReceiver;
}

implementation{
	components ForwarderP;
	components new SimpleSendC(AM_FORWARDER);
	components new AMReceiverC(AM_FORWARDER);
	
	components LinkStateC;
	ForwarderP.routingTable -> LinkStateC;

	ForwarderP.InsideSender -> SimpleSendC;
	ForwarderP.InsideReceive -> AMReceiverC;

	ForwarderReceiver = ForwarderP.ForwarderReceiver;
	Forwarder = ForwarderP.Forwarder;

	//Send = ForwarderP.send;

	components TransportC;
	ForwarderP.Transport -> TransportC;
}