#define AM_CHAT 50

configuration ChatC{
    provides interface Chat;
}

implementation {
    components ChatP;
	Chat = ChatP.Chat;

    // components new SimpleSendC(AM_CHAT) as sender;
    // ChatP.send -> sender;

    // components ForwarderC;
    // ChatP.send -> ForwarderC.SimpleSend;

     components TransportC;
    ChatP.Transport -> TransportC;
}