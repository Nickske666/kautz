module Kautz.Neighbours where

import Import

import Network.Socket.ByteString

import Kautz.JSONUtils
import Kautz.NodeInfo
import Kautz.SeedServerInfo
import Kautz.SockAddr
import Kautz.Types

updateNeighbours :: SockAddr -> KautzString -> [NodeInfo] -> IO ()
updateNeighbours addr kautzname nodeInfos = do
    let newReceivers = getNewReceivers kautzname nodeInfos
    mapM_ (uncurry (sendInfo addr)) newReceivers
    let newSenders = getNewSenders kautzname nodeInfos
    mapM_ (notifySender addr kautzname) newSenders
  where
    notifySender newAddr kautzName senderAddr =
        sendInfo senderAddr kautzName newAddr

getNewReceivers :: KautzString -> [NodeInfo] -> [(KautzString, SockAddr)]
getNewReceivers kautzname =
    fmap swap .
    filter (kautzNeighbours kautzname . snd) . fmap getAddressAndName

getNewSenders :: KautzString -> [NodeInfo] -> [SockAddr]
getNewSenders kautzname =
    fmap fst .
    filter (flip kautzNeighbours kautzname . snd) . fmap getAddressAndName

kautzNeighbours :: KautzString -> KautzString -> Bool
kautzNeighbours [] _ = False
kautzNeighbours (_:xs) receiver =
    case reverse receiver of
        (_:ys) -> xs == reverse ys
        _ -> False

sendInfo :: SockAddr -> KautzString -> SockAddr -> IO ()
sendInfo infoAddr infoName receiverAddr = do
    sock <- getSocket
    let message = encode $ NodeInfo infoAddr infoName
    connect sock receiverAddr
    sendAll sock message
