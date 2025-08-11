import Foundation
import MultipeerConnectivity
#if canImport(UIKit)
import UIKit
#endif
import ProxSyncCore

public final class NearbySession<P: ProxPayload>: NSObject,
    MCNearbyServiceAdvertiserDelegate,
    MCNearbyServiceBrowserDelegate,
    MCSessionDelegate
{
    public typealias ReceiveHandler = (IngestEnvelope<P>, String) -> Void
    public var onReceive: ReceiveHandler?

    private let serviceType: String
    private let peerID: MCPeerID
    private lazy var session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    /// `displayName` defaults to a UUID to avoid MainActor/UIDevice issues.
    public init(serviceType: String = "proxsync-app", displayName: String? = nil) {
        self.serviceType = serviceType
        #if canImport(UIKit)
        let name = displayName ?? UUID().uuidString
        #else
        let name = displayName ?? UUID().uuidString
        #endif
        self.peerID = MCPeerID(displayName: name)
        super.init()
        session.delegate = self
    }

    // MARK: - Public API
    public func startAdvertising() {
        let a = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser = a
        a.delegate = self
        a.startAdvertisingPeer()
    }

    public func stopAdvertising() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
    }

    public func startBrowsing() {
        let b = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser = b
        b.delegate = self
        b.startBrowsingForPeers()
    }

    public func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
    }

    public func invite(_ peer: MCPeerID) {
        browser?.invitePeer(peer, to: session, withContext: nil, timeout: 10)
    }

    public func send(_ payload: P) throws {
        let env = IngestEnvelope(payload: payload)
        let data = try JSONEncoder().encode(env)
        try session.send(data, toPeers: session.connectedPeers, with: .reliable)
    }

    // MARK: - MCNearbyServiceAdvertiserDelegate
    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                           didReceiveInvitationFromPeer peerID: MCPeerID,
                           withContext context: Data?,
                           invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }

    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                           didNotStartAdvertisingPeer error: Error) {
        #if DEBUG
        print("Nearby advertise error:", error.localizedDescription)
        #endif
    }

    // MARK: - MCNearbyServiceBrowserDelegate
    public func browser(_ browser: MCNearbyServiceBrowser,
                        foundPeer peerID: MCPeerID,
                        withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    public func browser(_ browser: MCNearbyServiceBrowser,
                        lostPeer peerID: MCPeerID) { }

    public func browser(_ browser: MCNearbyServiceBrowser,
                        didNotStartBrowsingForPeers error: Error) {
        #if DEBUG
        print("Nearby browse error:", error.localizedDescription)
        #endif
    }

    // MARK: - MCSessionDelegate
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) { }

    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let env = try? JSONDecoder().decode(IngestEnvelope<P>.self, from: data) {
            onReceive?(env, peerID.displayName)
        }
    }

    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) { }

    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) { }

    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) { }

    public func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID,
                        certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
}
