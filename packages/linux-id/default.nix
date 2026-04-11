{
  lib,
  fetchFromGitHub,
  buildGoModule,
}:

buildGoModule {
  pname = "linux-id";
  version = "0-unstable-2026-03-20";

  src = fetchFromGitHub {
    owner = "matejsmycka";
    repo = "linux-id";
    rev = "1615c1a029a6f397a55b4b673a2381301a087068";
    hash = "sha256-T57/VNWaEwvYNnSOZmiO3Oj+7Vlxuxwo5OrB0Wuol3M=";
  };

  vendorHash = "sha256-HwLcsjzaFqc0aQrTCoSUdes6ZlnsNZJCdtjwucFyOQ4=";

  # Remove U2F_V2 from GetInfo so browsers use CTAP2 instead of falling back to U2F.
  # Set NMSG capability flag to advertise no U2F support.
  # Add CTAPHID_KEEPALIVE support for libfido2/SSH compatibility.
  # NOTE: U2F CmdMsg is NOT rejected because libfido2 uses it for touch probing.
  postPatch = let
    # CTAPHID_KEEPALIVE: add constant and SendKeepalive method
    oldCborConst = ''CmdCbor  CmdType = 0x10 // Send encapsulated CTAP CBOR'';
    newCborConst = ''CmdCbor      CmdType = 0x10 // Send encapsulated CTAP CBOR
	CmdCancel    CmdType = 0x11 // Cancel ongoing operation
	CmdKeepalive CmdType = 0x3b // Keepalive during user verification'';

    oldWriteCtap2 = ''// WriteCtap2Response sends a CTAP2 response: [1-byte status] + [CBOR payload].
// No trailing U2F status word is appended.
func (t *SoftToken) WriteCtap2Response(ctx context.Context, evt AuthEvent, status byte, data []byte) error {
	payload := append([]byte{status}, data...)
	return writeRespose(t.device, evt.chanID, CmdCbor, payload, 0)
}'';
    newWriteCtap2 = ''// WriteCtap2Response sends a CTAP2 response: [1-byte status] + [CBOR payload].
// No trailing U2F status word is appended.
func (t *SoftToken) WriteCtap2Response(ctx context.Context, evt AuthEvent, status byte, data []byte) error {
	payload := append([]byte{status}, data...)
	log.Printf("WriteCtap2Response: status=0x%02x payloadLen=%d chanID=0x%08x", status, len(payload), evt.chanID)
	return writeRespose(t.device, evt.chanID, CmdCbor, payload, 0)
}

// SendKeepalive sends a CTAPHID_KEEPALIVE message with the given status byte.
// Status: 0x01 = processing, 0x02 = user presence needed.
func (t *SoftToken) SendKeepalive(evt AuthEvent, status byte) error {
	return writeRespose(t.device, evt.chanID, CmdKeepalive, []byte{status}, 0)
}'';

    # MakeCredential: add keepalive during verification wait
    oldMakeCredWait = ''	childCtx, cancel := context.WithTimeout(ctx, 35*time.Second)
	defer cancel()
	select {
	case result := <-resultCh:
		if !result.OK {
			if result.Error != nil {
				log.Printf("MakeCredential verifier result err: %s", result.Error)
			}
			token.WriteCtap2Response(ctx, evt, ctap2.StatusOperationDenied, nil)
			return
		}
	case <-childCtx.Done():
		token.WriteCtap2Response(ctx, evt, ctap2.StatusUserActionTimeout, nil)
		return
	}'';
    newMakeCredWait = ''	childCtx, cancel := context.WithTimeout(ctx, 35*time.Second)
	defer cancel()
	keepaliveDone := make(chan struct{})
	keepaliveStopped := make(chan struct{})
	go func() {
		defer close(keepaliveStopped)
		ticker := time.NewTicker(100 * time.Millisecond)
		defer ticker.Stop()
		for {
			select {
			case <-ticker.C:
				token.SendKeepalive(evt, 0x02)
			case <-keepaliveDone:
				return
			}
		}
	}()
	select {
	case result := <-resultCh:
		close(keepaliveDone)
		<-keepaliveStopped
		if !result.OK {
			if result.Error != nil {
				log.Printf("MakeCredential verifier result err: %s", result.Error)
			}
			token.WriteCtap2Response(ctx, evt, ctap2.StatusOperationDenied, nil)
			return
		}
	case <-childCtx.Done():
		close(keepaliveDone)
		<-keepaliveStopped
		token.WriteCtap2Response(ctx, evt, ctap2.StatusUserActionTimeout, nil)
		return
	}'';

    # GetAssertion: add keepalive during verification wait
    oldGetAssertWait = ''	childCtx, cancel := context.WithTimeout(ctx, 35*time.Second)
	defer cancel()
	select {
	case result := <-resultCh:
		if !result.OK {
			if result.Error != nil {
				log.Printf("GetAssertion verifier result err: %s", result.Error)
			}
			token.WriteCtap2Response(ctx, evt, ctap2.StatusOperationDenied, nil)
			return
		}
	case <-childCtx.Done():
		token.WriteCtap2Response(ctx, evt, ctap2.StatusUserActionTimeout, nil)
		return
	}'';
    newGetAssertWait = ''	childCtx, cancel := context.WithTimeout(ctx, 35*time.Second)
	defer cancel()
	keepaliveDone := make(chan struct{})
	keepaliveStopped := make(chan struct{})
	go func() {
		defer close(keepaliveStopped)
		ticker := time.NewTicker(100 * time.Millisecond)
		defer ticker.Stop()
		for {
			select {
			case <-ticker.C:
				token.SendKeepalive(evt, 0x02)
			case <-keepaliveDone:
				return
			}
		}
	}()
	select {
	case result := <-resultCh:
		close(keepaliveDone)
		<-keepaliveStopped
		if !result.OK {
			if result.Error != nil {
				log.Printf("GetAssertion verifier result err: %s", result.Error)
			}
			token.WriteCtap2Response(ctx, evt, ctap2.StatusOperationDenied, nil)
			return
		}
	case <-childCtx.Done():
		close(keepaliveDone)
		<-keepaliveStopped
		token.WriteCtap2Response(ctx, evt, ctap2.StatusUserActionTimeout, nil)
		return
	}'';
  in ''
    # Remove U2F_V2 from GetInfo versions so browsers only use CTAP2
    substituteInPlace main.go \
      --replace-fail '1: []string{"FIDO_2_0", "U2F_V2"},' \
                     '1: []string{"FIDO_2_0"},'

    # Add CmdKeepalive and CmdCancel constants
    substituteInPlace fidohid/fidohid.go \
      --replace-fail ${lib.escapeShellArg oldCborConst} \
                     ${lib.escapeShellArg newCborConst}

    # Set NMSG capability flag
    substituteInPlace fidohid/fidohid.go \
      --replace-fail 'RawCapabilities: cborCapability,' \
                     'RawCapabilities: cborCapability | nmsgCapability,'

    # Add SendKeepalive method
    substituteInPlace fidohid/fidohid.go \
      --replace-fail ${lib.escapeShellArg oldWriteCtap2} \
                     ${lib.escapeShellArg newWriteCtap2}

    # Add packet-level debug logging to writeRespose
    substituteInPlace fidohid/fidohid.go \
      --replace-fail 'func writeRespose(d *uhid.Device, chanID uint32, cmd CmdType, data []byte, status uint16) error {' \
                     'func writeRespose(d *uhid.Device, chanID uint32, cmd CmdType, data []byte, status uint16) error {
	log.Printf("writeRespose: cmd=0x%02x chanID=0x%08x dataLen=%d status=0x%04x", cmd, chanID, len(data), status)'

    # Add keepalive to MakeCredential verification wait
    substituteInPlace main.go \
      --replace-fail ${lib.escapeShellArg oldMakeCredWait} \
                     ${lib.escapeShellArg newMakeCredWait}

    # Add keepalive to GetAssertion verification wait
    substituteInPlace main.go \
      --replace-fail ${lib.escapeShellArg oldGetAssertWait} \
                     ${lib.escapeShellArg newGetAssertWait}
  '';

  ldflags = [
    "-s"
    "-w"
  ];

  meta = {
    description = "FIDO2/U2F token with CTAP2 support, protected by a TPM";
    homepage = "https://github.com/matejsmycka/linux-id";
    license = lib.licenses.mit;
    mainProgram = "linux-id";
  };
}
