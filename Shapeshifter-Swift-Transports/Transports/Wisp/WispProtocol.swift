//
//  WispProtocol.swift
//  Shapeshifter-Swift-Transports
//
//  Created by Brandon Wiley on 10/30/17.
//  Copyright © 2017 Operator Foundation. All rights reserved.
//
// The Wisp transport protocol is wire-compatible with the obfs4 transport and can use obfs4 servers as
// well as obfs4 configuration parameters.
//
// Wisp is a new implementaiton of the obfs4 protocol and is not guaranteed to be identical in
// implementation to other obfs4 implementations except when required for over-the-wire compatibility.

import Foundation
import NetworkExtension

struct Keypair {
    let publicKey: Data
    let privateKey: Data
    let representative: Data
}

struct WispProtocol {
    let nodeID:     Data
    let publicKey:  Data
    let sessionKey: Keypair
    
    let iatMode: Bool
    var network: NWTCPConnection
    
    init(connection: NWTCPConnection, cert: String, iatMode enableIAT: Bool) {
        network = connection
        iatMode = enableIAT

        (nodeID, publicKey) = unpackCert(cert: cert)
        
        sessionKey = newKeypair()
    }
    
    func handshake(completionHandler: (Error?) -> Void) {
/*
         const (
         maxHandshakeLength = 8192
         
         clientMinPadLength = (serverMinHandshakeLength + inlineSeedFrameLength) -
         clientMinHandshakeLength
         clientMaxPadLength       = maxHandshakeLength - clientMinHandshakeLength
         clientMinHandshakeLength = ntor.RepresentativeLength + markLength + macLength
         
         serverMinPadLength = 0
         serverMaxPadLength = maxHandshakeLength - (serverMinHandshakeLength +
         inlineSeedFrameLength)
         serverMinHandshakeLength = ntor.RepresentativeLength + ntor.AuthLength +
         markLength + macLength
         
         markLength = sha256.Size / 2
         macLength  = sha256.Size / 2
         
         inlineSeedFrameLength = framing.FrameOverhead + packetOverhead + seedPacketPayloadLength
         )
         
...

         func (conn *obfs4Conn) clientHandshake(nodeID *ntor.NodeID, peerIdentityKey *ntor.PublicKey, sessionKey *ntor.Keypair) error {
         if conn.isServer {
         return fmt.Errorf("clientHandshake called on server connection")
         }
         
         // Generate and send the client handshake.
         hs := newClientHandshake(nodeID, peerIdentityKey, sessionKey)
         blob, err := hs.generateHandshake()
         if err != nil {
         return err
         }
         if _, err = conn.Conn.Write(blob); err != nil {
         return err
         }
         
         // Consume the server handshake.
         var hsBuf [maxHandshakeLength]byte
         for {
         n, err := conn.Conn.Read(hsBuf[:])
         if err != nil {
         // The Read() could have returned data and an error, but there is
         // no point in continuing on an EOF or whatever.
         return err
         }
         conn.receiveBuffer.Write(hsBuf[:n])
         
         n, seed, err := hs.parseServerHandshake(conn.receiveBuffer.Bytes())
         if err == ErrMarkNotFoundYet {
         continue
         } else if err != nil {
         return err
         }
         _ = conn.receiveBuffer.Next(n)
         
         // Use the derived key material to intialize the link crypto.
         okm := ntor.Kdf(seed, framing.KeyLength*2)
         conn.encoder = framing.NewEncoder(okm[:framing.KeyLength])
         conn.decoder = framing.NewDecoder(okm[framing.KeyLength:])
         
         return nil
         }
         }
         
...
         
         func (hs *clientHandshake) generateHandshake() ([]byte, error) {
         var buf bytes.Buffer
         
         hs.mac.Reset()
         hs.mac.Write(hs.keypair.Representative().Bytes()[:])
         mark := hs.mac.Sum(nil)[:markLength]
         
         // The client handshake is X | P_C | M_C | MAC(X | P_C | M_C | E) where:
         //  * X is the client's ephemeral Curve25519 public key representative.
         //  * P_C is [clientMinPadLength,clientMaxPadLength] bytes of random padding.
         //  * M_C is HMAC-SHA256-128(serverIdentity | NodeID, X)
         //  * MAC is HMAC-SHA256-128(serverIdentity | NodeID, X .... E)
         //  * E is the string representation of the number of hours since the UNIX
         //    epoch.
         
         // Generate the padding
         pad, err := makePad(hs.padLen)
         if err != nil {
         return nil, err
         }
         
         // Write X, P_C, M_C.
         buf.Write(hs.keypair.Representative().Bytes()[:])
         buf.Write(pad)
         buf.Write(mark)
         
         // Calculate and write the MAC.
         hs.mac.Reset()
         hs.mac.Write(buf.Bytes())
         hs.epochHour = []byte(strconv.FormatInt(getEpochHour(), 10))
         hs.mac.Write(hs.epochHour)
         buf.Write(hs.mac.Sum(nil)[:macLength])
         
         return buf.Bytes(), nil
         }
 */
        
        completionHandler(nil)
    }
    
    func encode(_ data: Data) -> Data {
        return data
    }
    
    func decode(_ data: Data) -> Data {
        return data
    }
}

func unpackCert(cert: String) -> (Data, Data) {
/*
     const (
     // PublicKeyLength is the length of a Curve25519 public key.
     PublicKeyLength = 32
     
     // RepresentativeLength is the length of an Elligator representative.
     RepresentativeLength = 32
     
     // PrivateKeyLength is the length of a Curve25519 private key.
     PrivateKeyLength = 32
     
     // SharedSecretLength is the length of a Curve25519 shared secret.
     SharedSecretLength = 32
     
     // NodeIDLength is the length of a ntor node identifier.
     NodeIDLength = 20
     
     // KeySeedLength is the length of the derived KEY_SEED.
     KeySeedLength = sha256.Size
     
     // AuthLength is the lenght of the derived AUTH.
     AuthLength = sha256.Size
     )

...
     
     var nodeID *ntor.NodeID
     var publicKey *ntor.PublicKey
     
     // The "new" (version >= 0.0.3) bridge lines use a unified "cert" argument
     // for the Node ID and Public Key.
     cert, err := serverCertFromString(certString)
     if err != nil {
     return nil
     }
     nodeID, publicKey = cert.unpack()
     
...
     
     func serverCertFromString(encoded string) (*WispServerCert, error) {
     decoded, err := base64.StdEncoding.DecodeString(encoded + certSuffix)
     if err != nil {
     return nil, fmt.Errorf("failed to decode cert: %s", err)
     }
     
     if len(decoded) != certLength {
     return nil, fmt.Errorf("cert length %d is invalid", len(decoded))
     }
     
     return &WispServerCert{raw: decoded}, nil
     }

 ...

     func (cert *WispServerCert) unpack() (*ntor.NodeID, *ntor.PublicKey) {
     if len(cert.raw) != certLength {
     panic(fmt.Sprintf("cert length %d is invalid", len(cert.raw)))
     }
     
     nodeID, _ := ntor.NewNodeID(cert.raw[:ntor.NodeIDLength])
     pubKey, _ := ntor.NewPublicKey(cert.raw[ntor.NodeIDLength:])
     
     return nodeID, pubKey
     }
 */
    
    return (Data(), Data())
}

func newKeypair() -> Keypair {
/*
     // NewKeypair generates a new Curve25519 keypair, and optionally also generates
     // an Elligator representative of the public key.
     func NewKeypair(elligator bool) (*Keypair, error) {
     keypair := new(Keypair)
     keypair.private = new(PrivateKey)
     keypair.public = new(PublicKey)
     if elligator {
     keypair.representative = new(Representative)
     }
     
     for {
     // Generate a Curve25519 private key.  Like everyone who does this,
     // run the CSPRNG output through SHA256 for extra tinfoil hattery.
     priv := keypair.private.Bytes()[:]
     if err := csrand.Bytes(priv); err != nil {
     return nil, err
     }
     digest := sha256.Sum256(priv)
     digest[0] &= 248
     digest[31] &= 127
     digest[31] |= 64
     copy(priv, digest[:])
     
     if elligator {
     // Apply the Elligator transform.  This fails ~50% of the time.
     if !extra25519.ScalarBaseMult(keypair.public.Bytes(),
     keypair.representative.Bytes(),
     keypair.private.Bytes()) {
     continue
     }
     } else {
     // Generate the corresponding Curve25519 public key.
     curve25519.ScalarBaseMult(keypair.public.Bytes(),
     keypair.private.Bytes())
     }
     
     return keypair, nil
     }
     }
*/
    
    return Keypair(publicKey: Data(), privateKey: Data(), representative: Data())
}

func sha256(data : Data) -> Data {
    var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
    data.withUnsafeBytes {
        _ = CC_SHA256($0, CC_LONG(data.count), &hash)
    }
    return Data(bytes: hash)
}

enum WispPacketType: UInt8 {
    case payload = 0
    case seed    = 1
}

struct WispPacket {
   type:    WispPacketType // will always be 0 for packets made by the client
   length:  UInt16         // Length of the payload (serialize as Big Endian).
   payload: Data
   padding: Data
}

func makePacket(data: Data, padLen: Int) -> Data {
/*
     func (conn *obfs4Conn) makePacket(w io.Writer, pktType uint8, data []byte, padLen uint16) error {
     var pkt [framing.MaximumFramePayloadLength]byte
     
     if len(data)+int(padLen) > maxPacketPayloadLength {
     panic(fmt.Sprintf("BUG: makePacket() len(data) + padLen > maxPacketPayloadLength: %d + %d > %d",
     len(data), padLen, maxPacketPayloadLength))
     }
     
     pkt[0] = pktType
     binary.BigEndian.PutUint16(pkt[1:], uint16(len(data)))
     if len(data) > 0 {
     copy(pkt[3:], data[:])
     }
     copy(pkt[3+len(data):], zeroPadBytes[:padLen])
     
     pktLen := packetOverhead + len(data) + int(padLen)
     
     // Encode the packet in an AEAD frame.
     var frame [framing.MaximumSegmentLength]byte
     frameLen, err := conn.encoder.Encode(frame[:], pkt[:pktLen])
 */
    
    return Data()
}
